#pragma once

#include "ADKernelValue.h"
#include "RankTwoTensor.h"

/** Atomic +test*J*phi_f*F^{-T}Grad_X(p_f-omega_f^+) phase-pressure force. */
class ADPhaseMomentumPressurePotentialGradientTerm : public ADKernelValue
{
public:
  static InputParameters validParams();
  ADPhaseMomentumPressurePotentialGradientTerm(const InputParameters & parameters);

protected:
  ADReal precomputeQpResidual() override;

  const unsigned int _component;
  const ADMaterialProperty<RealVectorValue> & _reference_pressure_potential_gradient;
  const ADVariableValue * _coefficient_variable;
  const ADMaterialProperty<Real> * _coefficient_property;
  const Real _coefficient;
  const Real _scale;
  const ADMaterialProperty<Real> & _J;
  const ADMaterialProperty<RankTwoTensor> & _F_inv;
};
