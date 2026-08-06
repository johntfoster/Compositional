#pragma once

#include "ADKernelValue.h"

/** Atomic current-volume vector source pulled back with J. */
class ADPhaseMomentumVectorSourceTerm : public ADKernelValue
{
public:
  static InputParameters validParams();
  ADPhaseMomentumVectorSourceTerm(const InputParameters & parameters);

protected:
  ADReal precomputeQpResidual() override;

  const unsigned int _component;
  const ADMaterialProperty<RealVectorValue> & _source;
  const ADMaterialProperty<Real> & _J;
  const Real _scale;
};
