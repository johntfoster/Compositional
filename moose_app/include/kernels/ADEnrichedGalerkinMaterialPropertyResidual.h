#pragma once

#include "ADKernelValue.h"

class ADEnrichedGalerkinMaterialPropertyResidual : public ADKernelValue
{
public:
  static InputParameters validParams();

  ADEnrichedGalerkinMaterialPropertyResidual(const InputParameters & parameters);

protected:
  ADReal precomputeQpResidual() override;

  const ADMaterialProperty<Real> & _property;
  const Real _scale;
  const Real _anchor_coefficient;
  const Real _anchor_value;
};
