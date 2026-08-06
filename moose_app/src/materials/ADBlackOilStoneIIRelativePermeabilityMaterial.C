#include "ADBlackOilStoneIIRelativePermeabilityMaterial.h"

#include "metaphysicl/raw_type.h"

#include <algorithm>

registerMooseObject("MulticomponentReactiveFlowApp",
                    ADBlackOilStoneIIRelativePermeabilityMaterial);

InputParameters
ADBlackOilStoneIIRelativePermeabilityMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Evaluates tabulated two-phase water/oil and gas/oil curves and combines the oil curves "
      "with Stone's second three-phase relative-permeability model for SPE2.");
  params.addCoupledVar("water_saturation", "Water-saturation backbone or total field S_w.");
  params.addParam<MaterialPropertyName>(
      "water_saturation_name",
      "",
      "Optional AD reconstructed total water-saturation property. Supply exactly one water "
      "saturation input.");
  params.addCoupledVar("gas_saturation", "Gas-saturation backbone or total field S_g.");
  params.addParam<MaterialPropertyName>(
      "gas_saturation_name",
      "",
      "Optional AD reconstructed total gas-saturation property. Supply exactly one gas "
      "saturation input.");
  params.addRequiredParam<std::vector<Real>>(
      "water_saturation_points", "Strictly increasing water-saturation coordinates.");
  params.addRequiredParam<std::vector<Real>>(
      "water_relative_permeability_values", "Water relative-permeability values.");
  params.addRequiredParam<std::vector<Real>>(
      "oil_water_relative_permeability_values", "Oil values in the oil-water system.");
  params.addRequiredParam<std::vector<Real>>(
      "gas_saturation_points", "Strictly increasing gas-saturation coordinates.");
  params.addRequiredParam<std::vector<Real>>(
      "gas_relative_permeability_values", "Gas relative-permeability values.");
  params.addRequiredParam<std::vector<Real>>(
      "oil_gas_relative_permeability_values", "Oil values in the oil-gas system.");
  params.addParam<MooseEnum>("out_of_range_policy",
                             MooseEnum("error clamp linear", "clamp"),
                             "Policy for saturations outside each tabulated interval.");
  params.addParam<bool>(
      "clamp_oil_relative_permeability",
      true,
      "Clamp the Stone-II oil value to [0,k_rocw] after retaining its unclamped diagnostic.");
  params.addParam<std::string>(
      "property_prefix", "stone_ii", "Prefix for all declared material properties.");
  return params;
}

ADBlackOilStoneIIRelativePermeabilityMaterial::
    ADBlackOilStoneIIRelativePermeabilityMaterial(const InputParameters & parameters)
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
    _clamp_oil_relative_permeability(getParam<bool>("clamp_oil_relative_permeability")),
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
        declareADProperty<Real>(prefixedName("oil_gas_relative_permeability"))),
    _unclamped_oil_relative_permeability(
        declareADProperty<Real>(prefixedName("unclamped_oil_relative_permeability")))
{
  if (static_cast<bool>(_water_saturation) ==
      static_cast<bool>(_water_saturation_property))
    paramError("water_saturation_name", "Supply exactly one water-saturation input.");
  if (static_cast<bool>(_gas_saturation) == static_cast<bool>(_gas_saturation_property))
    paramError("gas_saturation_name", "Supply exactly one gas-saturation input.");
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
      paramError(first_parameter, "Supply one value for each saturation point.");
    if (second_values.size() != points.size())
      paramError(second_parameter, "Supply one value for each saturation point.");
    for (unsigned int i = 0; i + 1 < points.size(); ++i)
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
  if (_oil_water_relative_permeability_values.front() <= 0.0)
    paramError("oil_water_relative_permeability_values",
               "Stone II requires a positive oil relative permeability k_rocw at connate water.");
}

MaterialPropertyName
ADBlackOilStoneIIRelativePermeabilityMaterial::prefixedName(const std::string & suffix) const
{
  return MaterialPropertyName(_property_prefix + "_" + suffix);
}

ADReal
ADBlackOilStoneIIRelativePermeabilityMaterial::interpolate(
    const ADReal & coordinate,
    const std::vector<Real> & points,
    const std::vector<Real> & values) const
{
  const Real raw_coordinate = MetaPhysicL::raw_value(coordinate);
  if (raw_coordinate < points.front())
  {
    if (_out_of_range_policy == "error")
      mooseError(name(), ": saturation is below a relative-permeability table interval.");
    if (_out_of_range_policy == "clamp")
      return values.front();
  }
  else if (raw_coordinate > points.back())
  {
    if (_out_of_range_policy == "error")
      mooseError(name(), ": saturation is above a relative-permeability table interval.");
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
ADBlackOilStoneIIRelativePermeabilityMaterial::computeQpProperties()
{
  ADReal water_saturation =
      _water_saturation ? (*_water_saturation)[_qp] : (*_water_saturation_property)[_qp];
  ADReal gas_saturation =
      _gas_saturation ? (*_gas_saturation)[_qp] : (*_gas_saturation_property)[_qp];
  if (_out_of_range_policy == "clamp")
  {
    if (MetaPhysicL::raw_value(water_saturation) < _water_saturation_points.front())
      water_saturation = _water_saturation_points.front();
    else if (MetaPhysicL::raw_value(water_saturation) > _water_saturation_points.back())
      water_saturation = _water_saturation_points.back();
    if (MetaPhysicL::raw_value(gas_saturation) < _gas_saturation_points.front())
      gas_saturation = _gas_saturation_points.front();
    else if (MetaPhysicL::raw_value(gas_saturation) > _gas_saturation_points.back())
      gas_saturation = _gas_saturation_points.back();
  }

  _water_relative_permeability[_qp] = interpolate(water_saturation,
                                                   _water_saturation_points,
                                                   _water_relative_permeability_values);
  _oil_water_relative_permeability[_qp] =
      interpolate(water_saturation,
                  _water_saturation_points,
                  _oil_water_relative_permeability_values);
  _gas_relative_permeability[_qp] = interpolate(
      gas_saturation, _gas_saturation_points, _gas_relative_permeability_values);
  _oil_gas_relative_permeability[_qp] = interpolate(
      gas_saturation, _gas_saturation_points, _oil_gas_relative_permeability_values);

  const Real oil_at_connate_water = _oil_water_relative_permeability_values.front();
  _unclamped_oil_relative_permeability[_qp] =
      oil_at_connate_water *
      ((_oil_water_relative_permeability[_qp] / oil_at_connate_water +
        _water_relative_permeability[_qp]) *
           (_oil_gas_relative_permeability[_qp] / oil_at_connate_water +
            _gas_relative_permeability[_qp]) -
       _water_relative_permeability[_qp] - _gas_relative_permeability[_qp]);

  _oil_relative_permeability[_qp] = _unclamped_oil_relative_permeability[_qp];
  if (_clamp_oil_relative_permeability)
  {
    if (MetaPhysicL::raw_value(_oil_relative_permeability[_qp]) < 0.0)
      _oil_relative_permeability[_qp] = 0.0;
    else if (MetaPhysicL::raw_value(_oil_relative_permeability[_qp]) > oil_at_connate_water)
      _oil_relative_permeability[_qp] = oil_at_connate_water;
  }
}
