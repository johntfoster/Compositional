#include "ADTauEvolutionMaterial.h"

#include "Function.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADTauEvolutionMaterial);

InputParameters
ADTauEvolutionMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params += FunctionInterface::validParams();
  params.addClassDescription(
      "Computes the solid-frame transfer-potential residual tau_dot - |v_s|^2/2 - "
      "hat_mu_s^N + psi_s + pi_s^N/(phi_s rhobar_s eta_s^N). Optional forcing is "
      "subtracted for manufactured-solution verification.");
  params.addRequiredCoupledVar("tau", "Transfer potential tau backbone or unenriched field.");
  params.addCoupledVar(
      "tau_enrichment",
      "Optional P0 tau enrichment. When supplied, tau evolution uses d(tau + tau_enr)/dt.");
  params.addCoupledVar("reference_phase_velocity",
                       "Reference solid phase velocity components. Defaults to zero.");
  params.addCoupledVar(
      "reference_phase_displacements",
      "Reference solid displacement components; their time derivatives supply velocity. "
      "Use this production-mechanics interface or reference_phase_velocity, not both.");
  params.addParam<MaterialPropertyName>(
      "reference_neutral_potential_name",
      "",
      "Material property for hat_mu_s^N in the tau evolution equation.");
  params.addParam<MaterialPropertyName>(
      "reference_specific_helmholtz_name",
      "",
      "Material property for psi_s in the tau evolution equation.");
  params.addParam<MaterialPropertyName>(
      "reference_pressure_work_name",
      "",
      "Material property for pi_s^N/(phi_s rhobar_s eta_s^N) in the tau evolution equation.");
  params.addParam<FunctionName>("forcing", "0", "Manufactured residual forcing.");
  params.addParam<MaterialPropertyName>("tau_evolution_residual_name",
                                        "tau_evolution_residual",
                                        "Material property name for the tau residual.");
  return params;
}

ADTauEvolutionMaterial::ADTauEvolutionMaterial(const InputParameters & parameters)
  : Material(parameters),
    _tau_dot(adCoupledDot("tau")),
    _dim(_mesh.dimension()),
    _use_thermodynamic_rhs(
        !getParam<MaterialPropertyName>("reference_neutral_potential_name").empty() ||
        !getParam<MaterialPropertyName>("reference_specific_helmholtz_name").empty() ||
        !getParam<MaterialPropertyName>("reference_pressure_work_name").empty()),
    _tau_enrichment_dot(isCoupled("tau_enrichment") ? &adCoupledDot("tau_enrichment") : nullptr),
    _reference_neutral_potential(
        getParam<MaterialPropertyName>("reference_neutral_potential_name").empty()
            ? nullptr
            : &getADMaterialProperty<Real>("reference_neutral_potential_name")),
    _reference_specific_helmholtz(
        getParam<MaterialPropertyName>("reference_specific_helmholtz_name").empty()
            ? nullptr
            : &getADMaterialProperty<Real>("reference_specific_helmholtz_name")),
    _reference_pressure_work(getParam<MaterialPropertyName>("reference_pressure_work_name").empty()
                                 ? nullptr
                                 : &getADMaterialProperty<Real>("reference_pressure_work_name")),
    _forcing(getFunction("forcing")),
    _tau_evolution_residual(
        declareADProperty<Real>(getParam<MaterialPropertyName>("tau_evolution_residual_name")))
{
  if (isCoupled("reference_phase_velocity") &&
      coupledComponents("reference_phase_velocity") != _dim)
    paramError("reference_phase_velocity", "Provide exactly dim reference velocity components.");
  if (isCoupled("reference_phase_displacements") &&
      coupledComponents("reference_phase_displacements") != _dim)
    paramError("reference_phase_displacements",
               "Provide exactly dim reference displacement components.");
  if (isCoupled("reference_phase_velocity") && isCoupled("reference_phase_displacements"))
    paramError("reference_phase_velocity",
               "Choose reference_phase_velocity or reference_phase_displacements.");
  if (_use_thermodynamic_rhs &&
      (!_reference_neutral_potential || !_reference_specific_helmholtz || !_reference_pressure_work))
    paramError("reference_neutral_potential_name",
               "Supply reference_neutral_potential_name, reference_specific_helmholtz_name, and "
               "reference_pressure_work_name together.");

  _reference_phase_velocity.reserve(_dim);
  if (isCoupled("reference_phase_velocity"))
    for (const auto i : make_range(_dim))
      _reference_phase_velocity.push_back(&adCoupledValue("reference_phase_velocity", i));
  if (isCoupled("reference_phase_displacements"))
    for (const auto i : make_range(_dim))
      _reference_phase_displacement_dot.push_back(
          &adCoupledDot("reference_phase_displacements", i));
}

void
ADTauEvolutionMaterial::computeQpProperties()
{
  ADReal velocity_square = 0.0;
  for (const auto i : make_range(_reference_phase_velocity.size()))
    velocity_square += (*_reference_phase_velocity[i])[_qp] * (*_reference_phase_velocity[i])[_qp];
  for (const auto i : make_range(_reference_phase_displacement_dot.size()))
    velocity_square += (*_reference_phase_displacement_dot[i])[_qp] *
                       (*_reference_phase_displacement_dot[i])[_qp];

  const ADReal total_tau_dot =
      _tau_dot[_qp] + (_tau_enrichment_dot ? (*_tau_enrichment_dot)[_qp] : 0.0);
  _tau_evolution_residual[_qp] = total_tau_dot - 0.5 * velocity_square -
                                 _forcing.value(_t, _q_point[_qp]);

  if (_use_thermodynamic_rhs)
    _tau_evolution_residual[_qp] += -(*_reference_neutral_potential)[_qp] +
                                    (*_reference_specific_helmholtz)[_qp] +
                                    (*_reference_pressure_work)[_qp];
}
