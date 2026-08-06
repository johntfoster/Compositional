#pragma once

#include "ADKernel.h"
#include "RankTwoTensor.h"

/** Atomic J*a*F^{-T}Grad_X(q) force term with optional EG enrichment. */
class ADPhaseMomentumScalarGradientTerm : public ADKernel
{
public:
  static InputParameters validParams();
  ADPhaseMomentumScalarGradientTerm(const InputParameters & parameters);

protected:
  ADReal computeQpResidual() override;

  const unsigned int _component;
  const ADVariableGradient & _gradient;
  const ADVariableGradient * _enrichment_gradient;
  const ADVariableValue * _coefficient_variable;
  const ADMaterialProperty<Real> * _coefficient_property;
  const Real _coefficient;
  const Real _scale;
  const ADMaterialProperty<Real> & _J;
  const ADMaterialProperty<RankTwoTensor> & _F_inv;
};
