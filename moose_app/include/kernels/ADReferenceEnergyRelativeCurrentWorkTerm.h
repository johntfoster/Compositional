#pragma once

#include "ADKernelValue.h"
#include "RankTwoTensor.h"

/** Atomic gauge-invariant work of the electric field on relative charge current. */
class ADReferenceEnergyRelativeCurrentWorkTerm : public ADKernelValue
{
public:
  static InputParameters validParams();
  ADReferenceEnergyRelativeCurrentWorkTerm(const InputParameters & parameters);

protected:
  ADReal precomputeQpResidual() override;

  const ADMaterialProperty<RealVectorValue> & _relative_charge_current;
  const ADVariableGradient & _electric_potential_gradient;
  const ADMaterialProperty<RankTwoTensor> & _F_inv;
  const ADMaterialProperty<Real> & _J;
  const Real _scale;
};
