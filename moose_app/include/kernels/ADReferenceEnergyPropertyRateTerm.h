#pragma once

#include "ADKernelValue.h"

/** Atomic J*a*r energy term when the state rate r is supplied as an AD property. */
class ADReferenceEnergyPropertyRateTerm : public ADKernelValue
{
public:
  static InputParameters validParams();

  ADReferenceEnergyPropertyRateTerm(const InputParameters & parameters);

protected:
  ADReal precomputeQpResidual() override;

  const ADMaterialProperty<Real> & _rate;
  const ADMaterialProperty<Real> & _coefficient;
  const ADMaterialProperty<Real> & _J;
  const Real _scale;
  const bool _multiply_by_J;
};
