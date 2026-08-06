#include "ADRegisteredPhaseFlashMaterial.h"
#include "PhaseRegistry.h"

#include "metaphysicl/raw_type.h"

#include <algorithm>

registerMooseObject("MulticomponentReactiveFlowApp", ADRegisteredPhaseFlashMaterial);

InputParameters
ADRegisteredPhaseFlashMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Comparison-only conventional equilibrium flash-state assembler. It consumes "
      "input-deck phase amounts, phase compositions, and EOS-derived thermodynamic "
      "properties. The material reports mass, volume, activity, and equilibrium residuals "
      "and computes total reference component storages. It does not solve or implement the "
      "manuscript composition projections (current theory Eqs. 182--183), storage-multiplier "
      "recovery, tau evolution, or finite-rate generalized transfer work. Keep this object "
      "isolated to the traditional-flash comparison hierarchy; manuscript-theory decks use "
      "ADTheoryCompositionProjectionMaterial instead.");
  params.addRequiredParam<UserObjectName>("phase_registry", "Input-deck phase registry.");
  params.addRequiredParam<std::vector<std::string>>(
      "phases", "Registered phases participating in this flash state.");
  params.addRequiredParam<std::vector<std::string>>(
      "components", "Component names used to define the number and ordering of components.");
  params.addParam<std::string>(
      "equilibrium_reference_phase",
      "",
      "Phase used as the reference for pressure and chemical-potential equilibrium "
      "residuals. Defaults to the first phase in phases.");
  params.addParam<MaterialPropertyName>(
      "jacobian_name", "solid_reference_J", "Material property name for the solid-reference J.");
  params.addCoupledVar("total_phase_fraction",
                       1.0,
                       "Total volume fraction occupied by the listed phases.");
  params.addRequiredCoupledVar(
      "phase_volume_fractions",
      "Phase volume fractions phi_a in the same order as phases.");
  params.addRequiredCoupledVar(
      "phase_component_mass_fractions",
      "Flattened phase-major mass fractions eta_a^alpha: all components for phases[0], "
      "then all components for phases[1], and so on.");
  params.addCoupledVar(
      "overall_mass_fractions",
      "Optional overall component mass fractions z^alpha. When supplied, composition "
      "residuals are reported for every component.");
  params.addRequiredParam<std::vector<MaterialPropertyName>>(
      "phase_intrinsic_density_names",
      "EOS-derived intrinsic density material properties in the same order as phases.");
  params.addRequiredParam<std::vector<MaterialPropertyName>>(
      "phase_pressure_names", "EOS-derived pressure material properties in the same order as phases.");
  params.addRequiredParam<std::vector<MaterialPropertyName>>(
      "chemical_potential_names",
      "Flattened phase-major chemical potential material-property names.");
  params.addRangeCheckedParam<Real>(
      "active_tol", 1e-12, "active_tol>=0", "Phase volume fraction below this value is inactive.");
  params.addParam<std::string>(
      "property_prefix", "registered_flash", "Prefix for all declared material properties.");
  return params;
}

ADRegisteredPhaseFlashMaterial::ADRegisteredPhaseFlashMaterial(
    const InputParameters & parameters)
  : Material(parameters),
    _phase_registry(getUserObject<PhaseRegistry>("phase_registry")),
    _phases(getParam<std::vector<std::string>>("phases")),
    _components(getParam<std::vector<std::string>>("components")),
    _n_phases(_phases.size()),
    _n_components(_components.size()),
    _equilibrium_reference_index(0),
    _J(getADMaterialProperty<Real>("jacobian_name")),
    _total_phase_fraction(adCoupledValue("total_phase_fraction")),
    _active_tol(getParam<Real>("active_tol")),
    _has_overall_mass_fractions(isCoupled("overall_mass_fractions")),
    _property_prefix(getParam<std::string>("property_prefix")),
    _volume_constraint_residual(declareADProperty<Real>(prefixedName("volume_constraint_residual"))),
    _total_current_mass_density(declareADProperty<Real>(prefixedName("total_current_mass_density"))),
    _total_reference_mass_storage(
        declareADProperty<Real>(prefixedName("total_reference_mass_storage"))),
    _overall_mass_fraction_sum(declareADProperty<Real>(prefixedName("overall_mass_fraction_sum")))
{
  if (_n_phases == 0)
    paramError("phases", "Supply at least one phase.");
  if (_n_components == 0)
    paramError("components", "Supply at least one component.");
  if (_property_prefix.empty())
    paramError("property_prefix", "The material-property prefix must be nonempty.");

  for (const auto & phase : _phases)
    if (!_phase_registry.hasPhase(phase))
      paramError("phases", "Phase '", phase, "' is not registered.");

  const auto reference_phase = getParam<std::string>("equilibrium_reference_phase");
  if (!reference_phase.empty())
  {
    const auto iterator = std::find(_phases.begin(), _phases.end(), reference_phase);
    if (iterator == _phases.end())
      paramError("equilibrium_reference_phase",
                 "Reference flash phase '",
                 reference_phase,
                 "' is not present in phases.");
    _equilibrium_reference_index = std::distance(_phases.begin(), iterator);
  }

  if (coupledComponents("phase_volume_fractions") != _n_phases)
    paramError("phase_volume_fractions", "Supply exactly one volume fraction for each phase.");
  if (coupledComponents("phase_component_mass_fractions") != _n_phases * _n_components)
    paramError("phase_component_mass_fractions",
               "Supply exactly phases.size() * components.size() mass fractions.");
  if (_has_overall_mass_fractions && coupledComponents("overall_mass_fractions") != _n_components)
    paramError("overall_mass_fractions", "Supply exactly one overall mass fraction per component.");

  const auto density_names =
      getParam<std::vector<MaterialPropertyName>>("phase_intrinsic_density_names");
  const auto pressure_names = getParam<std::vector<MaterialPropertyName>>("phase_pressure_names");
  const auto chemical_potential_names =
      getParam<std::vector<MaterialPropertyName>>("chemical_potential_names");
  if (density_names.size() != _n_phases)
    paramError("phase_intrinsic_density_names",
               "Supply exactly one intrinsic-density property for each phase.");
  if (pressure_names.size() != _n_phases)
    paramError("phase_pressure_names", "Supply exactly one pressure property for each phase.");
  if (chemical_potential_names.size() != _n_phases * _n_components)
    paramError("chemical_potential_names",
               "Supply exactly phases.size() * components.size() chemical-potential names.");

  _phase_volume_fractions.reserve(_n_phases);
  _phase_intrinsic_densities.reserve(_n_phases);
  _phase_pressures.reserve(_n_phases);
  _phase_active.reserve(_n_phases);
  _phase_saturations.reserve(_n_phases);
  _phase_current_mass_densities.reserve(_n_phases);
  _phase_component_mass_fraction_sums.reserve(_n_phases);
  _phase_component_mass_fraction_residuals.reserve(_n_phases);
  _phase_pressure_equilibrium_residuals.reserve(_n_phases);

  for (const auto p : make_range(_n_phases))
  {
    _phase_volume_fractions.push_back(&adCoupledValue("phase_volume_fractions", p));
    _phase_intrinsic_densities.push_back(&getADMaterialProperty<Real>(density_names[p]));
    _phase_pressures.push_back(&getADMaterialProperty<Real>(pressure_names[p]));
    _phase_active.push_back(&declareADProperty<Real>(prefixedName(_phases[p] + "_active")));
    _phase_saturations.push_back(&declareADProperty<Real>(prefixedName(_phases[p] + "_saturation")));
    _phase_current_mass_densities.push_back(
        &declareADProperty<Real>(prefixedName(_phases[p] + "_current_mass_density")));
    _phase_component_mass_fraction_sums.push_back(
        &declareADProperty<Real>(prefixedName(_phases[p] + "_component_mass_fraction_sum")));
    _phase_component_mass_fraction_residuals.push_back(
        &declareADProperty<Real>(prefixedName(_phases[p] + "_component_mass_fraction_residual")));
    _phase_pressure_equilibrium_residuals.push_back(
        &declareADProperty<Real>(prefixedName(_phases[p] + "_pressure_equilibrium_residual")));
  }

  _phase_component_mass_fractions.reserve(_n_phases * _n_components);
  _phase_chemical_potentials.reserve(_n_phases * _n_components);
  _phase_reference_component_storages.reserve(_n_phases * _n_components);
  _phase_current_component_densities.reserve(_n_phases * _n_components);
  _phase_component_mass_fraction_properties.reserve(_n_phases * _n_components);
  _chemical_equilibrium_residuals.reserve(_n_phases * _n_components);
  for (const auto p : make_range(_n_phases))
    for (const auto c : make_range(_n_components))
    {
      const auto index = phaseComponentIndex(p, c);
      _phase_component_mass_fractions.push_back(
          &adCoupledValue("phase_component_mass_fractions", index));
      _phase_chemical_potentials.push_back(
          &getADMaterialProperty<Real>(chemical_potential_names[index]));
      _phase_current_component_densities.push_back(&declareADProperty<Real>(
          prefixedName(_phases[p] + "_current_component_density_" + std::to_string(c))));
      _phase_component_mass_fraction_properties.push_back(&declareADProperty<Real>(
          prefixedName(_phases[p] + "_component_mass_fraction_" + std::to_string(c))));
      _phase_reference_component_storages.push_back(&declareADProperty<Real>(
          prefixedName(_phases[p] + "_reference_component_storage_" + std::to_string(c))));
      _chemical_equilibrium_residuals.push_back(&declareADProperty<Real>(
          prefixedName(_phases[p] + "_chemical_equilibrium_residual_" + std::to_string(c))));
    }

  _overall_mass_fractions_from_phases.reserve(_n_components);
  _overall_composition_residuals.reserve(_n_components);
  _total_current_component_densities.reserve(_n_components);
  _total_reference_component_storages.reserve(_n_components);
  for (const auto c : make_range(_n_components))
  {
    if (_has_overall_mass_fractions)
      _overall_mass_fractions.push_back(&adCoupledValue("overall_mass_fractions", c));
    _overall_mass_fractions_from_phases.push_back(
        &declareADProperty<Real>(prefixedName("overall_mass_fraction_from_phases_" +
                                             std::to_string(c))));
    _overall_composition_residuals.push_back(
        &declareADProperty<Real>(prefixedName("overall_composition_residual_" +
                                             std::to_string(c))));
    _total_current_component_densities.push_back(
        &declareADProperty<Real>(prefixedName("total_current_component_density_" +
                                             std::to_string(c))));
    _total_reference_component_storages.push_back(
        &declareADProperty<Real>(prefixedName("total_reference_component_storage_" +
                                             std::to_string(c))));
  }
}

unsigned int
ADRegisteredPhaseFlashMaterial::phaseComponentIndex(const unsigned int phase,
                                                    const unsigned int component) const
{
  return phase * _n_components + component;
}

MaterialPropertyName
ADRegisteredPhaseFlashMaterial::prefixedName(const std::string & suffix) const
{
  return MaterialPropertyName(_property_prefix + "_" + suffix);
}

void
ADRegisteredPhaseFlashMaterial::computeQpProperties()
{
  std::vector<ADReal> active(_n_phases, 0.0);
  std::vector<ADReal> active_phase_volume(_n_phases, 0.0);
  std::vector<ADReal> phase_current_mass(_n_phases, 0.0);
  std::vector<ADReal> total_current_component_mass(_n_components, 0.0);

  ADReal active_phase_volume_sum = 0.0;
  _total_current_mass_density[_qp] = 0.0;
  for (const auto p : make_range(_n_phases))
  {
    active[p] =
        MetaPhysicL::raw_value((*_phase_volume_fractions[p])[_qp]) > _active_tol ? 1.0 : 0.0;
    active_phase_volume[p] = active[p] * (*_phase_volume_fractions[p])[_qp];
    active_phase_volume_sum += active_phase_volume[p];
    phase_current_mass[p] = active_phase_volume[p] * (*_phase_intrinsic_densities[p])[_qp];

    (*_phase_active[p])[_qp] = active[p];
    (*_phase_current_mass_densities[p])[_qp] = phase_current_mass[p];
    _total_current_mass_density[_qp] += phase_current_mass[p];
  }

  _volume_constraint_residual[_qp] = active_phase_volume_sum - _total_phase_fraction[_qp];
  _total_reference_mass_storage[_qp] = _J[_qp] * _total_current_mass_density[_qp];

  const auto active_phase_volume_sum_value = MetaPhysicL::raw_value(active_phase_volume_sum);
  for (const auto p : make_range(_n_phases))
    (*_phase_saturations[p])[_qp] =
        active_phase_volume_sum_value > _active_tol ? active_phase_volume[p] / active_phase_volume_sum
                                                   : 0.0;

  for (const auto p : make_range(_n_phases))
  {
    ADReal mass_fraction_sum = 0.0;
    for (const auto c : make_range(_n_components))
      mass_fraction_sum += (*_phase_component_mass_fractions[phaseComponentIndex(p, c)])[_qp];
    (*_phase_component_mass_fraction_sums[p])[_qp] = mass_fraction_sum;
    (*_phase_component_mass_fraction_residuals[p])[_qp] = active[p] * (mass_fraction_sum - 1.0);

    for (const auto c : make_range(_n_components))
    {
      const auto index = phaseComponentIndex(p, c);
      (*_phase_component_mass_fraction_properties[index])[_qp] =
          (*_phase_component_mass_fractions[index])[_qp];
      const ADReal current_component_mass =
          phase_current_mass[p] * (*_phase_component_mass_fractions[index])[_qp];
      (*_phase_current_component_densities[index])[_qp] = current_component_mass;
      (*_phase_reference_component_storages[index])[_qp] = _J[_qp] * current_component_mass;
      total_current_component_mass[c] += current_component_mass;
    }
  }

  const ADReal reference_phase_active = active[_equilibrium_reference_index];
  for (const auto p : make_range(_n_phases))
  {
    (*_phase_pressure_equilibrium_residuals[p])[_qp] =
        active[p] * reference_phase_active *
        ((*_phase_pressures[p])[_qp] - (*_phase_pressures[_equilibrium_reference_index])[_qp]);
    for (const auto c : make_range(_n_components))
    {
      const auto index = phaseComponentIndex(p, c);
      (*_chemical_equilibrium_residuals[index])[_qp] =
          active[p] * reference_phase_active *
          ((*_phase_chemical_potentials[index])[_qp] -
           (*_phase_chemical_potentials[phaseComponentIndex(_equilibrium_reference_index, c)])[_qp]);
    }
  }

  _overall_mass_fraction_sum[_qp] = 0.0;
  for (const auto c : make_range(_n_components))
  {
    (*_total_current_component_densities[c])[_qp] = total_current_component_mass[c];
    (*_total_reference_component_storages[c])[_qp] = _J[_qp] * total_current_component_mass[c];

    const ADReal mass_fraction_from_phases =
        MetaPhysicL::raw_value(_total_current_mass_density[_qp]) > _active_tol
            ? total_current_component_mass[c] / _total_current_mass_density[_qp]
            : 0.0;
    (*_overall_mass_fractions_from_phases[c])[_qp] = mass_fraction_from_phases;
    if (_has_overall_mass_fractions)
    {
      _overall_mass_fraction_sum[_qp] += (*_overall_mass_fractions[c])[_qp];
      (*_overall_composition_residuals[c])[_qp] =
          mass_fraction_from_phases - (*_overall_mass_fractions[c])[_qp];
    }
    else
    {
      _overall_mass_fraction_sum[_qp] += mass_fraction_from_phases;
      (*_overall_composition_residuals[c])[_qp] = 0.0;
    }
  }
}
