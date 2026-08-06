#pragma once

#include "ADKernelValue.h"

/** Atomic weak source term for conversion or externally supplied component mass. */
class ADReferenceComponentSourceTerm : public ADKernelValue
{
public:
  static InputParameters validParams();
  ADReferenceComponentSourceTerm(const InputParameters & parameters);

protected:
  ADReal precomputeQpResidual() override;

  const ADMaterialProperty<Real> & _reference_source;
  const Real _scale;
};
