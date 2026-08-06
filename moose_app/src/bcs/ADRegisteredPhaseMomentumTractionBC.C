#include "ADRegisteredPhaseMomentumTractionBC.h"

#include "Function.h"
#include "PhaseRegistry.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADRegisteredPhaseMomentumTractionBC);

InputParameters
ADRegisteredPhaseMomentumTractionBC::validParams()
{
  InputParameters params = ADIntegratedBC::validParams();
  params.addClassDescription(
      "Prescribed traction component per unit reference area for a registered full phase momentum solve.");
  params.addRequiredParam<std::string>("phase", "Registered phase using momentum model 'full'.");
  params.addRequiredParam<UserObjectName>("phase_registry", "Input-deck phase registry.");
  params.addRequiredParam<FunctionName>("traction", "Prescribed reference traction component.");
  return params;
}

ADRegisteredPhaseMomentumTractionBC::ADRegisteredPhaseMomentumTractionBC(
    const InputParameters & parameters)
  : ADIntegratedBC(parameters),
    _phase_name(getParam<std::string>("phase")),
    _phase_registry(getUserObject<PhaseRegistry>("phase_registry")),
    _traction(getFunction("traction"))
{
  if (!_phase_registry.hasPhase(_phase_name) || !_phase_registry.usesFullMomentum(_phase_name))
    paramError("phase", "Phase must be registered with momentum model 'full'.");
}

ADReal
ADRegisteredPhaseMomentumTractionBC::computeQpResidual()
{
  return -_test[_i][_qp] * _traction.value(_t, _q_point[_qp]);
}
