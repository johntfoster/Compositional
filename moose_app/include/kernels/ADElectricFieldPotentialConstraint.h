#pragma once

#include "ADKernelValue.h"
#include "RankTwoTensor.h"

/** One component of E + F^{-T} Grad_X(varphi) = 0. */
class ADElectricFieldPotentialConstraint : public ADKernelValue
{
public:
  static InputParameters validParams();
  ADElectricFieldPotentialConstraint(const InputParameters & parameters);

protected:
  ADReal precomputeQpResidual() override;

  const unsigned int _component;
  const ADVariableGradient & _potential_gradient;
  const ADMaterialProperty<RankTwoTensor> & _F_inv;
};
