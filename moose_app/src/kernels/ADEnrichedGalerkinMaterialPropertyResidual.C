#include "ADEnrichedGalerkinMaterialPropertyResidual.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADEnrichedGalerkinMaterialPropertyResidual);

InputParameters
ADEnrichedGalerkinMaterialPropertyResidual::validParams()
{
  InputParameters params = ADKernelValue::validParams();
  params.addClassDescription(
      "Material-property residual row for an enriched-Galerkin field. It can be applied "
      "to either the backbone or the enrichment variable; the optional anchor regularizes "
      "fluxless algebraic P0 tau reductions.");
  params.addRequiredParam<MaterialPropertyName>("property", "AD material property residual.");
  params.addParam<Real>("scale", 1.0, "Residual multiplier.");
  params.addRangeCheckedParam<Real>(
      "anchor_coefficient", 0.0, "anchor_coefficient>=0", "Optional P0 anchor coefficient.");
  params.addParam<Real>("anchor_value", 0.0, "Value used by the optional P0 anchor.");
  return params;
}

ADEnrichedGalerkinMaterialPropertyResidual::ADEnrichedGalerkinMaterialPropertyResidual(
    const InputParameters & parameters)
  : ADKernelValue(parameters),
    _property(getADMaterialProperty<Real>(getParam<MaterialPropertyName>("property"))),
    _scale(getParam<Real>("scale")),
    _anchor_coefficient(getParam<Real>("anchor_coefficient")),
    _anchor_value(getParam<Real>("anchor_value"))
{
}

ADReal
ADEnrichedGalerkinMaterialPropertyResidual::precomputeQpResidual()
{
  return _scale * _property[_qp] + _anchor_coefficient * (_u[_qp] - _anchor_value);
}
