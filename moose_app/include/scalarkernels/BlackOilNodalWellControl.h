#pragma once

#include "NodalScalarKernel.h"

/** Enforces one shared well BHP from completion-node pressure and an averaged productivity. */
class BlackOilNodalWellControl : public NodalScalarKernel
{
public:
  static InputParameters validParams();

  BlackOilNodalWellControl(const InputParameters & parameters);

  void computeResidual() override;
  void computeJacobian() override;

protected:
  Real computeQpResidual() override { return 0.0; }
  Real computeQpJacobian() override { return 0.0; }

  void residualDerivatives(Real & residual, Real & derivative_rate, Real & derivative_bhp) const;

  const unsigned int _pressure_var;
  const VariableValue & _pressure;
  const PostprocessorValue & _surface_rate;
  const PostprocessorValue & _surface_productivity;
  const Real _target_surface_rate;
  const bool _apply_bhp_limit;
  const MooseEnum _bhp_limit_type;
  const Real _bhp_limit;
};
