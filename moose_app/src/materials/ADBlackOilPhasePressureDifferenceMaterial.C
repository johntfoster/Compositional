#include "ADBlackOilPhasePressureDifferenceMaterial.h"

#include "metaphysicl/raw_type.h"

#include <algorithm>

registerMooseObject("MulticomponentReactiveFlowApp",
                    ADBlackOilPhasePressureDifferenceMaterial);

InputParameters
ADBlackOilPhasePressureDifferenceMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Reconstructs water/oil and gas/oil phase-pressure differences by adding independent "
      "stored surface-energy, electrical-enthalpy, and generalized saturation-force terms.");
  params.addCoupledVar("water_pressure_difference", "Water pressure minus oil pressure field.");
  params.addParam<MaterialPropertyName>(
      "water_pressure_difference_name",
      "",
      "Optional reconstructed water-minus-oil pressure-difference property.");
  params.addCoupledVar("gas_pressure_difference", "Gas pressure minus oil pressure field.");
  params.addParam<MaterialPropertyName>(
      "gas_pressure_difference_name",
      "",
      "Optional reconstructed gas-minus-oil pressure-difference property.");
  params.addCoupledVar("water_saturation", "Water-saturation backbone or total field.");
  params.addParam<MaterialPropertyName>(
      "water_saturation_name", "", "Optional reconstructed total water-saturation property.");
  params.addCoupledVar("gas_saturation", "Gas-saturation backbone or total field.");
  params.addParam<MaterialPropertyName>(
      "gas_saturation_name", "", "Optional reconstructed total gas-saturation property.");
  params.addRequiredParam<std::vector<Real>>(
      "water_saturation_points", "Strictly increasing S_w coordinates for p_cow.");
  params.addRequiredParam<std::vector<Real>>(
      "water_oil_capillary_pressure_values", "Stored oil-minus-water pressure values p_cow.");
  params.addRequiredParam<std::vector<Real>>(
      "gas_saturation_points", "Strictly increasing S_g coordinates for p_cgo.");
  params.addRequiredParam<std::vector<Real>>(
      "gas_oil_capillary_pressure_values", "Stored gas-minus-oil pressure values p_cgo.");
  params.addParam<MaterialPropertyName>(
      "water_electrical_enthalpy_difference_name",
      "",
      "Optional omega_w^+-omega_o^+ property; an empty name selects zero.");
  params.addParam<MaterialPropertyName>(
      "gas_electrical_enthalpy_difference_name",
      "",
      "Optional omega_g^+-omega_o^+ property; an empty name selects zero.");
  params.addParam<MaterialPropertyName>(
      "water_saturation_force_difference_name",
      "",
      "Optional L_w^sat-L_o^sat property; an empty name selects zero.");
  params.addParam<MaterialPropertyName>(
      "gas_saturation_force_difference_name",
      "",
      "Optional L_g^sat-L_o^sat property; an empty name selects zero.");
  params.addParam<MooseEnum>("out_of_range_policy",
                             MooseEnum("error clamp linear", "error"),
                             "Policy for saturations outside each table interval.");
  params.addParam<std::string>(
      "property_prefix", "black_oil_pressure", "Prefix for declared material properties.");
  return params;
}

ADBlackOilPhasePressureDifferenceMaterial::ADBlackOilPhasePressureDifferenceMaterial(
    const InputParameters & parameters)
  : Material(parameters),
    _water_pressure_difference(isCoupled("water_pressure_difference")
                                   ? &adCoupledValue("water_pressure_difference")
                                   : nullptr),
    _water_pressure_difference_property(
        getParam<MaterialPropertyName>("water_pressure_difference_name").empty()
            ? nullptr
            : &getADMaterialProperty<Real>("water_pressure_difference_name")),
    _gas_pressure_difference(isCoupled("gas_pressure_difference")
                                 ? &adCoupledValue("gas_pressure_difference")
                                 : nullptr),
    _gas_pressure_difference_property(
        getParam<MaterialPropertyName>("gas_pressure_difference_name").empty()
            ? nullptr
            : &getADMaterialProperty<Real>("gas_pressure_difference_name")),
    _water_saturation(isCoupled("water_saturation") ? &adCoupledValue("water_saturation")
                                                     : nullptr),
    _water_saturation_property(getParam<MaterialPropertyName>("water_saturation_name").empty()
                                   ? nullptr
                                   : &getADMaterialProperty<Real>("water_saturation_name")),
    _gas_saturation(isCoupled("gas_saturation") ? &adCoupledValue("gas_saturation") : nullptr),
    _gas_saturation_property(getParam<MaterialPropertyName>("gas_saturation_name").empty()
                                 ? nullptr
                                 : &getADMaterialProperty<Real>("gas_saturation_name")),
    _water_electrical_enthalpy_difference_input(
        getParam<MaterialPropertyName>("water_electrical_enthalpy_difference_name").empty()
            ? nullptr
            : &getADMaterialProperty<Real>("water_electrical_enthalpy_difference_name")),
    _gas_electrical_enthalpy_difference_input(
        getParam<MaterialPropertyName>("gas_electrical_enthalpy_difference_name").empty()
            ? nullptr
            : &getADMaterialProperty<Real>("gas_electrical_enthalpy_difference_name")),
    _water_saturation_force_difference_input(
        getParam<MaterialPropertyName>("water_saturation_force_difference_name").empty()
            ? nullptr
            : &getADMaterialProperty<Real>("water_saturation_force_difference_name")),
    _gas_saturation_force_difference_input(
        getParam<MaterialPropertyName>("gas_saturation_force_difference_name").empty()
            ? nullptr
            : &getADMaterialProperty<Real>("gas_saturation_force_difference_name")),
    _water_saturation_points(getParam<std::vector<Real>>("water_saturation_points")),
    _water_oil_capillary_pressure_values(
        getParam<std::vector<Real>>("water_oil_capillary_pressure_values")),
    _gas_saturation_points(getParam<std::vector<Real>>("gas_saturation_points")),
    _gas_oil_capillary_pressure_values(
        getParam<std::vector<Real>>("gas_oil_capillary_pressure_values")),
    _out_of_range_policy(getParam<MooseEnum>("out_of_range_policy")),
    _property_prefix(getParam<std::string>("property_prefix")),
    _water_stored_surface_energy_difference(
        declareADProperty<Real>(prefixedName("water_stored_surface_energy_difference"))),
    _gas_stored_surface_energy_difference(
        declareADProperty<Real>(prefixedName("gas_stored_surface_energy_difference"))),
    _water_electrical_enthalpy_difference(
        declareADProperty<Real>(prefixedName("water_electrical_enthalpy_difference"))),
    _gas_electrical_enthalpy_difference(
        declareADProperty<Real>(prefixedName("gas_electrical_enthalpy_difference"))),
    _water_saturation_force_difference(
        declareADProperty<Real>(prefixedName("water_saturation_force_difference"))),
    _gas_saturation_force_difference(
        declareADProperty<Real>(prefixedName("gas_saturation_force_difference"))),
    _water_reconstructed_pressure_difference(
        declareADProperty<Real>(prefixedName("water_reconstructed_pressure_difference"))),
    _gas_reconstructed_pressure_difference(
        declareADProperty<Real>(prefixedName("gas_reconstructed_pressure_difference"))),
    _water_pressure_difference_closure_residual(
        declareADProperty<Real>(prefixedName("water_pressure_difference_closure_residual"))),
    _gas_pressure_difference_closure_residual(
        declareADProperty<Real>(prefixedName("gas_pressure_difference_closure_residual")))
{
  const auto require_exactly_one = [this](const bool coupled,
                                          const bool property,
                                          const std::string & parameter) {
    if (coupled == property)
      paramError(parameter, "Supply exactly one coupled field or reconstructed property.");
  };
  require_exactly_one(_water_pressure_difference != nullptr,
                      _water_pressure_difference_property != nullptr,
                      "water_pressure_difference_name");
  require_exactly_one(_gas_pressure_difference != nullptr,
                      _gas_pressure_difference_property != nullptr,
                      "gas_pressure_difference_name");
  require_exactly_one(_water_saturation != nullptr,
                      _water_saturation_property != nullptr,
                      "water_saturation_name");
  require_exactly_one(_gas_saturation != nullptr,
                      _gas_saturation_property != nullptr,
                      "gas_saturation_name");
  if (_property_prefix.empty())
    paramError("property_prefix", "The material-property prefix must be nonempty.");

  const auto validate_table = [this](const std::vector<Real> & points,
                                     const std::vector<Real> & values,
                                     const std::string & point_parameter,
                                     const std::string & value_parameter) {
    if (points.size() < 2)
      paramError(point_parameter, "Supply at least two saturation points.");
    if (values.size() != points.size())
      paramError(value_parameter, "Supply one value for each saturation point.");
    for (unsigned int i = 0; i + 1 < points.size(); ++i)
      if (points[i + 1] <= points[i])
        paramError(point_parameter, "Saturation points must be strictly increasing.");
  };
  validate_table(_water_saturation_points,
                 _water_oil_capillary_pressure_values,
                 "water_saturation_points",
                 "water_oil_capillary_pressure_values");
  validate_table(_gas_saturation_points,
                 _gas_oil_capillary_pressure_values,
                 "gas_saturation_points",
                 "gas_oil_capillary_pressure_values");
}

MaterialPropertyName
ADBlackOilPhasePressureDifferenceMaterial::prefixedName(const std::string & suffix) const
{
  return MaterialPropertyName(_property_prefix + "_" + suffix);
}

ADReal
ADBlackOilPhasePressureDifferenceMaterial::waterSaturation() const
{
  return _water_saturation ? (*_water_saturation)[_qp] : (*_water_saturation_property)[_qp];
}

ADReal
ADBlackOilPhasePressureDifferenceMaterial::gasSaturation() const
{
  return _gas_saturation ? (*_gas_saturation)[_qp] : (*_gas_saturation_property)[_qp];
}

ADReal
ADBlackOilPhasePressureDifferenceMaterial::waterPressureDifference() const
{
  return _water_pressure_difference ? (*_water_pressure_difference)[_qp]
                                    : (*_water_pressure_difference_property)[_qp];
}

ADReal
ADBlackOilPhasePressureDifferenceMaterial::gasPressureDifference() const
{
  return _gas_pressure_difference ? (*_gas_pressure_difference)[_qp]
                                  : (*_gas_pressure_difference_property)[_qp];
}

ADReal
ADBlackOilPhasePressureDifferenceMaterial::interpolate(
    const ADReal & coordinate,
    const std::vector<Real> & points,
    const std::vector<Real> & values,
    const std::string & coordinate_name) const
{
  const Real raw_coordinate = MetaPhysicL::raw_value(coordinate);
  if (raw_coordinate < points.front())
  {
    if (_out_of_range_policy == "error")
      mooseError(name(), ": ", coordinate_name, " is below its capillary table interval.");
    if (_out_of_range_policy == "clamp")
      return values.front();
  }
  else if (raw_coordinate > points.back())
  {
    if (_out_of_range_policy == "error")
      mooseError(name(), ": ", coordinate_name, " is above its capillary table interval.");
    if (_out_of_range_policy == "clamp")
      return values.back();
  }

  unsigned int lower = 0;
  if (raw_coordinate >= points.back())
    lower = points.size() - 2;
  else if (raw_coordinate > points.front())
    lower = std::distance(
                points.begin(), std::upper_bound(points.begin(), points.end(), raw_coordinate)) -
            1;
  const Real slope = (values[lower + 1] - values[lower]) /
                     (points[lower + 1] - points[lower]);
  return values[lower] + slope * (coordinate - points[lower]);
}

void
ADBlackOilPhasePressureDifferenceMaterial::computeQpProperties()
{
  _water_stored_surface_energy_difference[_qp] =
      -interpolate(waterSaturation(),
                   _water_saturation_points,
                   _water_oil_capillary_pressure_values,
                   "water saturation");
  _gas_stored_surface_energy_difference[_qp] =
      interpolate(gasSaturation(),
                  _gas_saturation_points,
                  _gas_oil_capillary_pressure_values,
                  "gas saturation");
  _water_electrical_enthalpy_difference[_qp] =
      _water_electrical_enthalpy_difference_input
          ? (*_water_electrical_enthalpy_difference_input)[_qp]
          : 0.0;
  _gas_electrical_enthalpy_difference[_qp] =
      _gas_electrical_enthalpy_difference_input
          ? (*_gas_electrical_enthalpy_difference_input)[_qp]
          : 0.0;
  _water_saturation_force_difference[_qp] =
      _water_saturation_force_difference_input
          ? (*_water_saturation_force_difference_input)[_qp]
          : 0.0;
  _gas_saturation_force_difference[_qp] =
      _gas_saturation_force_difference_input ? (*_gas_saturation_force_difference_input)[_qp]
                                             : 0.0;
  _water_reconstructed_pressure_difference[_qp] =
      _water_stored_surface_energy_difference[_qp] +
      _water_electrical_enthalpy_difference[_qp] +
      _water_saturation_force_difference[_qp];
  _gas_reconstructed_pressure_difference[_qp] =
      _gas_stored_surface_energy_difference[_qp] +
      _gas_electrical_enthalpy_difference[_qp] +
      _gas_saturation_force_difference[_qp];
  _water_pressure_difference_closure_residual[_qp] =
      waterPressureDifference() - _water_reconstructed_pressure_difference[_qp];
  _gas_pressure_difference_closure_residual[_qp] =
      gasPressureDifference() - _gas_reconstructed_pressure_difference[_qp];
}
