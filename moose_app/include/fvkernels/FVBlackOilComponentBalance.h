#pragma once

#include "FVElementalKernel.h"

/** Cell-centered black-oil component storage and source residual. */
class FVBlackOilComponentBalance : public FVElementalKernel
{
public:
  static InputParameters validParams();

  FVBlackOilComponentBalance(const InputParameters & parameters);

protected:
  ADReal computeQpResidual() override;

  const ADMaterialProperty<Real> & _reference_component_storage_rate;
  const ADMaterialProperty<Real> & _reference_component_source;
};
