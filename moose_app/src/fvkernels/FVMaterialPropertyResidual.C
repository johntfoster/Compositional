#include "FVMaterialPropertyResidual.h"

registerADMooseObject("MulticomponentReactiveFlowApp", FVMaterialPropertyResidual);

InputParameters
FVMaterialPropertyResidual::validParams()
{
  InputParameters params = FVElementalKernel::validParams();
  params.addClassDescription(
      "Assembles an AD scalar material property as a cell-centered algebraic residual.");
  params.addRequiredParam<MaterialPropertyName>("property", "AD residual material property.");
  return params;
}

FVMaterialPropertyResidual::FVMaterialPropertyResidual(const InputParameters & parameters)
  : FVElementalKernel(parameters),
    _residual_property(
        getADMaterialProperty<Real>(getParam<MaterialPropertyName>("property")))
{
}

ADReal
FVMaterialPropertyResidual::computeQpResidual()
{
  return _residual_property[_qp];
}
