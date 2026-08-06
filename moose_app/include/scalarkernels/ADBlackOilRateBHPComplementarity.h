#pragma once

#include "ADScalarKernel.h"

class Function;

/**
 * Relates a shared surface-rate scalar to its schedule and an optional datum
 * BHP limit through a Fischer--Burmeister complementarity equation.
 */
class ADBlackOilRateBHPComplementarity : public ADScalarKernel
{
public:
  static InputParameters validParams();
  ADBlackOilRateBHPComplementarity(const InputParameters & parameters);

protected:
  ADReal computeQpResidual() override;

  const ADVariableValue & _well_rate;
  const Real _target_surface_rate;
  const Function * _target_surface_rate_function;
  const bool _apply_bhp_limit;
  const MooseEnum _bhp_limit_type;
  const Real _bhp_limit;
};
