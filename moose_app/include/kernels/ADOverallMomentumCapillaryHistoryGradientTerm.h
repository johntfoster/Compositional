#pragma once

#include "ADKernelValue.h"
#include "RankTwoTensor.h"

/** Atomic capillary-history-gradient force for an arbitrary number of history coordinates. */
class ADOverallMomentumCapillaryHistoryGradientTerm : public ADKernelValue
{
public:
  static InputParameters validParams();
  ADOverallMomentumCapillaryHistoryGradientTerm(const InputParameters & parameters);

protected:
  ADReal precomputeQpResidual() override;

  const unsigned int _component;
  std::vector<const ADVariableGradient *> _history_gradients;
  std::vector<const ADMaterialProperty<Real> *> _surface_energy_history_derivatives;
  const ADVariableValue & _fluid_fraction;
  const ADMaterialProperty<Real> & _J;
  const ADMaterialProperty<RankTwoTensor> & _F_inv;
};
