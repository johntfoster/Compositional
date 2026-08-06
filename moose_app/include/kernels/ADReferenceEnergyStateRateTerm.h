#pragma once

#include "ADKernelValue.h"

/** Atomic coefficient times the time rate of an independently coupled state variable. */
class ADReferenceEnergyStateRateTerm : public ADKernelValue
{
public:
  static InputParameters validParams();
  ADReferenceEnergyStateRateTerm(const InputParameters & parameters);

protected:
  ADReal precomputeQpResidual() override;

  const ADVariableValue & _state_dot;
  const ADMaterialProperty<Real> & _coefficient;
  const ADMaterialProperty<Real> & _J;
  const Real _scale;
  const bool _multiply_by_J;
};
