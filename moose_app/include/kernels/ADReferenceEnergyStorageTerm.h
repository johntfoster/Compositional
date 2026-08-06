#pragma once

#include "ADTimeKernel.h"

/** Atomic solid-reference conservative energy storage term. */
class ADReferenceEnergyStorageTerm : public ADTimeKernel
{
public:
  static InputParameters validParams();
  ADReferenceEnergyStorageTerm(const InputParameters & parameters);

protected:
  ADReal computeQpResidual() override;

  const Real _coefficient;
  const ADMaterialProperty<Real> * _coefficient_property;
  const ADMaterialProperty<Real> & _J;
  const bool _multiply_by_J;
};
