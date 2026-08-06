#include "ADReferenceMaterialStorageRateTerm.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADReferenceMaterialStorageRateTerm);

InputParameters
ADReferenceMaterialStorageRateTerm::validParams()
{
  InputParameters params = ADKernelValue::validParams();
  params.addClassDescription(
      "Atomic test*d(M_ref)/dt term for nonlinear material-computed reference storage.");
  params.addRequiredParam<MaterialPropertyName>(
      "reference_storage_rate_name", "AD material property d(M_ref)/dt.");
  params.addParam<Real>("scale", 1.0, "Signed multiplier.");
  return params;
}

ADReferenceMaterialStorageRateTerm::ADReferenceMaterialStorageRateTerm(
    const InputParameters & parameters)
  : ADKernelValue(parameters),
    _storage_rate(getADMaterialProperty<Real>("reference_storage_rate_name")),
    _scale(getParam<Real>("scale"))
{
}

ADReal
ADReferenceMaterialStorageRateTerm::precomputeQpResidual()
{
  return _scale * _storage_rate[_qp];
}
