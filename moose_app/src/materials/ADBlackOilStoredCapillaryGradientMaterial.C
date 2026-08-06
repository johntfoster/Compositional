#include "ADBlackOilStoredCapillaryGradientMaterial.h"

#include "metaphysicl/raw_type.h"

#include <algorithm>

registerMooseObject("MulticomponentReactiveFlowApp",
                    ADBlackOilStoredCapillaryGradientMaterial);

InputParameters
ADBlackOilStoredCapillaryGradientMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Evaluates the stored surface-energy parts of p_w-p_o and p_g-p_o and their "
      "solid-reference gradients from tabulated black-oil capillary curves.");
  params.addRequiredParam<MaterialPropertyName>("water_saturation_name",
                                                 "Reconstructed total water saturation.");
  params.addRequiredParam<MaterialPropertyName>("water_saturation_gradient_name",
                                                 "Reference gradient of total water saturation.");
  params.addRequiredParam<MaterialPropertyName>("gas_saturation_name",
                                                 "Reconstructed total gas saturation.");
  params.addRequiredParam<MaterialPropertyName>("gas_saturation_gradient_name",
                                                 "Reference gradient of total gas saturation.");
  params.addRequiredParam<std::vector<Real>>("water_saturation_points",
                                              "Strictly increasing water-saturation points.");
  params.addRequiredParam<std::vector<Real>>("water_oil_capillary_pressure_values",
                                              "Stored oil-minus-water capillary pressures.");
  params.addRequiredParam<std::vector<Real>>("gas_saturation_points",
                                              "Strictly increasing gas-saturation points.");
  params.addRequiredParam<std::vector<Real>>("gas_oil_capillary_pressure_values",
                                              "Stored gas-minus-oil capillary pressures.");
  params.addParam<MooseEnum>("out_of_range_policy",
                             MooseEnum("error clamp linear", "error"),
                             "Policy outside each saturation table.");
  params.addParam<std::string>("property_prefix",
                               "black_oil_stored_capillary",
                               "Prefix for output properties.");
  return params;
}

ADBlackOilStoredCapillaryGradientMaterial::ADBlackOilStoredCapillaryGradientMaterial(
    const InputParameters & parameters)
  : Material(parameters),
    _water_saturation(getADMaterialProperty<Real>("water_saturation_name")),
    _water_saturation_gradient(
        getADMaterialProperty<RealVectorValue>("water_saturation_gradient_name")),
    _gas_saturation(getADMaterialProperty<Real>("gas_saturation_name")),
    _gas_saturation_gradient(
        getADMaterialProperty<RealVectorValue>("gas_saturation_gradient_name")),
    _water_saturation_points(getParam<std::vector<Real>>("water_saturation_points")),
    _water_oil_capillary_pressure_values(
        getParam<std::vector<Real>>("water_oil_capillary_pressure_values")),
    _gas_saturation_points(getParam<std::vector<Real>>("gas_saturation_points")),
    _gas_oil_capillary_pressure_values(
        getParam<std::vector<Real>>("gas_oil_capillary_pressure_values")),
    _out_of_range_policy(getParam<MooseEnum>("out_of_range_policy")),
    _property_prefix(getParam<std::string>("property_prefix")),
    _water_stored_pressure_difference(
        declareADProperty<Real>(prefixedName("water_pressure_difference"))),
    _water_stored_pressure_difference_gradient(
        declareADProperty<RealVectorValue>(prefixedName("water_pressure_difference_gradient"))),
    _gas_stored_pressure_difference(
        declareADProperty<Real>(prefixedName("gas_pressure_difference"))),
    _gas_stored_pressure_difference_gradient(
        declareADProperty<RealVectorValue>(prefixedName("gas_pressure_difference_gradient")))
{
  if (_property_prefix.empty())
    paramError("property_prefix", "The output-property prefix must be nonempty.");

  const auto validate_table = [this](const std::vector<Real> & points,
                                     const std::vector<Real> & values,
                                     const std::string & point_parameter,
                                     const std::string & value_parameter) {
    if (points.size() < 2)
      paramError(point_parameter, "Supply at least two saturation points.");
    if (points.size() != values.size())
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
ADBlackOilStoredCapillaryGradientMaterial::prefixedName(const std::string & suffix) const
{
  return MaterialPropertyName(_property_prefix + "_" + suffix);
}

std::pair<ADReal, Real>
ADBlackOilStoredCapillaryGradientMaterial::interpolateValueAndSlope(
    const ADReal & coordinate,
    const std::vector<Real> & points,
    const std::vector<Real> & values,
    const std::string & coordinate_name) const
{
  const Real raw_coordinate = MetaPhysicL::raw_value(coordinate);
  if (raw_coordinate < points.front())
  {
    if (_out_of_range_policy == "error")
      mooseError(name(), ": ", coordinate_name, " is below its table interval.");
    if (_out_of_range_policy == "clamp")
      return {ADReal(values.front()), 0.0};
  }
  else if (raw_coordinate > points.back())
  {
    if (_out_of_range_policy == "error")
      mooseError(name(), ": ", coordinate_name, " is above its table interval.");
    if (_out_of_range_policy == "clamp")
      return {ADReal(values.back()), 0.0};
  }

  unsigned int lower = 0;
  if (raw_coordinate >= points.back())
    lower = points.size() - 2;
  else if (raw_coordinate > points.front())
    lower = std::distance(
                points.begin(), std::upper_bound(points.begin(), points.end(), raw_coordinate)) -
            1;
  const Real slope =
      (values[lower + 1] - values[lower]) / (points[lower + 1] - points[lower]);
  return {values[lower] + slope * (coordinate - points[lower]), slope};
}

void
ADBlackOilStoredCapillaryGradientMaterial::computeQpProperties()
{
  const auto water = interpolateValueAndSlope(_water_saturation[_qp],
                                               _water_saturation_points,
                                               _water_oil_capillary_pressure_values,
                                               "water saturation");
  const auto gas = interpolateValueAndSlope(_gas_saturation[_qp],
                                             _gas_saturation_points,
                                             _gas_oil_capillary_pressure_values,
                                             "gas saturation");

  _water_stored_pressure_difference[_qp] = -water.first;
  _water_stored_pressure_difference_gradient[_qp] =
      -water.second * _water_saturation_gradient[_qp];
  _gas_stored_pressure_difference[_qp] = gas.first;
  _gas_stored_pressure_difference_gradient[_qp] =
      gas.second * _gas_saturation_gradient[_qp];
}
