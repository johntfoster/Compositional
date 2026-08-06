#include "ADPhaseDeformationGradientHistory.h"

#include "Function.h"
#include "PhaseRegistry.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADPhaseDeformationGradientHistory);

InputParameters
ADPhaseDeformationGradientHistory::validParams()
{
  InputParameters params = ADTimeKernel::validParams();
  params.addClassDescription("Solid-frame residual for one component of mobile-phase "
                             "history kinematics: dF_a/dt|_X + c_a . Grad_X F_a - l_a F_a.");
  params.addRequiredParam<std::string>("phase", "Registered non-reference phase name.");
  params.addRequiredParam<UserObjectName>("phase_registry", "Input-deck phase registry.");
  params.addRequiredRangeCheckedParam<unsigned int>("row", "row<3", "Row of F_a.");
  params.addRequiredRangeCheckedParam<unsigned int>("col", "col<3", "Column of F_a.");
  params.addParam<FunctionName>("forcing", "0", "Manufactured source for this F_a component.");
  return params;
}

ADPhaseDeformationGradientHistory::ADPhaseDeformationGradientHistory(
    const InputParameters & parameters)
  : ADTimeKernel(parameters),
    _phase_name(getParam<std::string>("phase")),
    _phase_registry(getUserObject<PhaseRegistry>("phase_registry")),
    _row(getParam<unsigned int>("row")),
    _col(getParam<unsigned int>("col")),
    _phase_reference_convective_velocity(
        getADMaterialProperty<RealVectorValue>(_phase_name + "_phase_reference_convective_velocity")),
    _phase_velocity_gradient_current(
        getADMaterialProperty<RankTwoTensor>(_phase_name + "_phase_velocity_gradient_current")),
    _phase_F(getADMaterialProperty<RankTwoTensor>(_phase_name + "_phase_deformation_gradient")),
    _forcing(getFunction("forcing"))
{
  if (!_phase_registry.hasPhase(_phase_name) || _phase_registry.isReferencePhase(_phase_name))
    paramError("phase", "Phase must be a registered non-reference phase.");
}

ADReal
ADPhaseDeformationGradientHistory::computeQpResidual()
{
  const auto lF = _phase_velocity_gradient_current[_qp] * _phase_F[_qp];
  return _test[_i][_qp] * (_u_dot[_qp] +
                           _phase_reference_convective_velocity[_qp] * _grad_u[_qp] -
                           lF(_row, _col) - _forcing.value(_t, _q_point[_qp]));
}
