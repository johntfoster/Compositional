#pragma once

#include "NodalScalarKernel.h"

class Function;

/**
 * Enforces one rate/BHP complementarity equation for several completion
 * blocks sharing a datum BHP. Each completion contributes its own rate,
 * productivity, boundary-node set, and pressure Jacobian weight.
 */
class BlackOilMultiCompletionWellControl : public NodalScalarKernel
{
public:
  static InputParameters validParams();
  BlackOilMultiCompletionWellControl(const InputParameters & parameters);

  void computeResidual() override;
  void computeJacobian() override;

protected:
  Real computeQpResidual() override { return 0.0; }
  Real computeQpJacobian() override { return 0.0; }

  void residualDerivatives(Real & residual,
                           Real & derivative_rate,
                           Real & derivative_bhp) const;

  const unsigned int _pressure_var;
  const VariableValue & _pressure;
  std::vector<const PostprocessorValue *> _surface_rates;
  std::vector<const PostprocessorValue *> _surface_productivities;
  std::vector<std::vector<Real>> _completion_pressure_weights;
  const Real _target_surface_rate;
  const Function * _target_surface_rate_function;
  const bool _apply_bhp_limit;
  const MooseEnum _bhp_limit_type;
  const Real _bhp_limit;
};


