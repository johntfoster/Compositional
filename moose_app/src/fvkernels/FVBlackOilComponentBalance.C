#include "FVBlackOilComponentBalance.h"

registerADMooseObject("MulticomponentReactiveFlowApp", FVBlackOilComponentBalance);

InputParameters
FVBlackOilComponentBalance::validParams()
{
  InputParameters params = FVElementalKernel::validParams();
  params.addClassDescription(
      "Assembles the cell-centered reference component storage rate minus its reference source.");
  params.addRequiredParam<MaterialPropertyName>(
      "reference_component_storage_rate_name", "AD reference component storage-rate property.");
  params.addRequiredParam<MaterialPropertyName>(
      "reference_component_source_name", "AD reference component source property.");
  return params;
}

FVBlackOilComponentBalance::FVBlackOilComponentBalance(const InputParameters & parameters)
  : FVElementalKernel(parameters),
    _reference_component_storage_rate(getADMaterialProperty<Real>(
        getParam<MaterialPropertyName>("reference_component_storage_rate_name"))),
    _reference_component_source(getADMaterialProperty<Real>(
        getParam<MaterialPropertyName>("reference_component_source_name")))
{
}

ADReal
FVBlackOilComponentBalance::computeQpResidual()
{
  return _reference_component_storage_rate[_qp] - _reference_component_source[_qp];
}
