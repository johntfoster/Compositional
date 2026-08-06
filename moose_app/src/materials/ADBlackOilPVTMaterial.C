#include "ADBlackOilPVTMaterial.h"

#include "metaphysicl/raw_type.h"

#include <algorithm>

registerMooseObject("MulticomponentReactiveFlowApp", ADBlackOilPVTMaterial);

InputParameters
ADBlackOilPVTMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Evaluates pressure-tabulated black-oil formation-volume factors and solution-gas data, "
      "then computes phase densities, oil-phase component fractions, and water/oil/gas "
      "component storage on the solid reference configuration.");
  params.addParam<MaterialPropertyName>(
      "jacobian_name", "solid_reference_J", "Material property name for the solid-reference J.");
  params.addParam<MaterialPropertyName>("jacobian_rate_name",
                                        "solid_reference_J_dot",
                                        "Material property name for the material time rate of J.");
  params.addParam<bool>(
      "compute_storage_rates",
      false,
      "Compute chain-rule reference-storage rates from transient coupled-variable rates.");
  params.addCoupledVar("pressure", "Black-oil reference pressure backbone or total field.");
  params.addParam<MaterialPropertyName>(
      "pressure_name",
      "",
      "Optional AD material property containing reconstructed total pressure. Supply exactly "
      "one of pressure or pressure_name.");
  params.addParam<MaterialPropertyName>(
      "pressure_rate_name",
      "",
      "AD material property containing the reconstructed total-pressure time derivative when "
      "pressure_name is used with compute_storage_rates=true.");
  params.addRequiredCoupledVar("porosity", "Current pore-volume fraction phi.");
  params.addCoupledVar("water_saturation", "Water-saturation backbone or total field S_w.");
  params.addParam<MaterialPropertyName>(
      "water_saturation_name",
      "",
      "Optional AD material property containing reconstructed total water saturation. Supply "
      "exactly one of water_saturation or water_saturation_name.");
  params.addParam<MaterialPropertyName>(
      "water_saturation_rate_name",
      "",
      "AD material property containing the reconstructed total water-saturation rate when "
      "water_saturation_name is used with compute_storage_rates=true.");
  params.addCoupledVar("gas_saturation", "Gas-saturation backbone or total field S_g.");
  params.addParam<MaterialPropertyName>(
      "gas_saturation_name",
      "",
      "Optional AD material property containing reconstructed total gas saturation. Supply "
      "exactly one of gas_saturation or gas_saturation_name.");
  params.addParam<MaterialPropertyName>(
      "gas_saturation_rate_name",
      "",
      "AD material property containing the reconstructed total gas-saturation rate when "
      "gas_saturation_name is used with compute_storage_rates=true.");
  params.addRequiredParam<std::vector<Real>>(
      "pressure_points", "Strictly increasing pressure coordinates for all PVT tables.");
  params.addRequiredParam<std::vector<Real>>(
      "water_formation_volume_factor_values", "Water formation-volume factor B_w values.");
  params.addRequiredParam<std::vector<Real>>(
      "oil_formation_volume_factor_values", "Oil formation-volume factor B_o values.");
  params.addRequiredParam<std::vector<Real>>(
      "gas_formation_volume_factor_values", "Gas formation-volume factor B_g values.");
  params.addRequiredParam<std::vector<Real>>(
      "solution_gas_oil_ratio_values", "Solution gas-oil ratio R_s values.");
  params.addParam<std::vector<Real>>(
      "water_viscosity_values", {}, "Optional water-viscosity values on pressure_points.");
  params.addParam<std::vector<Real>>(
      "oil_viscosity_values", {}, "Optional oil-viscosity values on pressure_points.");
  params.addParam<std::vector<Real>>(
      "gas_viscosity_values", {}, "Optional gas-viscosity values on pressure_points.");
  params.addParam<MooseEnum>(
      "out_of_range_policy",
      MooseEnum("error clamp linear", "error"),
      "Policy for pressures outside the tabulated interval.");
  params.addRequiredRangeCheckedParam<Real>(
      "water_surface_density", "water_surface_density>0", "Stock-tank water density.");
  params.addRequiredRangeCheckedParam<Real>(
      "oil_surface_density", "oil_surface_density>0", "Stock-tank oil density.");
  params.addRequiredRangeCheckedParam<Real>(
      "gas_surface_density", "gas_surface_density>0", "Stock-tank gas density.");
  params.addParam<std::string>(
      "property_prefix", "black_oil", "Prefix for all declared material properties.");
  return params;
}

ADBlackOilPVTMaterial::ADBlackOilPVTMaterial(const InputParameters & parameters)
  : Material(parameters),
    _J(getADMaterialProperty<Real>("jacobian_name")),
    _J_dot(getParam<bool>("compute_storage_rates")
               ? &getADMaterialProperty<Real>("jacobian_rate_name")
               : nullptr),
    _pressure(isCoupled("pressure") ? &adCoupledValue("pressure") : nullptr),
    _pressure_property(getParam<MaterialPropertyName>("pressure_name").empty()
                           ? nullptr
                           : &getADMaterialProperty<Real>("pressure_name")),
    _pressure_dot(getParam<bool>("compute_storage_rates") && isCoupled("pressure")
                      ? &adCoupledDot("pressure")
                      : nullptr),
    _pressure_property_dot(
        getParam<bool>("compute_storage_rates") &&
                !getParam<MaterialPropertyName>("pressure_rate_name").empty()
            ? &getADMaterialProperty<Real>("pressure_rate_name")
            : nullptr),
    _porosity(adCoupledValue("porosity")),
    _porosity_dot(getParam<bool>("compute_storage_rates") ? &adCoupledDot("porosity") : nullptr),
    _water_saturation(isCoupled("water_saturation") ? &adCoupledValue("water_saturation") : nullptr),
    _water_saturation_property(getParam<MaterialPropertyName>("water_saturation_name").empty()
                                   ? nullptr
                                   : &getADMaterialProperty<Real>("water_saturation_name")),
    _water_saturation_dot(getParam<bool>("compute_storage_rates")
                                  && isCoupled("water_saturation")
                              ? &adCoupledDot("water_saturation")
                              : nullptr),
    _water_saturation_property_dot(
        getParam<bool>("compute_storage_rates") &&
                !getParam<MaterialPropertyName>("water_saturation_rate_name").empty()
            ? &getADMaterialProperty<Real>("water_saturation_rate_name")
            : nullptr),
    _gas_saturation(isCoupled("gas_saturation") ? &adCoupledValue("gas_saturation") : nullptr),
    _gas_saturation_property(getParam<MaterialPropertyName>("gas_saturation_name").empty()
                                 ? nullptr
                                 : &getADMaterialProperty<Real>("gas_saturation_name")),
    _gas_saturation_dot(getParam<bool>("compute_storage_rates")
                                && isCoupled("gas_saturation")
                            ? &adCoupledDot("gas_saturation")
                            : nullptr),
    _gas_saturation_property_dot(
        getParam<bool>("compute_storage_rates") &&
                !getParam<MaterialPropertyName>("gas_saturation_rate_name").empty()
            ? &getADMaterialProperty<Real>("gas_saturation_rate_name")
            : nullptr),
    _pressure_points(getParam<std::vector<Real>>("pressure_points")),
    _water_fvf_values(
        getParam<std::vector<Real>>("water_formation_volume_factor_values")),
    _oil_fvf_values(getParam<std::vector<Real>>("oil_formation_volume_factor_values")),
    _gas_fvf_values(getParam<std::vector<Real>>("gas_formation_volume_factor_values")),
    _solution_gas_oil_ratio_values(
        getParam<std::vector<Real>>("solution_gas_oil_ratio_values")),
    _water_viscosity_values(getParam<std::vector<Real>>("water_viscosity_values")),
    _oil_viscosity_values(getParam<std::vector<Real>>("oil_viscosity_values")),
    _gas_viscosity_values(getParam<std::vector<Real>>("gas_viscosity_values")),
    _out_of_range_policy(getParam<MooseEnum>("out_of_range_policy")),
    _water_surface_density(getParam<Real>("water_surface_density")),
    _oil_surface_density(getParam<Real>("oil_surface_density")),
    _gas_surface_density(getParam<Real>("gas_surface_density")),
    _property_prefix(getParam<std::string>("property_prefix")),
    _water_fvf(declareADProperty<Real>(prefixedName("water_formation_volume_factor"))),
    _oil_fvf(declareADProperty<Real>(prefixedName("oil_formation_volume_factor"))),
    _gas_fvf(declareADProperty<Real>(prefixedName("gas_formation_volume_factor"))),
    _solution_gas_oil_ratio(declareADProperty<Real>(prefixedName("solution_gas_oil_ratio"))),
    _water_viscosity(declareADProperty<Real>(prefixedName("water_viscosity"))),
    _oil_viscosity(declareADProperty<Real>(prefixedName("oil_viscosity"))),
    _gas_viscosity(declareADProperty<Real>(prefixedName("gas_viscosity"))),
    _oil_saturation(declareADProperty<Real>(prefixedName("oil_saturation"))),
    _water_intrinsic_density(declareADProperty<Real>(prefixedName("water_intrinsic_density"))),
    _oil_intrinsic_density(declareADProperty<Real>(prefixedName("oil_intrinsic_density"))),
    _gas_intrinsic_density(declareADProperty<Real>(prefixedName("gas_intrinsic_density"))),
    _oil_component_mass_fraction_in_oil(
        declareADProperty<Real>(prefixedName("oil_component_mass_fraction_in_oil"))),
    _gas_component_mass_fraction_in_oil(
        declareADProperty<Real>(prefixedName("gas_component_mass_fraction_in_oil"))),
    _water_current_component_storage(
        declareADProperty<Real>(prefixedName("water_current_component_storage"))),
    _oil_current_component_storage(
        declareADProperty<Real>(prefixedName("oil_current_component_storage"))),
    _gas_current_component_storage(
        declareADProperty<Real>(prefixedName("gas_current_component_storage"))),
    _water_reference_component_storage(
        declareADProperty<Real>(prefixedName("water_reference_component_storage"))),
    _oil_reference_component_storage(
        declareADProperty<Real>(prefixedName("oil_reference_component_storage"))),
    _gas_reference_component_storage(
        declareADProperty<Real>(prefixedName("gas_reference_component_storage"))),
    _water_reference_component_storage_rate(
        declareADProperty<Real>(prefixedName("water_reference_component_storage_rate"))),
    _oil_reference_component_storage_rate(
        declareADProperty<Real>(prefixedName("oil_reference_component_storage_rate"))),
    _gas_reference_component_storage_rate(
        declareADProperty<Real>(prefixedName("gas_reference_component_storage_rate")))
{
  if (static_cast<bool>(_pressure) == static_cast<bool>(_pressure_property))
    paramError("pressure_name", "Supply exactly one of pressure or pressure_name.");
  if (_pressure_property && getParam<bool>("compute_storage_rates") && !_pressure_property_dot)
    paramError("pressure_rate_name",
               "Supply pressure_rate_name when reconstructed total pressure is used with "
               "compute_storage_rates=true.");
  if (_pressure && !getParam<MaterialPropertyName>("pressure_rate_name").empty())
    paramError("pressure_rate_name",
               "pressure_rate_name is only valid when pressure_name supplies pressure.");

  if (static_cast<bool>(_water_saturation) == static_cast<bool>(_water_saturation_property))
    paramError("water_saturation_name",
               "Supply exactly one of water_saturation or water_saturation_name.");
  if (static_cast<bool>(_gas_saturation) == static_cast<bool>(_gas_saturation_property))
    paramError("gas_saturation_name",
               "Supply exactly one of gas_saturation or gas_saturation_name.");
  if (_water_saturation_property && getParam<bool>("compute_storage_rates") &&
      !_water_saturation_property_dot)
    paramError("water_saturation_rate_name",
               "Supply water_saturation_rate_name when reconstructed total water saturation "
               "is used with compute_storage_rates=true.");
  if (_gas_saturation_property && getParam<bool>("compute_storage_rates") &&
      !_gas_saturation_property_dot)
    paramError("gas_saturation_rate_name",
               "Supply gas_saturation_rate_name when reconstructed total gas saturation is "
               "used with compute_storage_rates=true.");
  if (_water_saturation &&
      !getParam<MaterialPropertyName>("water_saturation_rate_name").empty())
    paramError("water_saturation_rate_name",
               "water_saturation_rate_name is only valid with water_saturation_name.");
  if (_gas_saturation && !getParam<MaterialPropertyName>("gas_saturation_rate_name").empty())
    paramError("gas_saturation_rate_name",
               "gas_saturation_rate_name is only valid with gas_saturation_name.");

  const auto point_count = _pressure_points.size();
  if (point_count < 2)
    paramError("pressure_points", "Supply at least two pressure points.");
  if (_property_prefix.empty())
    paramError("property_prefix", "The material-property prefix must be nonempty.");

  const auto require_table_size = [this, point_count](const std::vector<Real> & values,
                                                       const std::string & parameter) {
    if (values.size() != point_count)
      paramError(parameter, "Supply exactly one value for each pressure point.");
  };
  require_table_size(_water_fvf_values, "water_formation_volume_factor_values");
  require_table_size(_oil_fvf_values, "oil_formation_volume_factor_values");
  require_table_size(_gas_fvf_values, "gas_formation_volume_factor_values");
  require_table_size(_solution_gas_oil_ratio_values, "solution_gas_oil_ratio_values");
  const bool any_viscosity_table = !_water_viscosity_values.empty() || !_oil_viscosity_values.empty() ||
                                   !_gas_viscosity_values.empty();
  const bool all_viscosity_tables = !_water_viscosity_values.empty() && !_oil_viscosity_values.empty() &&
                                   !_gas_viscosity_values.empty();
  if (any_viscosity_table && !all_viscosity_tables)
    paramError("water_viscosity_values", "Supply water, oil, and gas viscosity tables together.");
  if (all_viscosity_tables)
  {
    require_table_size(_water_viscosity_values, "water_viscosity_values");
    require_table_size(_oil_viscosity_values, "oil_viscosity_values");
    require_table_size(_gas_viscosity_values, "gas_viscosity_values");
  }

  for (const auto i : make_range(point_count - 1))
    if (_pressure_points[i + 1] <= _pressure_points[i])
      paramError("pressure_points", "Pressure points must be strictly increasing.");
  for (const auto value : _water_fvf_values)
    if (value <= 0.0)
      paramError("water_formation_volume_factor_values", "All B_w values must be positive.");
  for (const auto value : _oil_fvf_values)
    if (value <= 0.0)
      paramError("oil_formation_volume_factor_values", "All B_o values must be positive.");
  for (const auto value : _gas_fvf_values)
    if (value <= 0.0)
      paramError("gas_formation_volume_factor_values", "All B_g values must be positive.");
  for (const auto value : _solution_gas_oil_ratio_values)
    if (value < 0.0)
      paramError("solution_gas_oil_ratio_values", "All R_s values must be nonnegative.");
  for (const auto value : _water_viscosity_values)
    if (value <= 0.0)
      paramError("water_viscosity_values", "All water-viscosity values must be positive.");
  for (const auto value : _oil_viscosity_values)
    if (value <= 0.0)
      paramError("oil_viscosity_values", "All oil-viscosity values must be positive.");
  for (const auto value : _gas_viscosity_values)
    if (value <= 0.0)
      paramError("gas_viscosity_values", "All gas-viscosity values must be positive.");
}

MaterialPropertyName
ADBlackOilPVTMaterial::prefixedName(const std::string & suffix) const
{
  return MaterialPropertyName(_property_prefix + "_" + suffix);
}

ADReal
ADBlackOilPVTMaterial::interpolate(const std::vector<Real> & values) const
{
  const ADReal pressure_value_ad = pressure();
  const Real pressure_value = MetaPhysicL::raw_value(pressure_value_ad);
  const auto last = _pressure_points.size() - 1;

  if (pressure_value < _pressure_points.front())
  {
    if (_out_of_range_policy == "error")
      mooseError(name(), ": pressure is below the PVT table interval.");
    if (_out_of_range_policy == "clamp")
      return values.front();
  }
  else if (pressure_value > _pressure_points.back())
  {
    if (_out_of_range_policy == "error")
      mooseError(name(), ": pressure is above the PVT table interval.");
    if (_out_of_range_policy == "clamp")
      return values.back();
  }

  unsigned int lower = 0;
  if (pressure_value >= _pressure_points.back())
    lower = last - 1;
  else if (pressure_value > _pressure_points.front())
    lower = std::distance(
        _pressure_points.begin(),
        std::upper_bound(_pressure_points.begin(), _pressure_points.end(), pressure_value)) -
            1;

  const Real slope =
      (values[lower + 1] - values[lower]) /
      (_pressure_points[lower + 1] - _pressure_points[lower]);
  return values[lower] + slope * (pressure_value_ad - _pressure_points[lower]);
}

Real
ADBlackOilPVTMaterial::tableSlope(const std::vector<Real> & values) const
{
  const Real pressure = MetaPhysicL::raw_value(this->pressure());
  const auto last = _pressure_points.size() - 1;

  if ((pressure < _pressure_points.front() || pressure > _pressure_points.back()) &&
      _out_of_range_policy == "clamp")
    return 0.0;

  unsigned int lower = 0;
  if (pressure >= _pressure_points.back())
    lower = last - 1;
  else if (pressure > _pressure_points.front())
    lower = std::distance(
        _pressure_points.begin(),
        std::upper_bound(_pressure_points.begin(), _pressure_points.end(), pressure)) -
            1;

  return (values[lower + 1] - values[lower]) /
         (_pressure_points[lower + 1] - _pressure_points[lower]);
}

ADReal
ADBlackOilPVTMaterial::pressure() const
{
  return _pressure_property ? (*_pressure_property)[_qp] : (*_pressure)[_qp];
}

ADReal
ADBlackOilPVTMaterial::pressureDot() const
{
  return _pressure_property_dot ? (*_pressure_property_dot)[_qp] : (*_pressure_dot)[_qp];
}

ADReal
ADBlackOilPVTMaterial::waterSaturation() const
{
  return _water_saturation_property ? (*_water_saturation_property)[_qp]
                                    : (*_water_saturation)[_qp];
}

ADReal
ADBlackOilPVTMaterial::gasSaturation() const
{
  return _gas_saturation_property ? (*_gas_saturation_property)[_qp]
                                  : (*_gas_saturation)[_qp];
}

ADReal
ADBlackOilPVTMaterial::waterSaturationDot() const
{
  return _water_saturation_property_dot ? (*_water_saturation_property_dot)[_qp]
                                        : (*_water_saturation_dot)[_qp];
}

ADReal
ADBlackOilPVTMaterial::gasSaturationDot() const
{
  return _gas_saturation_property_dot ? (*_gas_saturation_property_dot)[_qp]
                                      : (*_gas_saturation_dot)[_qp];
}

void
ADBlackOilPVTMaterial::computeQpProperties()
{
  const ADReal water_saturation = waterSaturation();
  const ADReal gas_saturation = gasSaturation();
  _water_fvf[_qp] = interpolate(_water_fvf_values);
  _oil_fvf[_qp] = interpolate(_oil_fvf_values);
  _gas_fvf[_qp] = interpolate(_gas_fvf_values);
  _solution_gas_oil_ratio[_qp] = interpolate(_solution_gas_oil_ratio_values);
  if (_water_viscosity_values.empty())
  {
    _water_viscosity[_qp] = 1.0;
    _oil_viscosity[_qp] = 1.0;
    _gas_viscosity[_qp] = 1.0;
  }
  else
  {
    _water_viscosity[_qp] = interpolate(_water_viscosity_values);
    _oil_viscosity[_qp] = interpolate(_oil_viscosity_values);
    _gas_viscosity[_qp] = interpolate(_gas_viscosity_values);
  }

  if (MetaPhysicL::raw_value(_water_fvf[_qp]) <= 0.0 ||
      MetaPhysicL::raw_value(_oil_fvf[_qp]) <= 0.0 ||
      MetaPhysicL::raw_value(_gas_fvf[_qp]) <= 0.0)
    mooseError(name(), ": interpolated formation-volume factors must be positive.");
  if (MetaPhysicL::raw_value(_solution_gas_oil_ratio[_qp]) < 0.0)
    mooseError(name(), ": interpolated solution gas-oil ratio must be nonnegative.");

  _oil_saturation[_qp] = 1.0 - water_saturation - gas_saturation;
  _water_intrinsic_density[_qp] = _water_surface_density / _water_fvf[_qp];
  _oil_intrinsic_density[_qp] =
      (_oil_surface_density + _gas_surface_density * _solution_gas_oil_ratio[_qp]) /
      _oil_fvf[_qp];
  _gas_intrinsic_density[_qp] = _gas_surface_density / _gas_fvf[_qp];

  const ADReal oil_phase_surface_mass =
      _oil_surface_density + _gas_surface_density * _solution_gas_oil_ratio[_qp];
  _oil_component_mass_fraction_in_oil[_qp] = _oil_surface_density / oil_phase_surface_mass;
  _gas_component_mass_fraction_in_oil[_qp] =
      _gas_surface_density * _solution_gas_oil_ratio[_qp] / oil_phase_surface_mass;

  _water_current_component_storage[_qp] =
      _water_surface_density * _porosity[_qp] * water_saturation / _water_fvf[_qp];
  _oil_current_component_storage[_qp] =
      _oil_surface_density * _porosity[_qp] * _oil_saturation[_qp] / _oil_fvf[_qp];
  _gas_current_component_storage[_qp] =
      _gas_surface_density * _porosity[_qp] *
      (gas_saturation / _gas_fvf[_qp] +
       _solution_gas_oil_ratio[_qp] * _oil_saturation[_qp] / _oil_fvf[_qp]);

  _water_reference_component_storage[_qp] =
      _J[_qp] * _water_current_component_storage[_qp];
  _oil_reference_component_storage[_qp] = _J[_qp] * _oil_current_component_storage[_qp];
  _gas_reference_component_storage[_qp] = _J[_qp] * _gas_current_component_storage[_qp];

  if (!_pressure_dot && !_pressure_property_dot)
  {
    _water_reference_component_storage_rate[_qp] = 0.0;
    _oil_reference_component_storage_rate[_qp] = 0.0;
    _gas_reference_component_storage_rate[_qp] = 0.0;
    return;
  }

  const ADReal total_pressure_dot = pressureDot();
  const ADReal water_fvf_dot = tableSlope(_water_fvf_values) * total_pressure_dot;
  const ADReal oil_fvf_dot = tableSlope(_oil_fvf_values) * total_pressure_dot;
  const ADReal gas_fvf_dot = tableSlope(_gas_fvf_values) * total_pressure_dot;
  const ADReal solution_gas_oil_ratio_dot =
      tableSlope(_solution_gas_oil_ratio_values) * total_pressure_dot;
  const ADReal water_saturation_dot = waterSaturationDot();
  const ADReal gas_saturation_dot = gasSaturationDot();
  const ADReal oil_saturation_dot = -water_saturation_dot - gas_saturation_dot;

  _water_reference_component_storage_rate[_qp] =
      _water_surface_density *
      ((*_J_dot)[_qp] * _porosity[_qp] * water_saturation / _water_fvf[_qp] +
       _J[_qp] * (*_porosity_dot)[_qp] * water_saturation / _water_fvf[_qp] +
       _J[_qp] * _porosity[_qp] * water_saturation_dot / _water_fvf[_qp] -
       _J[_qp] * _porosity[_qp] * water_saturation * water_fvf_dot /
           (_water_fvf[_qp] * _water_fvf[_qp]));

  _oil_reference_component_storage_rate[_qp] =
      _oil_surface_density *
      ((*_J_dot)[_qp] * _porosity[_qp] * _oil_saturation[_qp] / _oil_fvf[_qp] +
       _J[_qp] * (*_porosity_dot)[_qp] * _oil_saturation[_qp] / _oil_fvf[_qp] +
       _J[_qp] * _porosity[_qp] * oil_saturation_dot / _oil_fvf[_qp] -
       _J[_qp] * _porosity[_qp] * _oil_saturation[_qp] * oil_fvf_dot /
           (_oil_fvf[_qp] * _oil_fvf[_qp]));

  const ADReal gas_current_storage_factor =
      gas_saturation / _gas_fvf[_qp] +
      _solution_gas_oil_ratio[_qp] * _oil_saturation[_qp] / _oil_fvf[_qp];
  const ADReal gas_current_storage_factor_dot =
      gas_saturation_dot / _gas_fvf[_qp] -
      gas_saturation * gas_fvf_dot / (_gas_fvf[_qp] * _gas_fvf[_qp]) +
      solution_gas_oil_ratio_dot * _oil_saturation[_qp] / _oil_fvf[_qp] +
      _solution_gas_oil_ratio[_qp] * oil_saturation_dot / _oil_fvf[_qp] -
      _solution_gas_oil_ratio[_qp] * _oil_saturation[_qp] * oil_fvf_dot /
          (_oil_fvf[_qp] * _oil_fvf[_qp]);
  _gas_reference_component_storage_rate[_qp] =
      _gas_surface_density *
      ((*_J_dot)[_qp] * _porosity[_qp] * gas_current_storage_factor +
       _J[_qp] * (*_porosity_dot)[_qp] * gas_current_storage_factor +
       _J[_qp] * _porosity[_qp] * gas_current_storage_factor_dot);
}
