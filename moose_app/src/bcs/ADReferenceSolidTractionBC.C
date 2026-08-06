#include "ADReferenceSolidTractionBC.h"

#include "Function.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADReferenceSolidTractionBC);

InputParameters
ADReferenceSolidTractionBC::validParams()
{
  InputParameters params = ADIntegratedBC::validParams();
  params.addClassDescription("Prescribed solid-skeleton traction component per unit reference area.");
  params.addRequiredParam<FunctionName>("traction", "Prescribed reference traction component.");
  return params;
}

ADReferenceSolidTractionBC::ADReferenceSolidTractionBC(const InputParameters & parameters)
  : ADIntegratedBC(parameters), _traction(getFunction("traction"))
{
}

ADReal
ADReferenceSolidTractionBC::computeQpResidual()
{
  return -_test[_i][_qp] * _traction.value(_t, _q_point[_qp]);
}
