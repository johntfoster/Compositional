#include "ADReferenceVectorMaterialSourceTerm.h"
registerMooseObject("MulticomponentReactiveFlowApp", ADReferenceVectorMaterialSourceTerm);
InputParameters ADReferenceVectorMaterialSourceTerm::validParams()
{
  InputParameters params = ADKernelValue::validParams();
  params.addClassDescription("Adds the -J test b_i residual for a current-volume vector source.");
  params.addRequiredRangeCheckedParam<unsigned int>("component", "component<3", "Vector component.");
  params.addRequiredParam<MaterialPropertyName>("source_name", "Current-volume vector source b.");
  params.addParam<MaterialPropertyName>("solid_jacobian_name", "solid_reference_J", "J.");
  return params;
}
ADReferenceVectorMaterialSourceTerm::ADReferenceVectorMaterialSourceTerm(const InputParameters & p)
  : ADKernelValue(p), _component(getParam<unsigned int>("component")),
    _J(getADMaterialProperty<Real>("solid_jacobian_name")),
    _source(getADMaterialProperty<RealVectorValue>("source_name")) {}
ADReal ADReferenceVectorMaterialSourceTerm::precomputeQpResidual()
{
  return -_J[_qp] * _source[_qp](_component);
}
