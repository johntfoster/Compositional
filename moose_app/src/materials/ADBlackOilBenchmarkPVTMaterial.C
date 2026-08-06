#include "ADBlackOilBenchmarkPVTMaterial.h"

#include "metaphysicl/raw_type.h"

#include <algorithm>
#include <cmath>
#include <limits>

registerMooseObject("MulticomponentReactiveFlowApp", ADBlackOilBenchmarkPVTMaterial);

InputParameters
ADBlackOilBenchmarkPVTMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Evaluates ECLIPSE-style PVTW, PVDG, and ragged PVTO data, black-oil component "
      "storage, and gas-appearance complementarity for SPE benchmarks.");
  params.addParam<MaterialPropertyName>(
      "jacobian_name", "solid_reference_J", "Material property name for the solid-reference J.");
  params.addParam<MaterialPropertyName>("jacobian_rate_name",
                                        "solid_reference_J_dot",
                                        "Material property name for the material time rate of J.");
  params.addParam<bool>(
      "compute_storage_rates",
      false,
      "Compute exact chain-rule rates of the three reference component storages.");
  params.addCoupledVar("oil_pressure", "Oil-phase pressure backbone or total field.");
  params.addParam<MaterialPropertyName>(
      "oil_pressure_name",
      "",
      "Optional AD material property containing reconstructed total oil pressure. Supply exactly "
      "one of oil_pressure or oil_pressure_name.");
  params.addParam<MaterialPropertyName>(
      "oil_pressure_rate_name",
      "",
      "AD material property containing the reconstructed total-pressure time derivative when "
      "oil_pressure_name is used with compute_storage_rates=true.");
  params.addRequiredCoupledVar(
      "solution_gas_oil_ratio", "Dissolved stock-tank gas to stock-tank oil ratio R_s.");
  params.addCoupledVar("porosity", "Current pore-volume fraction.");
  params.addParam<MaterialPropertyName>(
      "porosity_name",
      "",
      "Optional AD material property containing current porosity. Supply exactly one of "
      "porosity or porosity_name.");
  params.addParam<MaterialPropertyName>(
      "porosity_rate_name",
      "",
      "AD material property containing the current porosity material time rate when "
      "porosity_name is used with compute_storage_rates=true.");
  params.addParam<bool>("use_pressure_dependent_rock_porosity",
                        false,
                        "Apply an exponential ROCK pore-volume multiplier to the coupled "
                        "reference porosity.");
  params.addParam<Real>(
      "rock_reference_pressure", 0.0, "ROCK reference pressure for pore-volume compression.");
  params.addRangeCheckedParam<Real>("rock_compressibility",
                                    0.0,
                                    "rock_compressibility >= 0",
                                    "Constant ROCK pore-volume compressibility.");
  params.addCoupledVar("water_saturation", "Water-saturation backbone or total field.");
  params.addParam<MaterialPropertyName>(
      "water_saturation_name",
      "",
      "Optional AD material property containing reconstructed total water saturation. Supply "
      "exactly one of water_saturation or water_saturation_name.");
  params.addParam<MaterialPropertyName>(
      "water_saturation_rate_name",
      "",
      "AD material property containing the reconstructed total water-saturation time derivative "
      "when water_saturation_name is used with compute_storage_rates=true.");
  params.addCoupledVar("gas_saturation", "Gas-saturation backbone or total field.");
  params.addParam<MaterialPropertyName>(
      "gas_saturation_name",
      "",
      "Optional AD material property containing reconstructed total gas saturation. Supply "
      "exactly one of gas_saturation or gas_saturation_name.");
  params.addParam<MaterialPropertyName>(
      "gas_saturation_rate_name",
      "",
      "AD material property containing the reconstructed total gas-saturation time derivative "
      "when gas_saturation_name is used with compute_storage_rates=true.");

  params.addRequiredParam<Real>("water_reference_pressure", "PVTW reference pressure.");
  params.addRequiredRangeCheckedParam<Real>(
      "water_reference_fvf", "water_reference_fvf>0", "PVTW reference B_w.");
  params.addRequiredRangeCheckedParam<Real>(
      "water_compressibility", "water_compressibility>=0", "PVTW compressibility.");
  params.addRequiredRangeCheckedParam<Real>(
      "water_reference_viscosity", "water_reference_viscosity>0", "PVTW reference viscosity.");
  params.addRequiredParam<Real>("water_viscosibility", "PVTW viscosibility.");

  params.addRequiredParam<std::vector<Real>>("gas_pressure_points", "PVDG pressure coordinates.");
  params.addRequiredParam<std::vector<Real>>("gas_fvf_values", "PVDG B_g values.");
  params.addRequiredParam<std::vector<Real>>("gas_viscosity_values", "PVDG viscosity values.");

  params.addRequiredParam<std::vector<Real>>(
      "oil_solution_gas_oil_ratio_points", "PVTO branch R_s coordinates.");
  params.addRequiredParam<std::vector<Real>>(
      "oil_bubble_pressure_points", "PVTO saturated bubble-pressure coordinates.");
  params.addRequiredParam<std::vector<unsigned int>>(
      "oil_branch_offsets", "Offsets delimiting each PVTO pressure branch in the flattened arrays.");
  params.addRequiredParam<std::vector<Real>>(
      "oil_pressure_points", "Flattened PVTO branch pressure coordinates.");
  params.addRequiredParam<std::vector<Real>>("oil_fvf_values", "Flattened PVTO B_o values.");
  params.addRequiredParam<std::vector<Real>>(
      "oil_viscosity_values", "Flattened PVTO viscosity values.");
  params.addRequiredParam<std::vector<Real>>(
      "saturated_oil_fvf_values", "PVTO saturated B_o value for each R_s branch.");
  params.addRequiredParam<std::vector<Real>>(
      "saturated_oil_viscosity_values", "PVTO saturated viscosity for each R_s branch.");
  params.addParam<MooseEnum>("out_of_range_policy",
                             MooseEnum("error clamp linear", "error"),
                             "Policy for coordinates outside supplied PVT intervals.");
  params.addRangeCheckedParam<Real>(
      "gas_active_tol", 1e-12, "gas_active_tol>=0", "Gas-saturation activity tolerance.");
  params.addParam<bool>(
      "equilibrate_solution_gas_with_free_gas",
      true,
      "Use saturated PVTO properties when free gas is active. Set false for benchmark controls "
      "such as SPE1 Case 1 DRSDT=0 that retain undersaturated dissolved gas with free gas present.");
  params.addRangeCheckedParam<Real>(
      "solution_gas_oil_ratio_scale",
      1.0,
      "solution_gas_oil_ratio_scale > 0",
      "Positive R_s scale used to nondimensionalize the gas-appearance complementarity gap.");
  params.addRangeCheckedParam<Real>(
      "maximum_solution_gas_oil_ratio",
      std::numeric_limits<Real>::max(),
      "maximum_solution_gas_oil_ratio >= 0",
      "Maximum attainable dissolved R_s. SPE1 Case 1 uses its initial R_s because DRSDT=0 "
      "prevents injected free gas from increasing solution gas.");
  params.addRangeCheckedParam<Real>(
      "solution_gas_transition_width",
      0.0,
      "solution_gas_transition_width >= 0",
      "R_s width for a compact C1 regularization of the minimum between the old-time R_s cap "
      "and the saturated R_s curve. Zero retains the exact piecewise minimum.");
  params.addParam<bool>(
      "enforce_nonincreasing_solution_gas",
      false,
      "Limit R_s by its old time-step value. This represents DRSDT=0: exsolution may reduce "
      "R_s, while subsequent pressure recovery cannot redissolve free gas.");
  params.addParam<bool>(
      "reject_oversaturated_state",
      true,
      "Reject R_s above saturated R_s immediately. Disable while the complementarity equation "
      "is itself a nonlinear residual so trial iterates may cross the bound.");
  params.addRequiredRangeCheckedParam<Real>(
      "water_surface_density", "water_surface_density>0", "Stock-tank water density.");
  params.addRequiredRangeCheckedParam<Real>(
      "oil_surface_density", "oil_surface_density>0", "Stock-tank oil density.");
  params.addRequiredRangeCheckedParam<Real>(
      "gas_surface_density", "gas_surface_density>0", "Stock-tank gas density.");
  params.addParam<std::string>(
      "property_prefix", "benchmark_black_oil", "Prefix for declared material properties.");
  return params;
}

ADBlackOilBenchmarkPVTMaterial::ADBlackOilBenchmarkPVTMaterial(
    const InputParameters & parameters)
  : Material(parameters),
    _J(getADMaterialProperty<Real>("jacobian_name")),
    _J_dot(getParam<bool>("compute_storage_rates")
               ? &getADMaterialProperty<Real>("jacobian_rate_name")
               : nullptr),
    _oil_pressure(isCoupled("oil_pressure") ? &adCoupledValue("oil_pressure") : nullptr),
    _oil_pressure_property(getParam<MaterialPropertyName>("oil_pressure_name").empty()
                               ? nullptr
                               : &getADMaterialProperty<Real>("oil_pressure_name")),
    _oil_pressure_dot(getParam<bool>("compute_storage_rates") && isCoupled("oil_pressure")
                          ? &adCoupledDot("oil_pressure")
                          : nullptr),
    _oil_pressure_property_dot(
        getParam<bool>("compute_storage_rates") &&
                !getParam<MaterialPropertyName>("oil_pressure_rate_name").empty()
            ? &getADMaterialProperty<Real>("oil_pressure_rate_name")
            : nullptr),
    _solution_gas_oil_ratio_state(adCoupledValue("solution_gas_oil_ratio")),
    _solution_gas_oil_ratio_state_dot(getParam<bool>("compute_storage_rates")
                                          ? &adCoupledDot("solution_gas_oil_ratio")
                                          : nullptr),
    _solution_gas_oil_ratio_functor(getFunctor<ADReal>("solution_gas_oil_ratio")),
    _porosity(isCoupled("porosity") ? &adCoupledValue("porosity") : nullptr),
    _porosity_property(getParam<MaterialPropertyName>("porosity_name").empty()
                           ? nullptr
                           : &getADMaterialProperty<Real>("porosity_name")),
    _porosity_dot(getParam<bool>("compute_storage_rates") && isCoupled("porosity")
                      ? &adCoupledDot("porosity")
                      : nullptr),
    _porosity_property_dot(
        getParam<bool>("compute_storage_rates") &&
                !getParam<MaterialPropertyName>("porosity_rate_name").empty()
            ? &getADMaterialProperty<Real>("porosity_rate_name")
            : nullptr),
    _water_saturation(isCoupled("water_saturation") ? &adCoupledValue("water_saturation")
                                                     : nullptr),
    _water_saturation_property(getParam<MaterialPropertyName>("water_saturation_name").empty()
                                   ? nullptr
                                   : &getADMaterialProperty<Real>("water_saturation_name")),
    _water_saturation_dot(getParam<bool>("compute_storage_rates") &&
                                  isCoupled("water_saturation")
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
    _gas_saturation_dot(getParam<bool>("compute_storage_rates") && isCoupled("gas_saturation")
                            ? &adCoupledDot("gas_saturation")
                            : nullptr),
    _gas_saturation_property_dot(
        getParam<bool>("compute_storage_rates") &&
                !getParam<MaterialPropertyName>("gas_saturation_rate_name").empty()
            ? &getADMaterialProperty<Real>("gas_saturation_rate_name")
            : nullptr),
    _compute_storage_rates(getParam<bool>("compute_storage_rates")),
    _use_pressure_dependent_rock_porosity(
        getParam<bool>("use_pressure_dependent_rock_porosity")),
    _rock_reference_pressure(getParam<Real>("rock_reference_pressure")),
    _rock_compressibility(getParam<Real>("rock_compressibility")),
    _water_reference_pressure(getParam<Real>("water_reference_pressure")),
    _water_reference_fvf(getParam<Real>("water_reference_fvf")),
    _water_compressibility(getParam<Real>("water_compressibility")),
    _water_reference_viscosity(getParam<Real>("water_reference_viscosity")),
    _water_viscosibility(getParam<Real>("water_viscosibility")),
    _gas_pressure_points(getParam<std::vector<Real>>("gas_pressure_points")),
    _gas_fvf_values(getParam<std::vector<Real>>("gas_fvf_values")),
    _gas_viscosity_values(getParam<std::vector<Real>>("gas_viscosity_values")),
    _oil_rs_points(getParam<std::vector<Real>>("oil_solution_gas_oil_ratio_points")),
    _oil_bubble_pressure_points(getParam<std::vector<Real>>("oil_bubble_pressure_points")),
    _oil_branch_offsets(getParam<std::vector<unsigned int>>("oil_branch_offsets")),
    _oil_pressure_points(getParam<std::vector<Real>>("oil_pressure_points")),
    _oil_fvf_values(getParam<std::vector<Real>>("oil_fvf_values")),
    _oil_viscosity_values(getParam<std::vector<Real>>("oil_viscosity_values")),
    _saturated_oil_fvf_values(getParam<std::vector<Real>>("saturated_oil_fvf_values")),
    _saturated_oil_viscosity_values(
        getParam<std::vector<Real>>("saturated_oil_viscosity_values")),
    _out_of_range_policy(getParam<MooseEnum>("out_of_range_policy")),
    _gas_active_tol(getParam<Real>("gas_active_tol")),
    _equilibrate_solution_gas_with_free_gas(
        getParam<bool>("equilibrate_solution_gas_with_free_gas")),
    _solution_gas_oil_ratio_scale(getParam<Real>("solution_gas_oil_ratio_scale")),
    _maximum_solution_gas_oil_ratio(getParam<Real>("maximum_solution_gas_oil_ratio")),
    _solution_gas_transition_width(getParam<Real>("solution_gas_transition_width")),
    _enforce_nonincreasing_solution_gas(
        getParam<bool>("enforce_nonincreasing_solution_gas")),
    _reject_oversaturated_state(getParam<bool>("reject_oversaturated_state")),
    _water_surface_density(getParam<Real>("water_surface_density")),
    _oil_surface_density(getParam<Real>("oil_surface_density")),
    _gas_surface_density(getParam<Real>("gas_surface_density")),
    _property_prefix(getParam<std::string>("property_prefix")),
    _water_fvf(declareADProperty<Real>(prefixedName("water_formation_volume_factor"))),
    _oil_fvf(declareADProperty<Real>(prefixedName("oil_formation_volume_factor"))),
    _gas_fvf(declareADProperty<Real>(prefixedName("gas_formation_volume_factor"))),
    _water_viscosity(declareADProperty<Real>(prefixedName("water_viscosity"))),
    _oil_viscosity(declareADProperty<Real>(prefixedName("oil_viscosity"))),
    _gas_viscosity(declareADProperty<Real>(prefixedName("gas_viscosity"))),
    _solution_gas_oil_ratio(declareADProperty<Real>(prefixedName("solution_gas_oil_ratio"))),
    _saturated_solution_gas_oil_ratio(
        declareADProperty<Real>(prefixedName("saturated_solution_gas_oil_ratio"))),
    _undersaturation_gap(declareADProperty<Real>(prefixedName("undersaturation_gap"))),
    _gas_appearance_complementarity_residual(
        declareADProperty<Real>(prefixedName("gas_appearance_complementarity_residual"))),
    _solution_gas_constraint_residual(
        declareADProperty<Real>(prefixedName("solution_gas_constraint_residual"))),
    _oil_saturation(declareADProperty<Real>(prefixedName("oil_saturation"))),
    _water_intrinsic_density(declareADProperty<Real>(prefixedName("water_intrinsic_density"))),
    _oil_intrinsic_density(declareADProperty<Real>(prefixedName("oil_intrinsic_density"))),
    _gas_intrinsic_density(declareADProperty<Real>(prefixedName("gas_intrinsic_density"))),
    _water_component_mass_fraction_in_water(
        declareADProperty<Real>(prefixedName("water_component_mass_fraction_in_water"))),
    _oil_component_mass_fraction_in_oil(
        declareADProperty<Real>(prefixedName("oil_component_mass_fraction_in_oil"))),
    _gas_component_mass_fraction_in_oil(
        declareADProperty<Real>(prefixedName("gas_component_mass_fraction_in_oil"))),
    _gas_component_mass_fraction_in_gas(
        declareADProperty<Real>(prefixedName("gas_component_mass_fraction_in_gas"))),
    _water_reference_component_storage(
        declareADProperty<Real>(prefixedName("water_reference_component_storage"))),
    _oil_reference_component_storage(
        declareADProperty<Real>(prefixedName("oil_reference_component_storage"))),
    _gas_reference_component_storage(
        declareADProperty<Real>(prefixedName("gas_reference_component_storage"))),
    _dissolved_gas_reference_component_storage(
        declareADProperty<Real>(prefixedName("dissolved_gas_reference_component_storage"))),
    _free_gas_reference_component_storage(
        declareADProperty<Real>(prefixedName("free_gas_reference_component_storage"))),
    _water_reference_phase_mass_coefficient(
        declareADProperty<Real>(prefixedName("water_reference_phase_mass_coefficient"))),
    _free_gas_reference_phase_mass_coefficient(
        declareADProperty<Real>(prefixedName("free_gas_reference_phase_mass_coefficient"))),
    _water_reference_phase_mass_coefficient_rate(declareADProperty<Real>(
        prefixedName("water_reference_phase_mass_coefficient_rate"))),
    _free_gas_reference_phase_mass_coefficient_rate(declareADProperty<Real>(
        prefixedName("free_gas_reference_phase_mass_coefficient_rate"))),
    _water_reference_component_storage_rate(
        declareADProperty<Real>(prefixedName("water_reference_component_storage_rate"))),
    _oil_reference_component_storage_rate(
        declareADProperty<Real>(prefixedName("oil_reference_component_storage_rate"))),
    _gas_reference_component_storage_rate(
        declareADProperty<Real>(prefixedName("gas_reference_component_storage_rate"))),
    _dissolved_gas_reference_component_storage_rate(
        declareADProperty<Real>(prefixedName("dissolved_gas_reference_component_storage_rate"))),
    _free_gas_reference_component_storage_rate(
        declareADProperty<Real>(prefixedName("free_gas_reference_component_storage_rate"))),
    _water_bulk_phase_density(
        declareADProperty<Real>(prefixedName("water_bulk_phase_density"))),
    _oil_bulk_phase_density(
        declareADProperty<Real>(prefixedName("oil_bulk_phase_density"))),
    _gas_bulk_phase_density(
        declareADProperty<Real>(prefixedName("gas_bulk_phase_density"))),
    _oil_phase_availability(
        declareADProperty<Real>(prefixedName("oil_phase_availability"))),
    _gas_phase_availability(
        declareADProperty<Real>(prefixedName("gas_phase_availability"))),
    _oil_active(declareADProperty<Real>(prefixedName("oil_active"))),
    _gas_active(declareADProperty<Real>(prefixedName("gas_active")))
{
  if (static_cast<bool>(_oil_pressure) == static_cast<bool>(_oil_pressure_property))
    paramError("oil_pressure_name", "Supply exactly one of oil_pressure or oil_pressure_name.");
  if (_oil_pressure_property && _compute_storage_rates && !_oil_pressure_property_dot)
    paramError("oil_pressure_rate_name",
               "Supply oil_pressure_rate_name when reconstructed total pressure is used with "
               "compute_storage_rates=true.");
  if (_oil_pressure && !getParam<MaterialPropertyName>("oil_pressure_rate_name").empty())
    paramError("oil_pressure_rate_name",
               "oil_pressure_rate_name is only valid when oil_pressure_name supplies pressure.");
  if (static_cast<bool>(_porosity) == static_cast<bool>(_porosity_property))
    paramError("porosity_name", "Supply exactly one of porosity or porosity_name.");
  if (_porosity_property && _compute_storage_rates && !_porosity_property_dot)
    paramError("porosity_rate_name",
               "Supply porosity_rate_name when material-property porosity is used with "
               "compute_storage_rates=true.");
  if (_porosity && !getParam<MaterialPropertyName>("porosity_rate_name").empty())
    paramError("porosity_rate_name",
               "porosity_rate_name is only valid when porosity_name supplies porosity.");
  if (static_cast<bool>(_water_saturation) ==
      static_cast<bool>(_water_saturation_property))
    paramError("water_saturation_name",
               "Supply exactly one of water_saturation or water_saturation_name.");
  if (_water_saturation_property && _compute_storage_rates &&
      !_water_saturation_property_dot)
    paramError("water_saturation_rate_name",
               "Supply water_saturation_rate_name when reconstructed total water saturation is "
               "used with compute_storage_rates=true.");
  if (_water_saturation &&
      !getParam<MaterialPropertyName>("water_saturation_rate_name").empty())
    paramError("water_saturation_rate_name",
               "water_saturation_rate_name is only valid when water_saturation_name supplies "
               "water saturation.");
  if (static_cast<bool>(_gas_saturation) == static_cast<bool>(_gas_saturation_property))
    paramError("gas_saturation_name",
               "Supply exactly one of gas_saturation or gas_saturation_name.");
  if (_gas_saturation_property && _compute_storage_rates && !_gas_saturation_property_dot)
    paramError("gas_saturation_rate_name",
               "Supply gas_saturation_rate_name when reconstructed total gas saturation is used "
               "with compute_storage_rates=true.");
  if (_gas_saturation && !getParam<MaterialPropertyName>("gas_saturation_rate_name").empty())
    paramError("gas_saturation_rate_name",
               "gas_saturation_rate_name is only valid when gas_saturation_name supplies gas "
               "saturation.");
  if (_property_prefix.empty())
    paramError("property_prefix", "The material-property prefix must be nonempty.");

  const auto validate_table = [this](const std::vector<Real> & coordinates,
                                     const std::vector<Real> & values,
                                     const std::string & coordinate_parameter,
                                     const std::string & value_parameter) {
    if (coordinates.size() < 2 || coordinates.size() != values.size())
      paramError(value_parameter, "Supply at least two values, one per table coordinate.");
    for (const auto i : make_range(coordinates.size() - 1))
      if (coordinates[i + 1] <= coordinates[i])
        paramError(coordinate_parameter, "Table coordinates must be strictly increasing.");
  };
  validate_table(
      _gas_pressure_points, _gas_fvf_values, "gas_pressure_points", "gas_fvf_values");
  validate_table(_gas_pressure_points,
                 _gas_viscosity_values,
                 "gas_pressure_points",
                 "gas_viscosity_values");
  validate_table(_oil_bubble_pressure_points,
                 _oil_rs_points,
                 "oil_bubble_pressure_points",
                 "oil_solution_gas_oil_ratio_points");

  const auto branch_count = _oil_rs_points.size();
  if (_oil_branch_offsets.size() != branch_count + 1 || _oil_branch_offsets.front() != 0 ||
      _oil_branch_offsets.back() != _oil_pressure_points.size())
    paramError("oil_branch_offsets",
               "Supply branch_count+1 offsets beginning at zero and ending at the flattened "
               "PVTO table length.");
  if (_oil_fvf_values.size() != _oil_pressure_points.size() ||
      _oil_viscosity_values.size() != _oil_pressure_points.size())
    paramError("oil_fvf_values", "Flattened PVTO pressure, B_o, and viscosity sizes must match.");
  if (_saturated_oil_fvf_values.size() != branch_count ||
      _saturated_oil_viscosity_values.size() != branch_count)
    paramError("saturated_oil_fvf_values", "Supply one saturated value for each PVTO branch.");
  for (const auto branch : make_range(branch_count))
  {
    if (_oil_branch_offsets[branch + 1] <= _oil_branch_offsets[branch])
      paramError("oil_branch_offsets", "Every PVTO branch must contain at least one row.");
    for (unsigned int i = _oil_branch_offsets[branch];
         i + 1 < _oil_branch_offsets[branch + 1];
         ++i)
      if (_oil_pressure_points[i + 1] <= _oil_pressure_points[i])
        paramError("oil_pressure_points", "Pressure must increase within every PVTO branch.");
  }
  for (const auto value : _gas_fvf_values)
    if (value <= 0.0)
      paramError("gas_fvf_values", "All gas formation-volume factors must be positive.");
  for (const auto value : _gas_viscosity_values)
    if (value <= 0.0)
      paramError("gas_viscosity_values", "All gas viscosities must be positive.");
  for (const auto value : _oil_fvf_values)
    if (value <= 0.0)
      paramError("oil_fvf_values", "All oil formation-volume factors must be positive.");
  for (const auto value : _oil_viscosity_values)
    if (value <= 0.0)
      paramError("oil_viscosity_values", "All oil viscosities must be positive.");
  for (const auto value : _saturated_oil_fvf_values)
    if (value <= 0.0)
      paramError("saturated_oil_fvf_values",
                 "All saturated oil formation-volume factors must be positive.");
  for (const auto value : _saturated_oil_viscosity_values)
    if (value <= 0.0)
      paramError("saturated_oil_viscosity_values",
                 "All saturated oil viscosities must be positive.");

  const auto initialize_eclipse_interpolation_values = [](const std::vector<Real> & fvf,
                                                           const std::vector<Real> & viscosity,
                                                           std::vector<Real> & inverse_fvf,
                                                           std::vector<Real> & inverse_fvf_viscosity) {
    inverse_fvf.reserve(fvf.size());
    inverse_fvf_viscosity.reserve(fvf.size());
    for (const auto i : index_range(fvf))
    {
      inverse_fvf.push_back(1.0 / fvf[i]);
      inverse_fvf_viscosity.push_back(1.0 / (fvf[i] * viscosity[i]));
    }
  };
  initialize_eclipse_interpolation_values(_gas_fvf_values,
                                           _gas_viscosity_values,
                                           _gas_inverse_fvf_values,
                                           _gas_inverse_fvf_viscosity_values);
  initialize_eclipse_interpolation_values(_saturated_oil_fvf_values,
                                           _saturated_oil_viscosity_values,
                                           _saturated_oil_inverse_fvf_values,
                                           _saturated_oil_inverse_fvf_viscosity_values);

  _interpolation_oil_branch_offsets.push_back(0);
  for (const auto branch : make_range(branch_count))
  {
    const auto begin = _oil_branch_offsets[branch];
    const auto end = _oil_branch_offsets[branch + 1];
    for (unsigned int i = begin; i < end; ++i)
    {
      _interpolation_oil_pressure_points.push_back(_oil_pressure_points[i]);
      _oil_inverse_fvf_values.push_back(1.0 / _oil_fvf_values[i]);
      _oil_inverse_fvf_viscosity_values.push_back(
          1.0 / (_oil_fvf_values[i] * _oil_viscosity_values[i]));
    }

    if (end - begin == 1)
    {
      unsigned int master = branch + 1;
      while (master < branch_count &&
             _oil_branch_offsets[master + 1] - _oil_branch_offsets[master] == 1)
        ++master;
      if (master < branch_count)
      {
        const auto master_begin = _oil_branch_offsets[master];
        const auto master_end = _oil_branch_offsets[master + 1];
        Real completed_pressure = _oil_pressure_points[begin];
        Real completed_fvf = _oil_fvf_values[begin];
        Real completed_viscosity = _oil_viscosity_values[begin];
        for (unsigned int i = master_begin + 1; i < master_end; ++i)
        {
          completed_pressure += _oil_pressure_points[i] - _oil_pressure_points[i - 1];
          completed_fvf *= _oil_fvf_values[i] / _oil_fvf_values[i - 1];
          completed_viscosity *= _oil_viscosity_values[i] / _oil_viscosity_values[i - 1];
          _interpolation_oil_pressure_points.push_back(completed_pressure);
          _oil_inverse_fvf_values.push_back(1.0 / completed_fvf);
          _oil_inverse_fvf_viscosity_values.push_back(
              1.0 / (completed_fvf * completed_viscosity));
        }
      }
    }
    _interpolation_oil_branch_offsets.push_back(_interpolation_oil_pressure_points.size());
  }
}

MaterialPropertyName
ADBlackOilBenchmarkPVTMaterial::prefixedName(const std::string & suffix) const
{
  return MaterialPropertyName(_property_prefix + "_" + suffix);
}

ADReal
ADBlackOilBenchmarkPVTMaterial::oilPressure() const
{
  return _oil_pressure ? (*_oil_pressure)[_qp] : (*_oil_pressure_property)[_qp];
}

ADReal
ADBlackOilBenchmarkPVTMaterial::oilPressureDot() const
{
  return _oil_pressure_dot ? (*_oil_pressure_dot)[_qp] : (*_oil_pressure_property_dot)[_qp];
}

ADReal
ADBlackOilBenchmarkPVTMaterial::waterSaturation() const
{
  return _water_saturation ? (*_water_saturation)[_qp]
                           : (*_water_saturation_property)[_qp];
}

ADReal
ADBlackOilBenchmarkPVTMaterial::waterSaturationDot() const
{
  return _water_saturation_dot ? (*_water_saturation_dot)[_qp]
                               : (*_water_saturation_property_dot)[_qp];
}

ADReal
ADBlackOilBenchmarkPVTMaterial::gasSaturation() const
{
  return _gas_saturation ? (*_gas_saturation)[_qp] : (*_gas_saturation_property)[_qp];
}

ADReal
ADBlackOilBenchmarkPVTMaterial::gasSaturationDot() const
{
  return _gas_saturation_dot ? (*_gas_saturation_dot)[_qp]
                             : (*_gas_saturation_property_dot)[_qp];
}

ADReal
ADBlackOilBenchmarkPVTMaterial::interpolate1D(const std::vector<Real> & coordinates,
                                              const std::vector<Real> & values,
                                              const ADReal & coordinate,
                                              const std::string & table_name) const
{
  const Real value = MetaPhysicL::raw_value(coordinate);
  if (value < coordinates.front())
  {
    if (_out_of_range_policy == "error")
      mooseError(name(), ": ", table_name, " coordinate is below its table interval.");
    if (_out_of_range_policy == "clamp")
      return values.front();
  }
  else if (value > coordinates.back())
  {
    if (_out_of_range_policy == "error")
      mooseError(name(), ": ", table_name, " coordinate is above its table interval.");
    if (_out_of_range_policy == "clamp")
      return values.back();
  }

  unsigned int lower = 0;
  if (value >= coordinates.back())
    lower = coordinates.size() - 2;
  else if (value > coordinates.front())
    lower = std::distance(
                coordinates.begin(), std::upper_bound(coordinates.begin(), coordinates.end(), value)) -
            1;
  const Real slope =
      (values[lower + 1] - values[lower]) / (coordinates[lower + 1] - coordinates[lower]);
  return values[lower] + slope * (coordinate - coordinates[lower]);
}

ADReal
ADBlackOilBenchmarkPVTMaterial::interpolateOilBranchAtPressure(
    const unsigned int branch,
    const std::vector<Real> & values,
    const ADReal & pressure) const
{
  const auto begin = _interpolation_oil_branch_offsets[branch];
  const auto end = _interpolation_oil_branch_offsets[branch + 1];
  if (end - begin == 1)
    return values[begin];
  const std::vector<Real> pressure_points(_interpolation_oil_pressure_points.begin() + begin,
                                          _interpolation_oil_pressure_points.begin() + end);
  const std::vector<Real> branch_values(values.begin() + begin, values.begin() + end);
  return interpolate1D(pressure_points, branch_values, pressure, "PVTO pressure");
}

ADReal
ADBlackOilBenchmarkPVTMaterial::interpolateOilBranch(const unsigned int branch,
                                                     const std::vector<Real> & values) const
{
  return interpolateOilBranchAtPressure(branch, values, oilPressure());
}

ADReal
ADBlackOilBenchmarkPVTMaterial::interpolateUndersaturatedOil(
    const std::vector<Real> & values) const
{
  const Real rs = MetaPhysicL::raw_value(_solution_gas_oil_ratio_state[_qp]);
  const auto exact = std::lower_bound(_oil_rs_points.begin(), _oil_rs_points.end(), rs);
  if (exact != _oil_rs_points.end() && std::abs(*exact - rs) <= 1e-12)
    return interpolateOilBranch(std::distance(_oil_rs_points.begin(), exact), values);

  if (rs < _oil_rs_points.front())
  {
    if (_out_of_range_policy == "error")
      mooseError(name(), ": PVTO R_s is below its table interval.");
    return interpolateOilBranch(0, values);
  }
  if (rs > _oil_rs_points.back())
  {
    if (_out_of_range_policy == "error")
      mooseError(name(), ": PVTO R_s is above its table interval.");
    return interpolateOilBranch(_oil_rs_points.size() - 1, values);
  }

  const unsigned int upper =
      std::distance(_oil_rs_points.begin(), std::upper_bound(_oil_rs_points.begin(), _oil_rs_points.end(), rs));
  const unsigned int lower = upper - 1;
  const ADReal weight = (_solution_gas_oil_ratio_state[_qp] - _oil_rs_points[lower]) /
                        (_oil_rs_points[upper] - _oil_rs_points[lower]);
  const Real pressure_shift =
      _oil_bubble_pressure_points[upper] - _oil_bubble_pressure_points[lower];
  const ADReal lower_pressure = oilPressure() - weight * pressure_shift;
  const ADReal upper_pressure = oilPressure() + (1.0 - weight) * pressure_shift;
  const ADReal lower_value = interpolateOilBranchAtPressure(lower, values, lower_pressure);
  const ADReal upper_value = interpolateOilBranchAtPressure(upper, values, upper_pressure);
  return lower_value + weight * (upper_value - lower_value);
}

Real
ADBlackOilBenchmarkPVTMaterial::interpolate1DSlope(const std::vector<Real> & coordinates,
                                                   const std::vector<Real> & values,
                                                   const ADReal & coordinate,
                                                   const std::string & table_name) const
{
  const Real value = MetaPhysicL::raw_value(coordinate);
  if ((value < coordinates.front() || value > coordinates.back()) && _out_of_range_policy == "clamp")
    return 0.0;
  if (value < coordinates.front() && _out_of_range_policy == "error")
    mooseError(name(), ": ", table_name, " coordinate is below its table interval.");
  if (value > coordinates.back() && _out_of_range_policy == "error")
    mooseError(name(), ": ", table_name, " coordinate is above its table interval.");

  unsigned int lower = 0;
  if (value >= coordinates.back())
    lower = coordinates.size() - 2;
  else if (value > coordinates.front())
    lower = std::distance(
                coordinates.begin(), std::upper_bound(coordinates.begin(), coordinates.end(), value)) -
            1;
  return (values[lower + 1] - values[lower]) / (coordinates[lower + 1] - coordinates[lower]);
}

Real
ADBlackOilBenchmarkPVTMaterial::oilBranchPressureSlopeAtPressure(
    const unsigned int branch,
    const std::vector<Real> & values,
    const ADReal & pressure) const
{
  const auto begin = _interpolation_oil_branch_offsets[branch];
  const auto end = _interpolation_oil_branch_offsets[branch + 1];
  if (end - begin == 1)
    return 0.0;
  const std::vector<Real> pressure_points(_interpolation_oil_pressure_points.begin() + begin,
                                          _interpolation_oil_pressure_points.begin() + end);
  const std::vector<Real> branch_values(values.begin() + begin, values.begin() + end);
  return interpolate1DSlope(pressure_points, branch_values, pressure, "PVTO pressure");
}

Real
ADBlackOilBenchmarkPVTMaterial::oilBranchPressureSlope(const unsigned int branch,
                                                       const std::vector<Real> & values) const
{
  return oilBranchPressureSlopeAtPressure(branch, values, oilPressure());
}

std::pair<ADReal, ADReal>
ADBlackOilBenchmarkPVTMaterial::undersaturatedOilDerivatives(
    const std::vector<Real> & values) const
{
  const Real rs = MetaPhysicL::raw_value(_solution_gas_oil_ratio_state[_qp]);
  const auto exact = std::lower_bound(_oil_rs_points.begin(), _oil_rs_points.end(), rs);
  if (exact != _oil_rs_points.end() && std::abs(*exact - rs) <= 1e-12)
  {
    const auto branch = std::distance(_oil_rs_points.begin(), exact);
    return {oilBranchPressureSlope(branch, values), 0.0};
  }

  if (rs < _oil_rs_points.front())
    return {oilBranchPressureSlope(0, values), 0.0};
  if (rs > _oil_rs_points.back())
    return {oilBranchPressureSlope(_oil_rs_points.size() - 1, values), 0.0};

  const unsigned int upper = std::distance(
      _oil_rs_points.begin(), std::upper_bound(_oil_rs_points.begin(), _oil_rs_points.end(), rs));
  const unsigned int lower = upper - 1;
  const Real rs_interval = _oil_rs_points[upper] - _oil_rs_points[lower];
  const ADReal weight = (_solution_gas_oil_ratio_state[_qp] - _oil_rs_points[lower]) /
                        rs_interval;
  const Real pressure_shift =
      _oil_bubble_pressure_points[upper] - _oil_bubble_pressure_points[lower];
  const ADReal lower_pressure = oilPressure() - weight * pressure_shift;
  const ADReal upper_pressure = oilPressure() + (1.0 - weight) * pressure_shift;
  const ADReal lower_value = interpolateOilBranchAtPressure(lower, values, lower_pressure);
  const ADReal upper_value = interpolateOilBranchAtPressure(upper, values, upper_pressure);
  const Real lower_slope =
      oilBranchPressureSlopeAtPressure(lower, values, lower_pressure);
  const Real upper_slope =
      oilBranchPressureSlopeAtPressure(upper, values, upper_pressure);
  const ADReal pressure_derivative = lower_slope + weight * (upper_slope - lower_slope);
  const ADReal rs_derivative =
      (upper_value - lower_value -
       pressure_shift * (lower_slope + weight * (upper_slope - lower_slope))) /
      rs_interval;
  return {pressure_derivative, rs_derivative};
}

void
ADBlackOilBenchmarkPVTMaterial::computeQpProperties()
{
  _solution_gas_oil_ratio[_qp] = _solution_gas_oil_ratio_state[_qp];
  const ADReal gas_saturation = gasSaturation();
  ADReal bounded_oil_pressure = oilPressure();
  if (_out_of_range_policy == "clamp")
  {
    if (MetaPhysicL::raw_value(bounded_oil_pressure) < _gas_pressure_points.front())
      bounded_oil_pressure = _gas_pressure_points.front();
    else if (MetaPhysicL::raw_value(bounded_oil_pressure) > _gas_pressure_points.back())
      bounded_oil_pressure = _gas_pressure_points.back();
  }
  const ADReal pressure_delta = bounded_oil_pressure - _water_reference_pressure;
  const ADReal base_porosity =
      _porosity ? (*_porosity)[_qp] : (*_porosity_property)[_qp];
  const ADReal porosity =
      _use_pressure_dependent_rock_porosity
          ? base_porosity *
                exp(_rock_compressibility *
                    (bounded_oil_pressure - _rock_reference_pressure))
          : base_porosity;
  const ADReal water_x = _water_compressibility * pressure_delta;
  const ADReal inverse_water_fvf =
      (1.0 + water_x * (1.0 + water_x / 2.0)) / _water_reference_fvf;
  _water_fvf[_qp] = 1.0 / inverse_water_fvf;
  const ADReal water_y = (_water_compressibility - _water_viscosibility) * pressure_delta;
  _water_viscosity[_qp] = _water_reference_viscosity * _water_reference_fvf *
                          inverse_water_fvf / (1.0 + water_y * (1.0 + water_y / 2.0));

  const ADReal inverse_gas_fvf = interpolate1D(
      _gas_pressure_points, _gas_inverse_fvf_values, oilPressure(), "PVDG pressure");
  const ADReal inverse_gas_fvf_viscosity =
      interpolate1D(_gas_pressure_points,
                    _gas_inverse_fvf_viscosity_values,
                    oilPressure(),
                    "PVDG pressure");
  _gas_fvf[_qp] = 1.0 / inverse_gas_fvf;
  _gas_viscosity[_qp] = inverse_gas_fvf / inverse_gas_fvf_viscosity;
  _saturated_solution_gas_oil_ratio[_qp] = interpolate1D(_oil_bubble_pressure_points,
                                                          _oil_rs_points,
                                                          oilPressure(),
                                                          "PVTO bubble pressure");
  const Real history_limited_solution_gas_oil_ratio =
      _enforce_nonincreasing_solution_gas
          ? std::min(MetaPhysicL::raw_value(_solution_gas_oil_ratio_functor(
                         makeElemArg(_current_elem),
                         Moose::StateArg(1, Moose::SolutionIterationType::Time))),
                     _maximum_solution_gas_oil_ratio)
          : _maximum_solution_gas_oil_ratio;
  const bool saturation_curve_below_cap =
      MetaPhysicL::raw_value(_saturated_solution_gas_oil_ratio[_qp]) <=
      history_limited_solution_gas_oil_ratio;
  ADReal attainable_solution_gas_oil_ratio;
  const ADReal saturation_minus_cap =
      _saturated_solution_gas_oil_ratio[_qp] - history_limited_solution_gas_oil_ratio;
  if (_solution_gas_transition_width > 0.0 &&
      std::abs(MetaPhysicL::raw_value(saturation_minus_cap)) <
          _solution_gas_transition_width)
  {
    const ADReal compact_absolute_value =
        (saturation_minus_cap * saturation_minus_cap +
         _solution_gas_transition_width * _solution_gas_transition_width) /
        (2.0 * _solution_gas_transition_width);
    attainable_solution_gas_oil_ratio =
        0.5 * (_saturated_solution_gas_oil_ratio[_qp] +
               history_limited_solution_gas_oil_ratio -
               compact_absolute_value);
  }
  else
    attainable_solution_gas_oil_ratio = saturation_curve_below_cap
                                              ? _saturated_solution_gas_oil_ratio[_qp]
                                              : history_limited_solution_gas_oil_ratio;
  _undersaturation_gap[_qp] =
      attainable_solution_gas_oil_ratio - _solution_gas_oil_ratio_state[_qp];
  if (_reject_oversaturated_state && MetaPhysicL::raw_value(_undersaturation_gap[_qp]) < -1e-10)
    mooseError(name(), ": dissolved R_s exceeds saturated R_s at the current oil pressure.");
  const ADReal normalized_undersaturation_gap =
      _undersaturation_gap[_qp] / _solution_gas_oil_ratio_scale;
  const Real complementarity_norm =
      std::hypot(MetaPhysicL::raw_value(gas_saturation),
                 MetaPhysicL::raw_value(normalized_undersaturation_gap));
  if (complementarity_norm <= 1e-14)
    // The exact Fischer--Burmeister function is nondifferentiable at the
    // origin.  This member of its generalized Jacobian preserves the exact
    // zero residual while providing a finite semismooth Newton direction.
    _gas_appearance_complementarity_residual[_qp] =
        -gas_saturation - normalized_undersaturation_gap;
  else
    _gas_appearance_complementarity_residual[_qp] =
        sqrt(gas_saturation * gas_saturation +
             normalized_undersaturation_gap * normalized_undersaturation_gap) -
        gas_saturation - normalized_undersaturation_gap;
  _solution_gas_constraint_residual[_qp] =
      (_solution_gas_oil_ratio_state[_qp] - attainable_solution_gas_oil_ratio) /
      _solution_gas_oil_ratio_scale;
  const bool use_saturated_pvto = _equilibrate_solution_gas_with_free_gas &&
                                  saturation_curve_below_cap &&
                                  MetaPhysicL::raw_value(gas_saturation) > _gas_active_tol;
  if (use_saturated_pvto)
  {
    const ADReal inverse_oil_fvf = interpolate1D(_oil_bubble_pressure_points,
                                                  _saturated_oil_inverse_fvf_values,
                                                  oilPressure(),
                                                  "saturated PVTO pressure");
    const ADReal inverse_oil_fvf_viscosity =
        interpolate1D(_oil_bubble_pressure_points,
                      _saturated_oil_inverse_fvf_viscosity_values,
                      oilPressure(),
                      "saturated PVTO pressure");
    _oil_fvf[_qp] = 1.0 / inverse_oil_fvf;
    _oil_viscosity[_qp] = inverse_oil_fvf / inverse_oil_fvf_viscosity;
  }
  else
  {
    const ADReal inverse_oil_fvf = interpolateUndersaturatedOil(_oil_inverse_fvf_values);
    const ADReal inverse_oil_fvf_viscosity =
        interpolateUndersaturatedOil(_oil_inverse_fvf_viscosity_values);
    _oil_fvf[_qp] = 1.0 / inverse_oil_fvf;
    _oil_viscosity[_qp] = inverse_oil_fvf / inverse_oil_fvf_viscosity;
  }

  if (MetaPhysicL::raw_value(_water_fvf[_qp]) <= 0.0 ||
      MetaPhysicL::raw_value(_oil_fvf[_qp]) <= 0.0 ||
      MetaPhysicL::raw_value(_gas_fvf[_qp]) <= 0.0 ||
      MetaPhysicL::raw_value(_water_viscosity[_qp]) <= 0.0 ||
      MetaPhysicL::raw_value(_oil_viscosity[_qp]) <= 0.0 ||
      MetaPhysicL::raw_value(_gas_viscosity[_qp]) <= 0.0)
    mooseError(name(),
               ": formation-volume factors and viscosities must be positive; got B_w=",
               MetaPhysicL::raw_value(_water_fvf[_qp]),
               ", B_o=",
               MetaPhysicL::raw_value(_oil_fvf[_qp]),
               ", B_g=",
               MetaPhysicL::raw_value(_gas_fvf[_qp]),
               ", mu_w=",
               MetaPhysicL::raw_value(_water_viscosity[_qp]),
               ", mu_o=",
               MetaPhysicL::raw_value(_oil_viscosity[_qp]),
               ", and mu_g=",
               MetaPhysicL::raw_value(_gas_viscosity[_qp]),
               ".");

  const ADReal water_saturation = waterSaturation();
  _oil_saturation[_qp] = 1.0 - water_saturation - gas_saturation;
  _water_intrinsic_density[_qp] = _water_surface_density / _water_fvf[_qp];
  _oil_intrinsic_density[_qp] =
      (_oil_surface_density + _gas_surface_density * _solution_gas_oil_ratio_state[_qp]) /
      _oil_fvf[_qp];
  _gas_intrinsic_density[_qp] = _gas_surface_density / _gas_fvf[_qp];
  _water_bulk_phase_density[_qp] = porosity * water_saturation * _water_intrinsic_density[_qp];
  _oil_bulk_phase_density[_qp] = porosity * _oil_saturation[_qp] * _oil_intrinsic_density[_qp];
  _gas_bulk_phase_density[_qp] = porosity * gas_saturation * _gas_intrinsic_density[_qp];
  _oil_phase_availability[_qp] = _oil_saturation[_qp];
  _gas_phase_availability[_qp] = gas_saturation;
  _oil_active[_qp] =
      MetaPhysicL::raw_value(_oil_saturation[_qp]) > _gas_active_tol ? 1.0 : 0.0;
  _gas_active[_qp] =
      MetaPhysicL::raw_value(gas_saturation) > _gas_active_tol ? 1.0 : 0.0;
  const ADReal oil_phase_surface_mass =
      _oil_surface_density + _gas_surface_density * _solution_gas_oil_ratio_state[_qp];
  _water_component_mass_fraction_in_water[_qp] = 1.0;
  _oil_component_mass_fraction_in_oil[_qp] = _oil_surface_density / oil_phase_surface_mass;
  _gas_component_mass_fraction_in_oil[_qp] =
      _gas_surface_density * _solution_gas_oil_ratio_state[_qp] / oil_phase_surface_mass;
  _gas_component_mass_fraction_in_gas[_qp] = 1.0;

  _water_reference_component_storage[_qp] = _J[_qp] * _water_surface_density * porosity *
                                             water_saturation / _water_fvf[_qp];
  _oil_reference_component_storage[_qp] = _J[_qp] * _oil_surface_density * porosity *
                                           _oil_saturation[_qp] / _oil_fvf[_qp];
  _gas_reference_component_storage[_qp] =
      _J[_qp] * _gas_surface_density * porosity *
      (gas_saturation / _gas_fvf[_qp] +
       _solution_gas_oil_ratio_state[_qp] * _oil_saturation[_qp] / _oil_fvf[_qp]);
  _free_gas_reference_component_storage[_qp] =
      _J[_qp] * _gas_surface_density * porosity * gas_saturation / _gas_fvf[_qp];
  _dissolved_gas_reference_component_storage[_qp] =
      _J[_qp] * _gas_surface_density * porosity * _solution_gas_oil_ratio_state[_qp] *
      _oil_saturation[_qp] / _oil_fvf[_qp];
  _water_reference_phase_mass_coefficient[_qp] =
      _J[_qp] * _water_surface_density * porosity / _water_fvf[_qp];
  _free_gas_reference_phase_mass_coefficient[_qp] =
      _J[_qp] * _gas_surface_density * porosity / _gas_fvf[_qp];

  if (!_compute_storage_rates)
  {
    _water_reference_phase_mass_coefficient_rate[_qp] = 0.0;
    _free_gas_reference_phase_mass_coefficient_rate[_qp] = 0.0;
    _water_reference_component_storage_rate[_qp] = 0.0;
    _oil_reference_component_storage_rate[_qp] = 0.0;
    _gas_reference_component_storage_rate[_qp] = 0.0;
    _dissolved_gas_reference_component_storage_rate[_qp] = 0.0;
    _free_gas_reference_component_storage_rate[_qp] = 0.0;
    return;
  }

  const ADReal pressure_dot = oilPressureDot();
  const ADReal base_porosity_dot =
      _porosity_dot ? (*_porosity_dot)[_qp] : (*_porosity_property_dot)[_qp];
  const ADReal porosity_dot =
      _use_pressure_dependent_rock_porosity
          ? exp(_rock_compressibility *
                (bounded_oil_pressure - _rock_reference_pressure)) *
                    base_porosity_dot +
                porosity * _rock_compressibility * pressure_dot
          : base_porosity_dot;
  const ADReal rs_dot = (*_solution_gas_oil_ratio_state_dot)[_qp];
  const ADReal inverse_water_fvf_derivative =
      _water_compressibility * (1.0 + water_x) / _water_reference_fvf;
  const ADReal water_fvf_dot =
      -inverse_water_fvf_derivative * pressure_dot / (inverse_water_fvf * inverse_water_fvf);
  const ADReal inverse_gas_fvf_dot = interpolate1DSlope(_gas_pressure_points,
                                                         _gas_inverse_fvf_values,
                                                         oilPressure(),
                                                         "PVDG pressure") *
                                         pressure_dot;
  const ADReal gas_fvf_dot =
      -inverse_gas_fvf_dot / (inverse_gas_fvf * inverse_gas_fvf);
  _water_reference_phase_mass_coefficient_rate[_qp] =
      _water_surface_density *
      ((*_J_dot)[_qp] * porosity / _water_fvf[_qp] +
       _J[_qp] * porosity_dot / _water_fvf[_qp] -
       _J[_qp] * porosity * water_fvf_dot / (_water_fvf[_qp] * _water_fvf[_qp]));
  _free_gas_reference_phase_mass_coefficient_rate[_qp] =
      _gas_surface_density *
      ((*_J_dot)[_qp] * porosity / _gas_fvf[_qp] +
       _J[_qp] * porosity_dot / _gas_fvf[_qp] -
       _J[_qp] * porosity * gas_fvf_dot / (_gas_fvf[_qp] * _gas_fvf[_qp]));
  ADReal oil_fvf_dot;
  if (use_saturated_pvto)
  {
    const ADReal inverse_oil_fvf = interpolate1D(_oil_bubble_pressure_points,
                                                  _saturated_oil_inverse_fvf_values,
                                                  oilPressure(),
                                                  "saturated PVTO pressure");
    const ADReal inverse_oil_fvf_dot =
        interpolate1DSlope(_oil_bubble_pressure_points,
                           _saturated_oil_inverse_fvf_values,
                           oilPressure(),
                           "saturated PVTO pressure") *
        pressure_dot;
    oil_fvf_dot = -inverse_oil_fvf_dot / (inverse_oil_fvf * inverse_oil_fvf);
  }
  else
  {
    const ADReal inverse_oil_fvf = interpolateUndersaturatedOil(_oil_inverse_fvf_values);
    const auto derivatives = undersaturatedOilDerivatives(_oil_inverse_fvf_values);
    const ADReal inverse_oil_fvf_dot =
        derivatives.first * pressure_dot + derivatives.second * rs_dot;
    oil_fvf_dot = -inverse_oil_fvf_dot / (inverse_oil_fvf * inverse_oil_fvf);
  }

  const ADReal gas_saturation_dot = gasSaturationDot();
  const ADReal water_saturation_dot = waterSaturationDot();
  const ADReal oil_saturation_dot = -water_saturation_dot - gas_saturation_dot;
  const ADReal water_storage_factor = water_saturation / _water_fvf[_qp];
  const ADReal water_storage_factor_dot =
      water_saturation_dot / _water_fvf[_qp] -
      water_saturation * water_fvf_dot / (_water_fvf[_qp] * _water_fvf[_qp]);
  _water_reference_component_storage_rate[_qp] =
      _water_surface_density *
      ((*_J_dot)[_qp] * porosity * water_storage_factor +
       _J[_qp] * porosity_dot * water_storage_factor +
       _J[_qp] * porosity * water_storage_factor_dot);

  const ADReal oil_storage_factor = _oil_saturation[_qp] / _oil_fvf[_qp];
  const ADReal oil_storage_factor_dot =
      oil_saturation_dot / _oil_fvf[_qp] -
      _oil_saturation[_qp] * oil_fvf_dot / (_oil_fvf[_qp] * _oil_fvf[_qp]);
  _oil_reference_component_storage_rate[_qp] =
      _oil_surface_density *
      ((*_J_dot)[_qp] * porosity * oil_storage_factor +
       _J[_qp] * porosity_dot * oil_storage_factor +
       _J[_qp] * porosity * oil_storage_factor_dot);

  const ADReal gas_storage_factor =
      gas_saturation / _gas_fvf[_qp] +
      _solution_gas_oil_ratio_state[_qp] * _oil_saturation[_qp] / _oil_fvf[_qp];
  const ADReal gas_storage_factor_dot =
      gas_saturation_dot / _gas_fvf[_qp] -
      gas_saturation * gas_fvf_dot / (_gas_fvf[_qp] * _gas_fvf[_qp]) +
      rs_dot * _oil_saturation[_qp] / _oil_fvf[_qp] +
      _solution_gas_oil_ratio_state[_qp] * oil_saturation_dot / _oil_fvf[_qp] -
      _solution_gas_oil_ratio_state[_qp] * _oil_saturation[_qp] * oil_fvf_dot /
          (_oil_fvf[_qp] * _oil_fvf[_qp]);
  _gas_reference_component_storage_rate[_qp] =
      _gas_surface_density *
      ((*_J_dot)[_qp] * porosity * gas_storage_factor +
       _J[_qp] * porosity_dot * gas_storage_factor +
       _J[_qp] * porosity * gas_storage_factor_dot);

  const ADReal free_gas_storage_factor = gas_saturation / _gas_fvf[_qp];
  const ADReal free_gas_storage_factor_dot =
      gas_saturation_dot / _gas_fvf[_qp] -
      gas_saturation * gas_fvf_dot / (_gas_fvf[_qp] * _gas_fvf[_qp]);
  _free_gas_reference_component_storage_rate[_qp] =
      _gas_surface_density *
      ((*_J_dot)[_qp] * porosity * free_gas_storage_factor +
       _J[_qp] * porosity_dot * free_gas_storage_factor +
       _J[_qp] * porosity * free_gas_storage_factor_dot);

  const ADReal dissolved_gas_storage_factor =
      _solution_gas_oil_ratio_state[_qp] * _oil_saturation[_qp] / _oil_fvf[_qp];
  const ADReal dissolved_gas_storage_factor_dot =
      rs_dot * _oil_saturation[_qp] / _oil_fvf[_qp] +
      _solution_gas_oil_ratio_state[_qp] * oil_saturation_dot / _oil_fvf[_qp] -
      _solution_gas_oil_ratio_state[_qp] * _oil_saturation[_qp] * oil_fvf_dot /
          (_oil_fvf[_qp] * _oil_fvf[_qp]);
  _dissolved_gas_reference_component_storage_rate[_qp] =
      _gas_surface_density *
      ((*_J_dot)[_qp] * porosity * dissolved_gas_storage_factor +
       _J[_qp] * porosity_dot * dissolved_gas_storage_factor +
       _J[_qp] * porosity * dissolved_gas_storage_factor_dot);
}
