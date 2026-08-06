#pragma once

#include "FVElementalKernel.h"

/** Cell-centered residual supplied by an AD scalar material property. */
class FVMaterialPropertyResidual : public FVElementalKernel
{
public:
  static InputParameters validParams();

  FVMaterialPropertyResidual(const InputParameters & parameters);

protected:
  ADReal computeQpResidual() override;

  const ADMaterialProperty<Real> & _residual_property;
};
