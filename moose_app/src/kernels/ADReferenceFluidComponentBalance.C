#include "ADReferenceFluidComponentBalance.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADReferenceFluidComponentBalance);

InputParameters
ADReferenceFluidComponentBalance::validParams()
{
  InputParameters params = ADTimeKernel::validParams();
  params.addClassDescription("Residual for the solid-reference fluid component balance with "
                             "storage, full reference component flux, and J-weighted source.");
  params.addParam<MaterialPropertyName>("reference_component_flux",
                                        "reference_component_flux",
                                        "Material property for the full component flux.");
  params.addParam<MaterialPropertyName>("reference_component_source",
                                        "reference_component_source",
                                        "Material property for the J-weighted component source.");
  return params;
}

ADReferenceFluidComponentBalance::ADReferenceFluidComponentBalance(
    const InputParameters & parameters)
  : ADTimeKernel(parameters),
    _reference_component_flux(getADMaterialProperty<RealVectorValue>("reference_component_flux")),
    _reference_component_source(getADMaterialProperty<Real>("reference_component_source"))
{
}

ADReal
ADReferenceFluidComponentBalance::computeQpResidual()
{
  return _test[_i][_qp] * (_u_dot[_qp] - _reference_component_source[_qp]) -
         _grad_test[_i][_qp] * _reference_component_flux[_qp];
}
