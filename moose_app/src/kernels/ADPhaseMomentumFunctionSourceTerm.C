#include "ADPhaseMomentumFunctionSourceTerm.h"

#include "Function.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADPhaseMomentumFunctionSourceTerm);

InputParameters
ADPhaseMomentumFunctionSourceTerm::validParams()
{
  InputParameters params = ADKernelValue::validParams();
  params += FunctionInterface::validParams();
  params.addClassDescription(
      "Atomic -test*J*f_i current-volume momentum source for prescribed body loading or MMS.");
  params.addRequiredParam<FunctionName>("source", "Current-volume source component.");
  params.addParam<Real>("scale", 1.0, "Signed source multiplier.");
  params.addParam<MaterialPropertyName>("solid_jacobian_name", "solid_reference_J", "J.");
  return params;
}

ADPhaseMomentumFunctionSourceTerm::ADPhaseMomentumFunctionSourceTerm(
    const InputParameters & parameters)
  : ADKernelValue(parameters),
    _source(getFunction("source")),
    _J(getADMaterialProperty<Real>("solid_jacobian_name")),
    _scale(getParam<Real>("scale"))
{
}

ADReal
ADPhaseMomentumFunctionSourceTerm::precomputeQpResidual()
{
  return -_J[_qp] * _scale * _source.value(_t, _q_point[_qp]);
}
