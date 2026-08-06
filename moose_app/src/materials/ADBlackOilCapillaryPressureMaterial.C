#include "ADBlackOilCapillaryPressureMaterial.h"

#include "metaphysicl/raw_type.h"

#include <algorithm>

registerMooseObject("MulticomponentReactiveFlowApp", ADBlackOilCapillaryPressureMaterial);

InputParameters
ADBlackOilCapillaryPressureMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Reconstructs water and gas pressures from an oil reference pressure using fixed-history "
      "tabulated capillary curves and optional diagonal dynamic-capillary coefficients.");
  params.addRequiredCoupledVar("oil_pressure", "Oil reference pressure p_o.");
  params.addRequiredCoupledVar("water_pressure", "Water pressure p_w constrained by the closure.");
  params.addRequiredCoupledVar("gas_pressure", "Gas pressure p_g constrained by the closure.");
  params.addCoupledVar("water_saturation", "Water-saturation backbone or total field S_w.");
  params.addParam<MaterialPropertyName>(
      "water_saturation_name",
      "",
      "Optional AD material property containing reconstructed total water saturation. Supply "
      "exactly one of water_saturation or water_saturation_name.");
  params.addParam<MaterialPropertyName>(
      "water_saturation_rate_name",
      "",
      "Reconstructed total water-saturation rate property required with a nonzero dynamic "
      "coefficient when water_saturation_name is used.");
  params.addCoupledVar("gas_saturation", "Gas-saturation backbone or total field S_g.");
  params.addParam<MaterialPropertyName>(
      "gas_saturation_name",
      "",
      "Optional AD material property containing reconstructed total gas saturation. Supply "
      "exactly one of gas_saturation or gas_saturation_name.");
  params.addParam<MaterialPropertyName>(
      "gas_saturation_rate_name",
      "",
      "Reconstructed total gas-saturation rate property required with a nonzero dynamic "
      "coefficient when gas_saturation_name is used.");
  params.addRequiredParam<std::vector<Real>>(
      "water_saturation_points", "Strictly increasing S_w coordinates for p_cow.");
  params.addRequiredParam<std::vector<Real>>(
      "water_oil_capillary_pressure_values", "Water-oil capillary pressure p_cow values.");
  params.addRequiredParam<std::vector<Real>>(
      "gas_saturation_points", "Strictly increasing S_g coordinates for p_cgo.");
  params.addRequiredParam<std::vector<Real>>(
      "gas_oil_capillary_pressure_values", "Gas-oil capillary pressure p_cgo values.");
  params.addRangeCheckedParam<Real>("water_oil_dynamic_coefficient",
                                    0.0,
                                    "water_oil_dynamic_coefficient>=0",
                                    "Diagonal dynamic coefficient T_ow.");
  params.addRangeCheckedParam<Real>("gas_oil_dynamic_coefficient",
                                    0.0,
                                    "gas_oil_dynamic_coefficient>=0",
                                    "Diagonal dynamic coefficient T_go.");
  params.addParam<MooseEnum>("out_of_range_policy",
                             MooseEnum("error clamp linear", "error"),
                             "Policy for saturations outside each tabulated interval.");
  params.addParam<std::string>(
      "property_prefix", "black_oil", "Prefix for all declared material properties.");
  return params;
}

ADBlackOilCapillaryPressureMaterial::ADBlackOilCapillaryPressureMaterial(
    const InputParameters & parameters)
  : Material(parameters),
    _oil_pressure(adCoupledValue("oil_pressure")),
    _water_pressure(adCoupledValue("water_pressure")),
    _gas_pressure(adCoupledValue("gas_pressure")),
    _water_saturation(isCoupled("water_saturation") ? &adCoupledValue("water_saturation") : nullptr),
    _water_saturation_property(getParam<MaterialPropertyName>("water_saturation_name").empty()
                                   ? nullptr
                                   : &getADMaterialProperty<Real>("water_saturation_name")),
    _gas_saturation(isCoupled("gas_saturation") ? &adCoupledValue("gas_saturation") : nullptr),
    _gas_saturation_property(getParam<MaterialPropertyName>("gas_saturation_name").empty()
                                 ? nullptr
                                 : &getADMaterialProperty<Real>("gas_saturation_name")),
    _water_saturation_dot(getParam<Real>("water_oil_dynamic_coefficient") > 0.0 &&
                                  isCoupled("water_saturation")
                              ? &adCoupledDot("water_saturation")
                              : nullptr),
    _water_saturation_property_dot(
        getParam<Real>("water_oil_dynamic_coefficient") > 0.0 &&
                !getParam<MaterialPropertyName>("water_saturation_rate_name").empty()
            ? &getADMaterialProperty<Real>("water_saturation_rate_name")
            : nullptr),
    _gas_saturation_dot(getParam<Real>("gas_oil_dynamic_coefficient") > 0.0 &&
                                isCoupled("gas_saturation")
                            ? &adCoupledDot("gas_saturation")
                            : nullptr),
    _gas_saturation_property_dot(
        getParam<Real>("gas_oil_dynamic_coefficient") > 0.0 &&
                !getParam<MaterialPropertyName>("gas_saturation_rate_name").empty()
            ? &getADMaterialProperty<Real>("gas_saturation_rate_name")
            : nullptr),
    _water_saturation_points(getParam<std::vector<Real>>("water_saturation_points")),
    _water_oil_capillary_pressure_values(
        getParam<std::vector<Real>>("water_oil_capillary_pressure_values")),
    _gas_saturation_points(getParam<std::vector<Real>>("gas_saturation_points")),
    _gas_oil_capillary_pressure_values(
        getParam<std::vector<Real>>("gas_oil_capillary_pressure_values")),
    _water_oil_dynamic_coefficient(getParam<Real>("water_oil_dynamic_coefficient")),
    _gas_oil_dynamic_coefficient(getParam<Real>("gas_oil_dynamic_coefficient")),
    _out_of_range_policy(getParam<MooseEnum>("out_of_range_policy")),
    _property_prefix(getParam<std::string>("property_prefix")),
    _water_oil_capillary_pressure(
        declareADProperty<Real>(prefixedName("water_oil_capillary_pressure"))),
    _gas_oil_capillary_pressure(
        declareADProperty<Real>(prefixedName("gas_oil_capillary_pressure"))),
    _reconstructed_water_pressure(
        declareADProperty<Real>(prefixedName("reconstructed_water_pressure"))),
    _reconstructed_gas_pressure(
        declareADProperty<Real>(prefixedName("reconstructed_gas_pressure"))),
    _water_pressure_closure_residual(
        declareADProperty<Real>(prefixedName("water_pressure_closure_residual"))),
    _gas_pressure_closure_residual(
        declareADProperty<Real>(prefixedName("gas_pressure_closure_residual")))
{
  if (static_cast<bool>(_water_saturation) == static_cast<bool>(_water_saturation_property))
    paramError("water_saturation_name",
               "Supply exactly one of water_saturation or water_saturation_name.");
  if (static_cast<bool>(_gas_saturation) == static_cast<bool>(_gas_saturation_property))
    paramError("gas_saturation_name",
               "Supply exactly one of gas_saturation or gas_saturation_name.");
  if (_water_saturation_property && _water_oil_dynamic_coefficient > 0.0 &&
      !_water_saturation_property_dot)
    paramError("water_saturation_rate_name",
               "Supply water_saturation_rate_name for reconstructed dynamic capillarity.");
  if (_gas_saturation_property && _gas_oil_dynamic_coefficient > 0.0 &&
      !_gas_saturation_property_dot)
    paramError("gas_saturation_rate_name",
               "Supply gas_saturation_rate_name for reconstructed dynamic capillarity.");
  if (_water_saturation &&
      !getParam<MaterialPropertyName>("water_saturation_rate_name").empty())
    paramError("water_saturation_rate_name",
               "water_saturation_rate_name is only valid with water_saturation_name.");
  if (_gas_saturation && !getParam<MaterialPropertyName>("gas_saturation_rate_name").empty())
    paramError("gas_saturation_rate_name",
               "gas_saturation_rate_name is only valid with gas_saturation_name.");
  if (_property_prefix.empty())
    paramError("property_prefix", "The material-property prefix must be nonempty.");

  const auto validate_table = [this](const std::vector<Real> & points,
                                     const std::vector<Real> & values,
                                     const std::string & point_parameter,
                                     const std::string & value_parameter) {
    if (points.size() < 2)
      paramError(point_parameter, "Supply at least two saturation points.");
    if (values.size() != points.size())
      paramError(value_parameter, "Supply exactly one value for each saturation point.");
    for (const auto i : make_range(points.size() - 1))
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

ADReal
ADBlackOilCapillaryPressureMaterial::waterSaturation() const
{
  return _water_saturation_property ? (*_water_saturation_property)[_qp]
                                    : (*_water_saturation)[_qp];
}

ADReal
ADBlackOilCapillaryPressureMaterial::gasSaturation() const
{
  return _gas_saturation_property ? (*_gas_saturation_property)[_qp]
                                  : (*_gas_saturation)[_qp];
}

ADReal
ADBlackOilCapillaryPressureMaterial::waterSaturationDot() const
{
  return _water_saturation_property_dot ? (*_water_saturation_property_dot)[_qp]
                                        : (*_water_saturation_dot)[_qp];
}

ADReal
ADBlackOilCapillaryPressureMaterial::gasSaturationDot() const
{
  return _gas_saturation_property_dot ? (*_gas_saturation_property_dot)[_qp]
                                      : (*_gas_saturation_dot)[_qp];
}

MaterialPropertyName
ADBlackOilCapillaryPressureMaterial::prefixedName(const std::string & suffix) const
{
  return MaterialPropertyName(_property_prefix + "_" + suffix);
}

ADReal
ADBlackOilCapillaryPressureMaterial::interpolate(const ADReal & coordinate,
                                                 const std::vector<Real> & points,
                                                 const std::vector<Real> & values,
                                                 const std::string & coordinate_name) const
{
  const Real coordinate_value = MetaPhysicL::raw_value(coordinate);
  const auto last = points.size() - 1;

  if (coordinate_value < points.front())
  {
    if (_out_of_range_policy == "error")
      mooseError(name(), ": ", coordinate_name, " is below its capillary table interval.");
    if (_out_of_range_policy == "clamp")
      return values.front();
  }
  else if (coordinate_value > points.back())
  {
    if (_out_of_range_policy == "error")
      mooseError(name(), ": ", coordinate_name, " is above its capillary table interval.");
    if (_out_of_range_policy == "clamp")
      return values.back();
  }

  unsigned int lower = 0;
  if (coordinate_value >= points.back())
    lower = last - 1;
  else if (coordinate_value > points.front())
    lower = std::distance(
        points.begin(), std::upper_bound(points.begin(), points.end(), coordinate_value)) -
            1;

  const Real slope = (values[lower + 1] - values[lower]) / (points[lower + 1] - points[lower]);
  return values[lower] + slope * (coordinate - points[lower]);
}

void
ADBlackOilCapillaryPressureMaterial::computeQpProperties()
{
  const ADReal water_saturation = waterSaturation();
  const ADReal gas_saturation = gasSaturation();
  _water_oil_capillary_pressure[_qp] =
      interpolate(water_saturation,
                  _water_saturation_points,
                  _water_oil_capillary_pressure_values,
                  "water saturation");
  _gas_oil_capillary_pressure[_qp] = interpolate(gas_saturation,
                                                 _gas_saturation_points,
                                                 _gas_oil_capillary_pressure_values,
                                                 "gas saturation");

  const ADReal water_dynamic_pressure =
      (_water_saturation_dot || _water_saturation_property_dot)
          ? _water_oil_dynamic_coefficient * waterSaturationDot()
          : 0.0;
  const ADReal gas_dynamic_pressure =
      (_gas_saturation_dot || _gas_saturation_property_dot)
          ? _gas_oil_dynamic_coefficient * gasSaturationDot()
          : 0.0;
  _reconstructed_water_pressure[_qp] = _oil_pressure[_qp] -
                                       _water_oil_capillary_pressure[_qp] +
                                       water_dynamic_pressure;
  _reconstructed_gas_pressure[_qp] =
      _oil_pressure[_qp] + _gas_oil_capillary_pressure[_qp] + gas_dynamic_pressure;
  _water_pressure_closure_residual[_qp] =
      _water_pressure[_qp] - _reconstructed_water_pressure[_qp];
  _gas_pressure_closure_residual[_qp] =
      _gas_pressure[_qp] - _reconstructed_gas_pressure[_qp];
}
