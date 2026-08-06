#include "ADReactionNetworkMaterial.h"
#include "PhaseRegistry.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADReactionNetworkMaterial);

InputParameters
ADReactionNetworkMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Assembles arbitrary mechanism-major reaction-network sources, traditional affinities, "
      "tau-corrected generalized conversion coefficients, and the subsystem-temperature-weighted "
      "neutral force used by the nonisothermal Onsager reaction law. Stoichiometric coefficients "
      "are flattened as mechanism, phase, then component.");
  params.addRequiredParam<UserObjectName>("phase_registry", "Input-deck phase registry.");
  params.addRequiredParam<std::vector<std::string>>(
      "phases", "Registered phases participating in the reaction network.");
  params.addRequiredParam<std::vector<std::string>>(
      "components", "Component names defining the component ordering.");
  params.addRequiredCoupledVar(
      "reaction_rates", "Mechanism rates in the same order used by stoichiometric_coefficients.");
  params.addRequiredParam<std::vector<Real>>(
      "stoichiometric_coefficients",
      "Flattened mechanism-major stoichiometric coefficients nu_xi(m)^alpha.");
  params.addRequiredParam<std::vector<MaterialPropertyName>>(
      "chemical_potential_names",
      "Flattened phase-major chemical or electrochemical potential names.");
  params.addParam<std::vector<MaterialPropertyName>>(
      "phase_tau_offset_names",
      {},
      "Optional phase tau-transfer offset properties D_xi tau/Dt - |v_xi|^2/2. Supply one "
      "per phase to compute generalized conversion coefficients.");
  params.addParam<std::vector<MaterialPropertyName>>(
      "neutral_conversion_coefficient_names",
      {},
      "Optional flattened phase-major neutral coefficients psi_xi+L_xi^alpha used by the "
      "temperature-weighted reaction force.");
  params.addParam<std::vector<MaterialPropertyName>>(
      "phase_temperature_names",
      {},
      "Optional absolute-temperature property for each phase; phases in one thermal subsystem "
      "may reference the same property.");
  params.addParam<MooseEnum>(
      "kinetic_force",
      MooseEnum("generalized_conversion temperature_weighted_neutral", "generalized_conversion"),
      "Force used by the optional linear kinetic law.");
  params.addParam<std::vector<Real>>(
      "kinetic_mobilities",
      {},
      "Optional nonnegative mechanism mobilities. When supplied, kinetic residuals are "
      "rate_m - mobility_m * selected_kinetic_force_m.");
  params.addParam<std::vector<MaterialPropertyName>>(
      "forward_phase_active_names",
      {},
      "Optional mechanism-major activity properties multiplying positive selected-force kinetics "
      "(forward reactions). Supply one per mechanism together with reverse names.");
  params.addParam<std::vector<MaterialPropertyName>>(
      "reverse_phase_active_names",
      {},
      "Optional mechanism-major activity properties multiplying negative selected-force kinetics "
      "(reverse reactions). Supply one per mechanism together with forward names.");
  params.addParam<MaterialPropertyName>(
      "jacobian_name", "solid_reference_J", "Material property name for J.");
  params.addParam<std::string>(
      "property_prefix", "reaction_network", "Prefix for declared material properties.");
  return params;
}

ADReactionNetworkMaterial::ADReactionNetworkMaterial(const InputParameters & parameters)
  : Material(parameters),
    _phase_registry(getUserObject<PhaseRegistry>("phase_registry")),
    _phases(getParam<std::vector<std::string>>("phases")),
    _components(getParam<std::vector<std::string>>("components")),
    _n_phases(_phases.size()),
    _n_components(_components.size()),
    _n_mechanisms(coupledComponents("reaction_rates")),
    _J(getADMaterialProperty<Real>("jacobian_name")),
    _stoichiometric_coefficients(getParam<std::vector<Real>>("stoichiometric_coefficients")),
    _use_tau_offsets(!getParam<std::vector<MaterialPropertyName>>("phase_tau_offset_names").empty()),
    _use_temperature_weighted_force(
        !getParam<std::vector<MaterialPropertyName>>("neutral_conversion_coefficient_names").empty() ||
        !getParam<std::vector<MaterialPropertyName>>("phase_temperature_names").empty()),
    _kinetic_force(getParam<MooseEnum>("kinetic_force")),
    _use_kinetic_mobilities(!getParam<std::vector<Real>>("kinetic_mobilities").empty()),
    _kinetic_mobilities(getParam<std::vector<Real>>("kinetic_mobilities")),
    _use_directional_availability(
        !getParam<std::vector<MaterialPropertyName>>("forward_phase_active_names").empty() ||
        !getParam<std::vector<MaterialPropertyName>>("reverse_phase_active_names").empty()),
    _property_prefix(getParam<std::string>("property_prefix"))
{
  if (_n_phases == 0)
    paramError("phases", "Supply at least one phase.");
  if (_n_components == 0)
    paramError("components", "Supply at least one component.");
  if (_n_mechanisms == 0)
    paramError("reaction_rates", "Supply at least one reaction mechanism rate.");
  if (_property_prefix.empty())
    paramError("property_prefix", "The material-property prefix must be nonempty.");

  for (const auto & phase : _phases)
    if (!_phase_registry.hasPhase(phase))
      paramError("phases", "Phase '", phase, "' is not registered.");

  if (_stoichiometric_coefficients.size() != _n_mechanisms * _n_phases * _n_components)
    paramError("stoichiometric_coefficients",
               "Supply exactly mechanisms.size() * phases.size() * components.size() "
               "stoichiometric coefficients.");

  const auto chemical_potential_names =
      getParam<std::vector<MaterialPropertyName>>("chemical_potential_names");
  if (chemical_potential_names.size() != _n_phases * _n_components)
    paramError("chemical_potential_names",
               "Supply exactly phases.size() * components.size() potential names.");

  const auto phase_tau_offset_names =
      getParam<std::vector<MaterialPropertyName>>("phase_tau_offset_names");
  if (_use_tau_offsets && phase_tau_offset_names.size() != _n_phases)
    paramError("phase_tau_offset_names", "Supply exactly one tau offset for each phase.");

  const auto neutral_conversion_coefficient_names =
      getParam<std::vector<MaterialPropertyName>>("neutral_conversion_coefficient_names");
  const auto phase_temperature_names =
      getParam<std::vector<MaterialPropertyName>>("phase_temperature_names");
  if (_use_temperature_weighted_force &&
      neutral_conversion_coefficient_names.size() != _n_phases * _n_components)
    paramError("neutral_conversion_coefficient_names",
               "Supply exactly phases.size() * components.size() neutral coefficients when "
               "temperature weighting is enabled.");
  if (_use_temperature_weighted_force && phase_temperature_names.size() != _n_phases)
    paramError("phase_temperature_names",
               "Supply exactly one absolute-temperature property per phase when temperature "
               "weighting is enabled.");
  if (_kinetic_force == "temperature_weighted_neutral" && !_use_temperature_weighted_force)
    paramError("kinetic_force",
               "Select temperature_weighted_neutral only with neutral coefficients and phase "
               "temperatures.");
  if (_use_kinetic_mobilities && _kinetic_mobilities.size() != _n_mechanisms)
    paramError("kinetic_mobilities", "Supply exactly one kinetic mobility for each mechanism.");
  for (const auto mobility : _kinetic_mobilities)
    if (mobility < 0.0)
      paramError("kinetic_mobilities", "Kinetic mobilities must be nonnegative.");

  const auto forward_active =
      getParam<std::vector<MaterialPropertyName>>("forward_phase_active_names");
  const auto reverse_active =
      getParam<std::vector<MaterialPropertyName>>("reverse_phase_active_names");
  if (_use_directional_availability &&
      (forward_active.size() != _n_mechanisms || reverse_active.size() != _n_mechanisms))
    paramError("forward_phase_active_names",
               "Supply one forward and one reverse activity property per mechanism.");
  for (const auto m : make_range(_n_mechanisms))
    if (_use_directional_availability)
    {
      _forward_phase_active.push_back(&getADMaterialProperty<Real>(forward_active[m]));
      _reverse_phase_active.push_back(&getADMaterialProperty<Real>(reverse_active[m]));
    }

  _reaction_rates.reserve(_n_mechanisms);
  for (const auto m : make_range(_n_mechanisms))
    _reaction_rates.push_back(&adCoupledValue("reaction_rates", m));

  _chemical_potentials.reserve(_n_phases * _n_components);
  for (const auto pc : make_range(_n_phases * _n_components))
    _chemical_potentials.push_back(&getADMaterialProperty<Real>(chemical_potential_names[pc]));

  if (_use_tau_offsets)
  {
    _phase_tau_offsets.reserve(_n_phases);
    for (const auto p : make_range(_n_phases))
      _phase_tau_offsets.push_back(&getADMaterialProperty<Real>(phase_tau_offset_names[p]));
  }
  if (_use_temperature_weighted_force)
  {
    _neutral_conversion_coefficients.reserve(_n_phases * _n_components);
    for (const auto pc : make_range(_n_phases * _n_components))
      _neutral_conversion_coefficients.push_back(
          &getADMaterialProperty<Real>(neutral_conversion_coefficient_names[pc]));
    _phase_temperatures.reserve(_n_phases);
    for (const auto p : make_range(_n_phases))
      _phase_temperatures.push_back(&getADMaterialProperty<Real>(phase_temperature_names[p]));
  }

  _phase_current_component_sources.reserve(_n_phases * _n_components);
  _phase_reference_component_sources.reserve(_n_phases * _n_components);
  for (const auto p : make_range(_n_phases))
    for (const auto c : make_range(_n_components))
    {
      _phase_current_component_sources.push_back(&declareADProperty<Real>(
          prefixedName(_phases[p] + "_current_component_source_" + std::to_string(c))));
      _phase_reference_component_sources.push_back(&declareADProperty<Real>(
          prefixedName(_phases[p] + "_reference_component_source_" + std::to_string(c))));
    }

  _mechanism_current_component_sources.reserve(_n_mechanisms * _n_components);
  _mechanism_reference_component_sources.reserve(_n_mechanisms * _n_components);
  for (const auto m : make_range(_n_mechanisms))
    for (const auto c : make_range(_n_components))
    {
      _mechanism_current_component_sources.push_back(&declareADProperty<Real>(
          prefixedName("mechanism_" + std::to_string(m) + "_current_component_source_" +
                       std::to_string(c))));
      _mechanism_reference_component_sources.push_back(&declareADProperty<Real>(
          prefixedName("mechanism_" + std::to_string(m) + "_reference_component_source_" +
                       std::to_string(c))));
    }

  _total_current_component_sources.reserve(_n_components);
  _total_reference_component_sources.reserve(_n_components);
  for (const auto c : make_range(_n_components))
  {
    _total_current_component_sources.push_back(&declareADProperty<Real>(
        prefixedName("current_component_source_" + std::to_string(c))));
    _total_reference_component_sources.push_back(&declareADProperty<Real>(
        prefixedName("reference_component_source_" + std::to_string(c))));
  }

  _mechanism_affinities.reserve(_n_mechanisms);
  _mechanism_transfer_work_corrections.reserve(_n_mechanisms);
  _mechanism_generalized_conversion_coefficients.reserve(_n_mechanisms);
  _mechanism_temperature_weighted_forces.reserve(_n_mechanisms);
  _mechanism_kinetic_forces.reserve(_n_mechanisms);
  _mechanism_kinetic_residuals.reserve(_n_mechanisms);
  _mechanism_reaction_powers.reserve(_n_mechanisms);
  _mechanism_temperature_weighted_reaction_powers.reserve(_n_mechanisms);
  for (const auto m : make_range(_n_mechanisms))
  {
    _mechanism_affinities.push_back(
        &declareADProperty<Real>(prefixedName("affinity_" + std::to_string(m))));
    _mechanism_transfer_work_corrections.push_back(&declareADProperty<Real>(
        prefixedName("transfer_work_correction_" + std::to_string(m))));
    _mechanism_generalized_conversion_coefficients.push_back(&declareADProperty<Real>(
        prefixedName("generalized_conversion_coefficient_" + std::to_string(m))));
    _mechanism_temperature_weighted_forces.push_back(&declareADProperty<Real>(
        prefixedName("temperature_weighted_force_" + std::to_string(m))));
    _mechanism_kinetic_forces.push_back(
        &declareADProperty<Real>(prefixedName("kinetic_force_" + std::to_string(m))));
    _mechanism_kinetic_residuals.push_back(
        &declareADProperty<Real>(prefixedName("kinetic_residual_" + std::to_string(m))));
    _mechanism_reaction_powers.push_back(
        &declareADProperty<Real>(prefixedName("reaction_power_" + std::to_string(m))));
    _mechanism_temperature_weighted_reaction_powers.push_back(&declareADProperty<Real>(
        prefixedName("temperature_weighted_reaction_power_" + std::to_string(m))));
  }

  _mechanism_phase_mass_sums.reserve(_n_mechanisms * _n_phases);
  for (const auto m : make_range(_n_mechanisms))
    for (const auto p : make_range(_n_phases))
      _mechanism_phase_mass_sums.push_back(&declareADProperty<Real>(
          prefixedName("mechanism_" + std::to_string(m) + "_" + _phases[p] + "_mass_sum")));
}

unsigned int
ADReactionNetworkMaterial::phaseComponentIndex(const unsigned int phase,
                                               const unsigned int component) const
{
  return phase * _n_components + component;
}

unsigned int
ADReactionNetworkMaterial::mechanismComponentIndex(const unsigned int mechanism,
                                                   const unsigned int component) const
{
  return mechanism * _n_components + component;
}

unsigned int
ADReactionNetworkMaterial::mechanismPhaseIndex(const unsigned int mechanism,
                                               const unsigned int phase) const
{
  return mechanism * _n_phases + phase;
}

unsigned int
ADReactionNetworkMaterial::mechanismPhaseComponentIndex(const unsigned int mechanism,
                                                        const unsigned int phase,
                                                        const unsigned int component) const
{
  return mechanism * _n_phases * _n_components + phase * _n_components + component;
}

MaterialPropertyName
ADReactionNetworkMaterial::prefixedName(const std::string & suffix) const
{
  return MaterialPropertyName(_property_prefix + "_" + suffix);
}

void
ADReactionNetworkMaterial::computeQpProperties()
{
  for (auto * source : _phase_current_component_sources)
    (*source)[_qp] = 0.0;
  for (auto * source : _phase_reference_component_sources)
    (*source)[_qp] = 0.0;
  for (auto * source : _mechanism_current_component_sources)
    (*source)[_qp] = 0.0;
  for (auto * source : _mechanism_reference_component_sources)
    (*source)[_qp] = 0.0;
  for (auto * source : _total_current_component_sources)
    (*source)[_qp] = 0.0;
  for (auto * source : _total_reference_component_sources)
    (*source)[_qp] = 0.0;

  for (const auto m : make_range(_n_mechanisms))
  {
    ADReal affinity = 0.0;
    ADReal correction = 0.0;
    ADReal temperature_weighted_force = 0.0;

    for (const auto p : make_range(_n_phases))
    {
      ADReal phase_mass_sum = 0.0;
      if (_use_temperature_weighted_force &&
          MetaPhysicL::raw_value((*_phase_temperatures[p])[_qp]) <= 0.0)
        mooseError(name(), ": phase temperatures must be positive for the temperature-weighted "
                           "reaction force.");
      for (const auto c : make_range(_n_components))
      {
        const auto pc = phaseComponentIndex(p, c);
        const auto mc = mechanismComponentIndex(m, c);
        const auto mpc = mechanismPhaseComponentIndex(m, p, c);
        const Real nu = _stoichiometric_coefficients[mpc];
        const ADReal current_source = nu * (*_reaction_rates[m])[_qp];

        (*_phase_current_component_sources[pc])[_qp] += current_source;
        (*_mechanism_current_component_sources[mc])[_qp] += current_source;
        (*_total_current_component_sources[c])[_qp] += current_source;

        const ADReal reference_source = _J[_qp] * current_source;
        (*_phase_reference_component_sources[pc])[_qp] += reference_source;
        (*_mechanism_reference_component_sources[mc])[_qp] += reference_source;
        (*_total_reference_component_sources[c])[_qp] += reference_source;

        phase_mass_sum += nu;
        affinity -= (*_chemical_potentials[pc])[_qp] * nu;
        if (_use_temperature_weighted_force)
          temperature_weighted_force -=
              (*_neutral_conversion_coefficients[pc])[_qp] * nu /
              (*_phase_temperatures[p])[_qp];
      }

      (*_mechanism_phase_mass_sums[mechanismPhaseIndex(m, p)])[_qp] = phase_mass_sum;
      if (_use_tau_offsets)
        correction += (*_phase_tau_offsets[p])[_qp] * phase_mass_sum;
    }

    const ADReal generalized = affinity - correction;
    (*_mechanism_affinities[m])[_qp] = affinity;
    (*_mechanism_transfer_work_corrections[m])[_qp] = correction;
    (*_mechanism_generalized_conversion_coefficients[m])[_qp] = generalized;
    (*_mechanism_temperature_weighted_forces[m])[_qp] = temperature_weighted_force;
    const ADReal kinetic_force = _kinetic_force == "temperature_weighted_neutral"
                                     ? temperature_weighted_force
                                     : generalized;
    (*_mechanism_kinetic_forces[m])[_qp] = kinetic_force;
    ADReal predicted_rate = 0.0;
    if (_use_kinetic_mobilities)
    {
      ADReal availability = 1.0;
      if (_use_directional_availability)
        availability = MetaPhysicL::raw_value(kinetic_force) >= 0.0
                           ? (*_forward_phase_active[m])[_qp]
                           : (*_reverse_phase_active[m])[_qp];
      predicted_rate = _kinetic_mobilities[m] * availability * kinetic_force;
    }
    (*_mechanism_kinetic_residuals[m])[_qp] =
        (*_reaction_rates[m])[_qp] - predicted_rate;
    (*_mechanism_reaction_powers[m])[_qp] = generalized * (*_reaction_rates[m])[_qp];
    (*_mechanism_temperature_weighted_reaction_powers[m])[_qp] =
        temperature_weighted_force * (*_reaction_rates[m])[_qp];
  }
}

