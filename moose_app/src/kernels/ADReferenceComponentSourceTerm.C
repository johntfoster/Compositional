#include "ADReferenceComponentSourceTerm.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADReferenceComponentSourceTerm);

InputParameters
ADReferenceComponentSourceTerm::validParams()
{
  InputParameters params = ADKernelValue::validParams();
  params.addClassDescription(
      "Atomic source contribution -test*q0 for stoichiometric conversion, wells, boundary "
      "exchange, or other sources in fluid/solid reference component balances.");
  params.addRequiredParam<MaterialPropertyName>("reference_source_name",
                                                 "AD source per solid reference volume.");
  params.addParam<Real>("scale", 1.0, "Signed source multiplier.");
  return params;
}

ADReferenceComponentSourceTerm::ADReferenceComponentSourceTerm(
    const InputParameters & parameters)
  : ADKernelValue(parameters),
    _reference_source(getADMaterialProperty<Real>("reference_source_name")),
    _scale(getParam<Real>("scale"))
{
}

ADReal
ADReferenceComponentSourceTerm::precomputeQpResidual()
{
  return -_scale * _reference_source[_qp];
}
