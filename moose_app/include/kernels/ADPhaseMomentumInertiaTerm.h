#pragma once

#include "ADTimeKernel.h"
#include "RankTwoTensor.h"

/** Atomic phase inertia: J rho [dot(v_i)+F^{-1}(v-v_s).Grad_X(v_i)]. */
class ADPhaseMomentumInertiaTerm : public ADTimeKernel
{
public:
  static InputParameters validParams();
  ADPhaseMomentumInertiaTerm(const InputParameters & parameters);

protected:
  ADReal computeQpResidual() override;

  const unsigned int _component;
  const unsigned int _dim;
  std::vector<const ADVariableValue *> _phase_velocities;
  std::vector<const ADVariableValue *> _solid_velocities;
  const ADVariableValue & _bulk_density;
  const ADMaterialProperty<Real> & _J;
  const ADMaterialProperty<RankTwoTensor> & _F_inv;
};
