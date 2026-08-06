#pragma once

#include "ADKernelValue.h"
#include "RankTwoTensor.h"

/** Atomic sum of dissipative saturation-gradient pressure-lag forces. */
class ADOverallMomentumDynamicPressureLagTerm : public ADKernelValue
{
public:
  static InputParameters validParams();
  ADOverallMomentumDynamicPressureLagTerm(const InputParameters & parameters);

protected:
  ADReal precomputeQpResidual() override;

  const unsigned int _component;
  std::vector<const ADVariableGradient *> _saturation_gradients;
  std::vector<const ADMaterialProperty<Real> *> _pressure_lags;
  const ADVariableValue & _fluid_fraction;
  const ADMaterialProperty<Real> & _J;
  const ADMaterialProperty<RankTwoTensor> & _F_inv;
};
