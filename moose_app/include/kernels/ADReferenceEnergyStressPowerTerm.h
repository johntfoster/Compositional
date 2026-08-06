#pragma once

#include "ADKernelValue.h"
#include "RankTwoTensor.h"

/** Atomic phase stress power J sigma:L in a thermal-subsystem balance. */
class ADReferenceEnergyStressPowerTerm : public ADKernelValue
{
public:
  static InputParameters validParams();
  ADReferenceEnergyStressPowerTerm(const InputParameters & parameters);

protected:
  ADReal precomputeQpResidual() override;

  const unsigned int _dim;
  std::vector<const ADVariableGradient *> _velocity_gradients;
  const ADMaterialProperty<RankTwoTensor> & _cauchy_stress;
  const ADMaterialProperty<RankTwoTensor> & _F_inv;
  const ADMaterialProperty<Real> & _J;
  const Real _scale;
};
