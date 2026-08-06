#include "ADTheoryCompositionProjectionMaterial.h"
#include "PhaseRegistry.h"

#include "metaphysicl/raw_type.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADTheoryCompositionProjectionMaterial);

InputParameters
ADTheoryCompositionProjectionMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Implements the manuscript fluid/solid composition projections (current theory Eqs. "
      "182--183), the mass-fraction normalization, the phase-pressure storage sum, storage-"
      "multiplier recovery, and the neutral component Euler identity. Optional independently "
      "assembled correction properties supply each solid stress-free-map term in Eq. (183).");
  params.addRequiredParam<UserObjectName>("phase_registry", "Input-deck phase registry.");
  params.addRequiredParam<std::string>("phase", "Registered phase represented by this object.");
  params.addRequiredCoupledVar(
      "mass_fractions", "All N phase mass fractions eta_xi^alpha in component order.");
  params.addRequiredCoupledVar("phase_fraction", "Current phase volume fraction phi_xi.");
  params.addRequiredParam<MaterialPropertyName>(
      "intrinsic_density_name", "Current intrinsic phase density bar_rho_xi.");
  params.addRequiredParam<MaterialPropertyName>(
      "phase_pressure_name", "Total phase pressure bar_p_xi from the manuscript EOS relation.");
  params.addRequiredParam<MaterialPropertyName>(
      "specific_helmholtz_name",
      "Specific phase Helmholtz potential psi_xi. It must expose first derivatives with "
      "respect to every variable in mass_fractions.");
  params.addParam<MaterialPropertyName>(
      "electric_enthalpy_name",
      "",
      "Optional phase electric enthalpy omega_xi^+. When supplied it must expose first "
      "derivatives with respect to every variable in mass_fractions.");
  params.addParam<std::vector<MaterialPropertyName>>(
      "composition_correction_names",
      {},
      "Optional term-major scalar corrections. The list length must be a multiple of N: all "
      "N component corrections from term 0, then all N from term 1, etc. Fluid Eq. (182) "
      "normally leaves this empty; solid Eq. (183) stitches the two stress-map terms here.");
  params.addParam<MooseEnum>(
      "storage_multiplier_mode",
      MooseEnum("recover coupled", "recover"),
      "recover computes pi_xi^alpha from the N-1 projection equations and pressure sum; "
      "coupled consumes N storage_multipliers and reports their algebraic residuals.");
  params.addCoupledVar(
      "storage_multipliers",
      "The N pi_xi^alpha unknowns, required only when storage_multiplier_mode=coupled.");
  params.addRangeCheckedParam<Real>(
      "minimum_active_bulk_density",
      1e-14,
      "minimum_active_bulk_density>0",
      "Strict lower bound on phi_xi*bar_rho_xi when evaluating active-phase component "
      "potentials. Phase switching/complementarity must deactivate this object outside the "
      "active set.");
  params.addParam<std::string>(
      "property_prefix", "", "Output prefix; defaults to <phase>_theory_composition.");
  return params;
}

ADTheoryCompositionProjectionMaterial::ADTheoryCompositionProjectionMaterial(
    const InputParameters & parameters)
  : DerivativeMaterialInterface<Material>(parameters),
    _phase_registry(getUserObject<PhaseRegistry>("phase_registry")),
    _phase(getParam<std::string>("phase")),
    _n_components(coupledComponents("mass_fractions")),
    _recover_storage_multipliers(
        getParam<MooseEnum>("storage_multiplier_mode") == "recover"),
    _minimum_active_bulk_density(getParam<Real>("minimum_active_bulk_density")),
    _property_prefix(getParam<std::string>("property_prefix").empty()
                         ? _phase + "_theory_composition"
                         : getParam<std::string>("property_prefix")),
    _phase_fraction(adCoupledValue("phase_fraction")),
    _intrinsic_density(getADMaterialProperty<Real>("intrinsic_density_name")),
    _phase_pressure(getADMaterialProperty<Real>("phase_pressure_name")),
    _specific_helmholtz_name(getParam<MaterialPropertyName>("specific_helmholtz_name")),
    _specific_helmholtz(getADMaterialProperty<Real>(_specific_helmholtz_name)),
    _normalization_residual(
        declareADProperty<Real>(outputName("normalization_residual"))),
    _phase_pressure_storage_residual(
        declareADProperty<Real>(outputName("phase_pressure_storage_residual"))),
    _composition_multiplier(declareADProperty<Real>(outputName("composition_multiplier"))),
    _bulk_phase_density(declareADProperty<Real>(outputName("bulk_phase_density")))
{
  if (!_phase_registry.hasPhase(_phase))
    paramError("phase", "Phase '", _phase, "' is not registered.");
  if (_n_components < 2)
    paramError("mass_fractions", "Supply at least two component mass fractions.");
  if (_property_prefix.empty())
    paramError("property_prefix", "The output property prefix must be nonempty.");

  if (!_recover_storage_multipliers &&
      coupledComponents("storage_multipliers") != _n_components)
    paramError("storage_multipliers",
               "storage_multiplier_mode=coupled requires exactly one pi for each component.");
  if (_recover_storage_multipliers && isCoupled("storage_multipliers"))
    paramError("storage_multipliers",
               "Do not couple storage_multipliers when storage_multiplier_mode=recover.");

  const auto electric_name = getParam<MaterialPropertyName>("electric_enthalpy_name");
  const auto correction_names =
      getParam<std::vector<MaterialPropertyName>>("composition_correction_names");
  if (correction_names.size() % _n_components != 0)
    paramError("composition_correction_names",
               "The number of correction properties must be a multiple of the component count.");
  _correction_terms.resize(correction_names.size() / _n_components);

  _mass_fractions.reserve(_n_components);
  _mass_fraction_names.reserve(_n_components);
  _coupled_storage_multipliers.reserve(_n_components);
  _helmholtz_derivatives.reserve(_n_components);
  _electric_enthalpy_derivatives.reserve(_n_components);
  _composition_coefficients.reserve(_n_components);
  _storage_multipliers.reserve(_n_components);
  _storage_multipliers_over_mass_fraction.reserve(_n_components);
  _specific_storage_works.reserve(_n_components);
  _neutral_component_potentials.reserve(_n_components);
  for (const auto component : make_range(_n_components))
  {
    _mass_fractions.push_back(&adCoupledValue("mass_fractions", component));
    _mass_fraction_names.push_back(coupledName("mass_fractions", component));
    if (!_recover_storage_multipliers)
      _coupled_storage_multipliers.push_back(
          &adCoupledValue("storage_multipliers", component));

    _helmholtz_derivatives.push_back(&getADMaterialProperty<Real>(
        derivativePropertyNameFirst(_specific_helmholtz_name,
                                    _mass_fraction_names.back())));
    if (!electric_name.empty())
      _electric_enthalpy_derivatives.push_back(&getADMaterialProperty<Real>(
          derivativePropertyNameFirst(electric_name, _mass_fraction_names.back())));

    for (const auto term : index_range(_correction_terms))
      _correction_terms[term].push_back(
          &getADMaterialProperty<Real>(correction_names[term * _n_components + component]));

    _composition_coefficients.push_back(&declareADProperty<Real>(
        outputName("composition_coefficient_" + std::to_string(component))));
    _storage_multipliers.push_back(&declareADProperty<Real>(
        outputName("storage_multiplier_" + std::to_string(component))));
    _storage_multipliers_over_mass_fraction.push_back(&declareADProperty<Real>(
        outputName("storage_multiplier_over_mass_fraction_" + std::to_string(component))));
    _specific_storage_works.push_back(&declareADProperty<Real>(
        outputName("specific_storage_work_" + std::to_string(component))));
    _neutral_component_potentials.push_back(&declareADProperty<Real>(
        outputName("neutral_component_potential_" + std::to_string(component))));
  }

  _projection_residuals.reserve(_n_components - 1);
  for (const auto component : make_range(_n_components - 1))
    _projection_residuals.push_back(&declareADProperty<Real>(
        outputName("projection_residual_" + std::to_string(component))));
}

MaterialPropertyName
ADTheoryCompositionProjectionMaterial::outputName(const std::string & suffix) const
{
  return MaterialPropertyName(_property_prefix + "_" + suffix);
}

void
ADTheoryCompositionProjectionMaterial::computeQpProperties()
{
  _normalization_residual[_qp] = -1.0;
  _bulk_phase_density[_qp] = _phase_fraction[_qp] * _intrinsic_density[_qp];

  std::vector<ADReal> coefficient(_n_components, 0.0);
  for (const auto component : make_range(_n_components))
  {
    _normalization_residual[_qp] += (*_mass_fractions[component])[_qp];
    coefficient[component] =
        _bulk_phase_density[_qp] * (*_helmholtz_derivatives[component])[_qp];
    if (!_electric_enthalpy_derivatives.empty())
      coefficient[component] +=
          _phase_fraction[_qp] * (*_electric_enthalpy_derivatives[component])[_qp];
    for (const auto & term : _correction_terms)
      coefficient[component] += (*term[component])[_qp];
    (*_composition_coefficients[component])[_qp] = coefficient[component];
  }

  std::vector<ADReal> pi(_n_components, 0.0);
  std::vector<ADReal> pi_over_eta(_n_components, 0.0);
  if (_recover_storage_multipliers)
  {
    _composition_multiplier[_qp] = -_phase_fraction[_qp] * _phase_pressure[_qp];
    for (const auto component : make_range(_n_components))
      _composition_multiplier[_qp] +=
          (*_mass_fractions[component])[_qp] * coefficient[component];

    for (const auto component : make_range(_n_components))
    {
      pi_over_eta[component] = coefficient[component] - _composition_multiplier[_qp];
      pi[component] = (*_mass_fractions[component])[_qp] * pi_over_eta[component];
    }
  }
  else
  {
    for (const auto component : make_range(_n_components))
    {
      if (MetaPhysicL::raw_value((*_mass_fractions[component])[_qp]) <= 0.0)
        mooseError("ADTheoryCompositionProjectionMaterial coupled mode requires positive active "
                   "mass fractions; phase ",
                   _phase,
                   ", component ",
                   component,
                   ".");
      pi[component] = (*_coupled_storage_multipliers[component])[_qp];
      pi_over_eta[component] = pi[component] / (*_mass_fractions[component])[_qp];
    }
    _composition_multiplier[_qp] = coefficient.back() - pi_over_eta.back();
  }

  _phase_pressure_storage_residual[_qp] =
      -_phase_fraction[_qp] * _phase_pressure[_qp];
  for (const auto component : make_range(_n_components))
  {
    _phase_pressure_storage_residual[_qp] += pi[component];
    (*_storage_multipliers[component])[_qp] = pi[component];
    (*_storage_multipliers_over_mass_fraction[component])[_qp] = pi_over_eta[component];
  }

  const auto reference = _n_components - 1;
  for (const auto component : make_range(reference))
    (*_projection_residuals[component])[_qp] =
        coefficient[component] - coefficient[reference] - pi_over_eta[component] +
        pi_over_eta[reference];

  if (MetaPhysicL::raw_value(_bulk_phase_density[_qp]) <= _minimum_active_bulk_density)
    mooseError("ADTheoryCompositionProjectionMaterial requires an active phase with "
               "phi*bar_rho > ",
               _minimum_active_bulk_density,
               "; phase ",
               _phase,
               ". Use the phase-appearance/complementarity hierarchy to deactivate the active-"
               "phase projection outside its domain.");

  for (const auto component : make_range(_n_components))
  {
    (*_specific_storage_works[component])[_qp] =
        pi_over_eta[component] / _bulk_phase_density[_qp];
    (*_neutral_component_potentials[component])[_qp] =
        _specific_helmholtz[_qp] + (*_specific_storage_works[component])[_qp];
  }
}
