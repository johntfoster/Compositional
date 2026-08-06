#include "ADPhaseJacobianHistory.h"

#include "Function.h"
#include "PhaseRegistry.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADPhaseJacobianHistory);

InputParameters
ADPhaseJacobianHistory::validParams()
{
  InputParameters params = ADTimeKernel::validParams();
  params.addClassDescription("Solid-frame residual for the mobile-phase history Jacobian: "
                             "dJ_a/dt|_X + c_a . Grad_X J_a - J_a tr(l_a).");
  params.addRequiredParam<std::string>("phase", "Registered non-reference phase name.");
  params.addRequiredParam<UserObjectName>("phase_registry", "Input-deck phase registry.");
  params.addParam<FunctionName>("forcing", "0", "Manufactured source for J_a.");
  return params;
}

ADPhaseJacobianHistory::ADPhaseJacobianHistory(const InputParameters & parameters)
  : ADTimeKernel(parameters),
    _phase_name(getParam<std::string>("phase")),
    _phase_registry(getUserObject<PhaseRegistry>("phase_registry")),
    _phase_reference_convective_velocity(
        getADMaterialProperty<RealVectorValue>(_phase_name + "_phase_reference_convective_velocity")),
    _phase_velocity_gradient_current(
        getADMaterialProperty<RankTwoTensor>(_phase_name + "_phase_velocity_gradient_current")),
    _phase_J_history(getADMaterialProperty<Real>(_phase_name + "_phase_jacobian_history")),
    _forcing(getFunction("forcing"))
{
  if (!_phase_registry.hasPhase(_phase_name) || _phase_registry.isReferencePhase(_phase_name))
    paramError("phase", "Phase must be a registered non-reference phase.");
}

ADReal
ADPhaseJacobianHistory::computeQpResidual()
{
  return _test[_i][_qp] * (_u_dot[_qp] +
                           _phase_reference_convective_velocity[_qp] * _grad_u[_qp] -
                           _phase_J_history[_qp] *
                               _phase_velocity_gradient_current[_qp].tr() -
                           _forcing.value(_t, _q_point[_qp]));
}
