#pragma once

#include "ADKernelScalarBase.h"

/**
 * Integrates one completion's AD surface rate into a shared scalar well-rate
 * equation. The object assembles only the scalar row; its element loop retains
 * derivatives with respect to every CG/EG field used by the rate material.
 */
class ADBlackOilCompletionRateConstraint : public ADKernelScalarBase
{
public:
  static InputParameters validParams();
  ADBlackOilCompletionRateConstraint(const InputParameters & parameters);

protected:
  ADReal computeQpResidual() override { return 0.0; }
  ADReal computeScalarQpResidual() override;

  const ADMaterialProperty<Real> & _surface_rate;
  const Real _completion_reference_volume;
  const Real _well_rate_fraction;
};
