#include "ADBlackOilRelativePermeabilityMaterial.h"

#include "metaphysicl/raw_type.h"

#include <algorithm>

registerMooseObject("MulticomponentReactiveFlowApp", ADBlackOilRelativePermeabilityMaterial);

InputParameters
ADBlackOilRelativePermeabilityMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Evaluates SWOF/SGOF-style water and gas relative permeabilities and the default "
      "ECLIPSE/OPM saturation-weighted three-phase oil relative permeability.");
  params.addCoupledVar("water_saturation", "Water-saturation backbone or total field S_w.");
  params.addParam<MaterialPropertyName>(
      "water_saturation_name",
      "",
      "Optional AD material property containing reconstructed total water saturation. Supply "
      "exactly one of water_saturation or water_saturation_name.");
  params.addCoupledVar("gas_saturation", "Gas-saturation backbone or total field S_g.");
  params.addParam<MaterialPropertyName>(
      "gas_saturation_name",
      "",
      "Optional AD material property containing reconstructed total gas saturation. Supply "
      "exactly one of gas_saturation or gas_saturation_name.");
  params.addRequiredParam<std::vector<Real>>(
      "water_saturation_points", "Strictly increasing SWOF water-saturation coordinates.");
  params.addRequiredParam<std::vector<Real>>(
      "water_relative_permeability_values", "SWOF water relative-permeability values.");
  params.addRequiredParam<std::vector<Real>>(
      "oil_water_relative_permeability_values",
      "SWOF oil relative-permeability values in the oil-water system.");
  params.addRequiredParam<std::vector<Real>>(
      "gas_saturation_points", "Strictly increasing SGOF gas-saturation coordinates.");
  params.addRequiredParam<std::vector<Real>>(
      "gas_relative_permeability_values", "SGOF gas relative-permeability values.");
  params.addRequiredParam<std::vector<Real>>(
      "oil_gas_relative_permeability_values",
      "SGOF oil relative-permeability values in the oil-gas system.");
  params.addParam<MooseEnum>("out_of_range_policy",
                             MooseEnum("error clamp linear", "clamp"),
                             "Policy for saturations outside each tabulated interval.");
  params.addParam<std::string>(
      "property_prefix", "black_oil", "Prefix for all declared material properties.");
  return params;
}

ADBlackOilRelativePermeabilityMaterial::ADBlackOilRelativePermeabilityMaterial(
    const InputParameters & parameters)
  : Material(parameters),
    _water_saturation(isCoupled("water_saturation") ? &adCoupledValue("water_saturation")
                                                     : nullptr),
    _water_saturation_property(getParam<MaterialPropertyName>("water_saturation_name").empty()
                                   ? nullptr
                                   : &getADMaterialProperty<Real>("water_saturation_name")),
    _gas_saturation(isCoupled("gas_saturation") ? &adCoupledValue("gas_saturation") : nullptr),
    _gas_saturation_property(getParam<MaterialPropertyName>("gas_saturation_name").empty()
                                 ? nullptr
                                 : &getADMaterialProperty<Real>("gas_saturation_name")),
    _water_saturation_points(getParam<std::vector<Real>>("water_saturation_points")),
    _water_relative_permeability_values(
        getParam<std::vector<Real>>("water_relative_permeability_values")),
    _oil_water_relative_permeability_values(
        getParam<std::vector<Real>>("oil_water_relative_permeability_values")),
    _gas_saturation_points(getParam<std::vector<Real>>("gas_saturation_points")),
    _gas_relative_permeability_values(
        getParam<std::vector<Real>>("gas_relative_permeability_values")),
    _oil_gas_relative_permeability_values(
        getParam<std::vector<Real>>("oil_gas_relative_permeability_values")),
    _out_of_range_policy(getParam<MooseEnum>("out_of_range_policy")),
    _property_prefix(getParam<std::string>("property_prefix")),
    _water_relative_permeability(
        declareADProperty<Real>(prefixedName("water_relative_permeability"))),
    _oil_relative_permeability(
        declareADProperty<Real>(prefixedName("oil_relative_permeability"))),
    _gas_relative_permeability(
        declareADProperty<Real>(prefixedName("gas_relative_permeability"))),
    _oil_water_relative_permeability(
        declareADProperty<Real>(prefixedName("oil_water_relative_permeability"))),
    _oil_gas_relative_permeability(
        declareADProperty<Real>(prefixedName("oil_gas_relative_permeability")))
{
  if (static_cast<bool>(_water_saturation) ==
      static_cast<bool>(_water_saturation_property))
    paramError("water_saturation_name",
               "Supply exactly one of water_saturation or water_saturation_name.");
  if (static_cast<bool>(_gas_saturation) == static_cast<bool>(_gas_saturation_property))
    paramError("gas_saturation_name",
               "Supply exactly one of gas_saturation or gas_saturation_name.");
  if (_property_prefix.empty())
    paramError("property_prefix", "The material-property prefix must be nonempty.");

  const auto validate_table = [this](const std::vector<Real> & points,
                                     const std::vector<Real> & first_values,
                                     const std::vector<Real> & second_values,
                                     const std::string & point_parameter,
                                     const std::string & first_parameter,
                                     const std::string & second_parameter) {
    if (points.size() < 2)
      paramError(point_parameter, "Supply at least two saturation points.");
    if (first_values.size() != points.size())
      paramError(first_parameter, "Supply exactly one value for each saturation point.");
    if (second_values.size() != points.size())
      paramError(second_parameter, "Supply exactly one value for each saturation point.");
    for (const auto i : make_range(points.size() - 1))
      if (points[i + 1] <= points[i])
        paramError(point_parameter, "Saturation points must be strictly increasing.");
    for (const auto value : first_values)
      if (value < 0.0)
        paramError(first_parameter, "Relative-permeability values must be nonnegative.");
    for (const auto value : second_values)
      if (value < 0.0)
        paramError(second_parameter, "Relative-permeability values must be nonnegative.");
  };
  validate_table(_water_saturation_points,
                 _water_relative_permeability_values,
                 _oil_water_relative_permeability_values,
                 "water_saturation_points",
                 "water_relative_permeability_values",
                 "oil_water_relative_permeability_values");
  validate_table(_gas_saturation_points,
                 _gas_relative_permeability_values,
                 _oil_gas_relative_permeability_values,
                 "gas_saturation_points",
                 "gas_relative_permeability_values",
                 "oil_gas_relative_permeability_values");
}

MaterialPropertyName
ADBlackOilRelativePermeabilityMaterial::prefixedName(const std::string & suffix) const
{
  return MaterialPropertyName(_property_prefix + "_" + suffix);
}

ADReal
ADBlackOilRelativePermeabilityMaterial::interpolate(const ADReal & coordinate,
                                                    const std::vector<Real> & points,
                                                    const std::vector<Real> & values) const
{
  const Real coordinate_value = MetaPhysicL::raw_value(coordinate);
  const auto last = points.size() - 1;

  if (coordinate_value < points.front())
  {
    if (_out_of_range_policy == "error")
      mooseError(name(), ": saturation is below a relative-permeability table interval.");
    if (_out_of_range_policy == "clamp")
      return values.front();
  }
  else if (coordinate_value > points.back())
  {
    if (_out_of_range_policy == "error")
      mooseError(name(), ": saturation is above a relative-permeability table interval.");
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
ADBlackOilRelativePermeabilityMaterial::computeQpProperties()
{
  const Real connate_water_saturation = _water_saturation_points.front();
  const ADReal raw_water_saturation =
      _water_saturation ? (*_water_saturation)[_qp] : (*_water_saturation_property)[_qp];
  const ADReal water_saturation =
      MetaPhysicL::raw_value(raw_water_saturation) < connate_water_saturation
          ? ADReal(connate_water_saturation)
          : raw_water_saturation;
  const ADReal raw_gas_saturation =
      _gas_saturation ? (*_gas_saturation)[_qp] : (*_gas_saturation_property)[_qp];
  ADReal gas_saturation = raw_gas_saturation;
  if (_out_of_range_policy == "clamp")
  {
    if (MetaPhysicL::raw_value(raw_gas_saturation) < _gas_saturation_points.front())
      gas_saturation = _gas_saturation_points.front();
    else if (MetaPhysicL::raw_value(raw_gas_saturation) > _gas_saturation_points.back())
      gas_saturation = _gas_saturation_points.back();
  }
  const ADReal oil_water_curve_coordinate = water_saturation + gas_saturation;

  _water_relative_permeability[_qp] = interpolate(
      water_saturation, _water_saturation_points, _water_relative_permeability_values);
  _gas_relative_permeability[_qp] =
      interpolate(gas_saturation, _gas_saturation_points, _gas_relative_permeability_values);
  _oil_water_relative_permeability[_qp] = interpolate(oil_water_curve_coordinate,
                                                      _water_saturation_points,
                                                      _oil_water_relative_permeability_values);
  _oil_gas_relative_permeability[_qp] = interpolate(
      gas_saturation, _gas_saturation_points, _oil_gas_relative_permeability_values);

  const ADReal mobile_water_saturation = water_saturation - connate_water_saturation;
  const ADReal blend_denominator = gas_saturation + mobile_water_saturation;
  constexpr Real regularization = 1e-5;
  if (MetaPhysicL::raw_value(blend_denominator) <= regularization / 2.0)
    _oil_relative_permeability[_qp] =
        0.5 * (_oil_water_relative_permeability[_qp] + _oil_gas_relative_permeability[_qp]);
  else
  {
    const ADReal weighted_oil_relative_permeability =
        (gas_saturation * _oil_gas_relative_permeability[_qp] +
         mobile_water_saturation * _oil_water_relative_permeability[_qp]) /
        blend_denominator;
    if (MetaPhysicL::raw_value(blend_denominator) < regularization)
    {
      const ADReal regularized_oil_relative_permeability =
          0.5 * (_oil_water_relative_permeability[_qp] +
                 _oil_gas_relative_permeability[_qp]);
      const ADReal regularized_weight =
          (regularization - blend_denominator) / (regularization / 2.0);
      _oil_relative_permeability[_qp] =
          regularized_weight * regularized_oil_relative_permeability +
          (1.0 - regularized_weight) * weighted_oil_relative_permeability;
    }
    else
      _oil_relative_permeability[_qp] = weighted_oil_relative_permeability;
  }
}
