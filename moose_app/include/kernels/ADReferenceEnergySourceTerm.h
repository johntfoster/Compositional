#pragma once

#include "ADKernelValue.h"

/** Atomic energy source or local power term. */
class ADReferenceEnergySourceTerm : public ADKernelValue
{
public:
  static InputParameters validParams();
  ADReferenceEnergySourceTerm(const InputParameters & parameters);

protected:
  ADReal precomputeQpResidual() override;

  const ADMaterialProperty<Real> & _source;
  const ADMaterialProperty<Real> & _J;
  const Real _scale;
  const bool _multiply_by_J;
};
