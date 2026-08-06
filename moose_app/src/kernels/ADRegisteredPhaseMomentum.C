#include "ADRegisteredPhaseMomentum.h"

#include "Function.h"
#include "PhaseRegistry.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADRegisteredPhaseMomentum);

InputParameters
ADRegisteredPhaseMomentum::validParams()
{
  InputParameters params = ADTimeKernel::validParams();
  params.addClassDescription(
      "Full registered-phase momentum residual pulled back to the reference phase mesh. "
      "Includes phase material acceleration, equivalent pressure, optional capillary pressure, gravity, "
      "fluid-skeleton drag, conversion insertion, and optional extra Cauchy stress.");
  params.addRequiredParam<std::string>("phase", "Registered phase using momentum model 'full'.");
  params.addRequiredParam<UserObjectName>("phase_registry", "Input-deck phase registry.");
  params.addRequiredRangeCheckedParam<unsigned int>("component", "component<3", "Momentum component.");
  params.addRequiredCoupledVar("phase_velocity", "All current phase-velocity components.");
  params.addRequiredCoupledVar("solid_displacements", "Reference-phase displacement components.");
  params.addRequiredCoupledVar("bulk_density", "Current bulk phase density rho_a = phi_a rhobar_a.");
  params.addRequiredCoupledVar("phase_fraction", "Current phase volume fraction phi_a.");
  params.addRequiredCoupledVar("pressure_potential", "Base equivalent pressure p_E backbone or unenriched field.");
  params.addCoupledVar("pressure_potential_enrichment",
                       "Optional P0 enrichment for the equivalent-pressure driver.");
  params.addParam<bool>(
      "include_capillary_pressure",
      false,
      "Include the phase capillary contribution gamma_a in the pressure force.");
  params.addCoupledVar(
      "capillary_pressure",
      "Optional phase capillary contribution gamma_a; required only when "
      "include_capillary_pressure=true.");
  params.addCoupledVar("capillary_pressure_enrichment",
                       "Optional P0 enrichment for the phase capillary-pressure driver.");
  params.addCoupledVar("net_conversion_rate", 0.0, "Net phase mass production sum_alpha dot(c)_a^alpha.");
  params.addParam<Real>(
      "net_conversion_rate_scale",
      1.0,
      "Signed scale converting the coupled rate into this phase's net mass production. This "
      "allows one reaction-rate variable to drive donor and receiver phase momentum equations.");
  params.addCoupledVar("transfer_potential", 0.0, "Transfer potential tau stored on the solid mesh.");
  params.addCoupledVar("transfer_potential_enrichment",
                       "Optional discontinuous enrichment of the transfer potential tau.");
  params.addCoupledVar(
      "additional_interaction_force",
      "Optional current-volume interaction-force components beyond the built-in "
      "fluid-skeleton drag, including registered fluid-fluid interactions.");
  params.addRequiredRangeCheckedParam<Real>("viscosity", "viscosity>0", "Dynamic phase viscosity.");
  params.addRequiredRangeCheckedParam<Real>("permeability", "permeability>0", "Isotropic phase permeability.");
  params.addParam<RealVectorValue>("gravity", RealVectorValue(), "Spatial gravity vector.");
  params.addParam<MaterialPropertyName>(
      "extra_cauchy_stress_name",
      "",
      "Optional phase extra Cauchy stress sigma'_a + phi_a E tensor d_a.");
  params.addParam<MaterialPropertyName>("solid_jacobian_name", "solid_reference_J", "Property name for J_s.");
  params.addParam<MaterialPropertyName>(
      "solid_inverse_deformation_gradient_name", "solid_reference_F_inv", "Property name for F_s^{-1}.");
  params.addParam<FunctionName>("forcing", "0", "Manufactured body-force residual contribution.");
  return params;
}

ADRegisteredPhaseMomentum::ADRegisteredPhaseMomentum(const InputParameters & parameters)
  : ADTimeKernel(parameters),
    _phase_name(getParam<std::string>("phase")),
    _phase_registry(getUserObject<PhaseRegistry>("phase_registry")),
    _component(getParam<unsigned int>("component")),
    _dim(_mesh.dimension()),
    _bulk_density(adCoupledValue("bulk_density")),
    _phase_fraction(adCoupledValue("phase_fraction")),
    _pressure_potential_gradient(adCoupledGradient("pressure_potential")),
    _pressure_potential_enrichment_gradient(isCoupled("pressure_potential_enrichment")
                                                ? &adCoupledGradient("pressure_potential_enrichment")
                                                : nullptr),
    _include_capillary_pressure(getParam<bool>("include_capillary_pressure")),
    _capillary_pressure_gradient(nullptr),
    _capillary_pressure_enrichment_gradient(nullptr),
    _net_conversion_rate(adCoupledValue("net_conversion_rate")),
    _net_conversion_rate_scale(getParam<Real>("net_conversion_rate_scale")),
    _transfer_potential_gradient(adCoupledGradient("transfer_potential")),
    _transfer_potential_enrichment_gradient(isCoupled("transfer_potential_enrichment")
                                                ? &adCoupledGradient("transfer_potential_enrichment")
                                                : nullptr),
    _solid_J(getADMaterialProperty<Real>("solid_jacobian_name")),
    _solid_F_inv(getADMaterialProperty<RankTwoTensor>("solid_inverse_deformation_gradient_name")),
    _extra_cauchy_stress(getParam<MaterialPropertyName>("extra_cauchy_stress_name").empty()
                             ? nullptr
                             : &getADMaterialProperty<RankTwoTensor>("extra_cauchy_stress_name")),
    _viscosity(getParam<Real>("viscosity")),
    _permeability(getParam<Real>("permeability")),
    _gravity(getParam<RealVectorValue>("gravity")),
    _forcing(getFunction("forcing"))
{
  if (!_phase_registry.hasPhase(_phase_name) || !_phase_registry.usesFullMomentum(_phase_name))
    paramError("phase", "Phase must be registered with momentum model 'full'.");
  if (_component >= _dim)
    paramError("component", "Momentum component must be smaller than the mesh dimension.");
  if (coupledComponents("phase_velocity") != _dim)
    paramError("phase_velocity", "Provide exactly dim phase-velocity components.");
  if (coupledComponents("solid_displacements") != _dim)
    paramError("solid_displacements", "Provide exactly dim solid-displacement components.");
  if (isCoupled("additional_interaction_force") &&
      coupledComponents("additional_interaction_force") != _dim)
    paramError("additional_interaction_force", "Provide exactly dim force components.");
  if (_include_capillary_pressure && !isCoupled("capillary_pressure"))
    paramError("capillary_pressure",
               "A phase capillary field is required when include_capillary_pressure=true.");
  if (!_include_capillary_pressure && isCoupled("capillary_pressure"))
    paramError("capillary_pressure",
               "Set include_capillary_pressure=true to couple a phase capillary field.");
  if (!_include_capillary_pressure && isCoupled("capillary_pressure_enrichment"))
    paramError("capillary_pressure_enrichment",
               "Set include_capillary_pressure=true to couple a phase capillary enrichment field.");
  if (_include_capillary_pressure)
  {
    _capillary_pressure_gradient = &adCoupledGradient("capillary_pressure");
    if (isCoupled("capillary_pressure_enrichment"))
      _capillary_pressure_enrichment_gradient = &adCoupledGradient("capillary_pressure_enrichment");
  }

  _phase_velocities.reserve(_dim);
  _solid_velocities.reserve(_dim);
  _additional_interaction_force.reserve(_dim);
  for (const auto i : make_range(_dim))
  {
    _phase_velocities.push_back(&adCoupledValue("phase_velocity", i));
    _solid_velocities.push_back(&adCoupledDot("solid_displacements", i));
    if (isCoupled("additional_interaction_force"))
      _additional_interaction_force.push_back(
          &adCoupledValue("additional_interaction_force", i));
  }
}

ADReal
ADRegisteredPhaseMomentum::computeQpResidual()
{
  ADRealVectorValue relative_velocity;
  for (const auto i : make_range(_dim))
    relative_velocity(i) = (*_phase_velocities[i])[_qp] - (*_solid_velocities[i])[_qp];

  const ADRealVectorValue reference_convective_velocity = _solid_F_inv[_qp] * relative_velocity;
  const ADReal acceleration = _u_dot[_qp] + reference_convective_velocity * _grad_u[_qp];
  ADRealVectorValue reference_pressure_gradient = _pressure_potential_gradient[_qp];
  if (_pressure_potential_enrichment_gradient)
    reference_pressure_gradient += (*_pressure_potential_enrichment_gradient)[_qp];
  if (_include_capillary_pressure)
  {
    reference_pressure_gradient += (*_capillary_pressure_gradient)[_qp];
    if (_capillary_pressure_enrichment_gradient)
      reference_pressure_gradient += (*_capillary_pressure_enrichment_gradient)[_qp];
  }
  const ADRealVectorValue current_pressure_gradient =
      _solid_F_inv[_qp].transpose() * reference_pressure_gradient;
  ADRealVectorValue reference_tau_gradient = _transfer_potential_gradient[_qp];
  if (_transfer_potential_enrichment_gradient)
    reference_tau_gradient += (*_transfer_potential_enrichment_gradient)[_qp];
  const ADRealVectorValue current_tau_gradient =
      _solid_F_inv[_qp].transpose() * reference_tau_gradient;
  const ADReal drag = _viscosity * _phase_fraction[_qp] * _phase_fraction[_qp] / _permeability;

  ADReal strong_residual =
      _bulk_density[_qp] * acceleration + _phase_fraction[_qp] * current_pressure_gradient(_component) -
      _bulk_density[_qp] * _gravity(_component) + drag * relative_velocity(_component) -
      _net_conversion_rate_scale * _net_conversion_rate[_qp] *
          (current_tau_gradient(_component) - (*_phase_velocities[_component])[_qp]) -
      _forcing.value(_t, _q_point[_qp]);
  if (!_additional_interaction_force.empty())
    strong_residual -= (*_additional_interaction_force[_component])[_qp];

  ADReal residual = _test[_i][_qp] * _solid_J[_qp] * strong_residual;
  if (_extra_cauchy_stress)
  {
    const ADRankTwoTensor phase_piola =
        _solid_J[_qp] * (*_extra_cauchy_stress)[_qp] * _solid_F_inv[_qp].transpose();
    for (const auto j : make_range(_dim))
      residual += _grad_test[_i][_qp](j) * phase_piola(_component, j);
  }
  return residual;
}
