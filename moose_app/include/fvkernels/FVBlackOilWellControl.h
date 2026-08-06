#pragma once

#include "FVElementalKernel.h"

class MooseVariableScalar;

/** One-cell FV completion equation for a shared scalar bottom-hole pressure. */
class FVBlackOilWellControl : public FVElementalKernel
{
public:
  static InputParameters validParams();

  FVBlackOilWellControl(const InputParameters & parameters);

  void computeResidual() override;
  void computeJacobian() override;
  void computeOffDiagJacobian() override;
  void computeResidualAndJacobian() override;

protected:
  ADReal computeQpResidual() override { return 0.0; }
  ADReal controlResidual() const;

  const MooseVariableScalar & _bhp_var;
  const ADVariableValue & _bhp;
  const ADMaterialProperty<Real> & _surface_rate;
  const Real _target_surface_rate;
  const bool _apply_bhp_limit;
  const MooseEnum _bhp_limit_type;
  const Real _bhp_limit;
};
