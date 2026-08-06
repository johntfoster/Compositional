#pragma once

#include "ADKernelValue.h"

class Function;

/** Atomic prescribed current-volume momentum source, primarily for loads and MMS. */
class ADPhaseMomentumFunctionSourceTerm : public ADKernelValue
{
public:
  static InputParameters validParams();
  ADPhaseMomentumFunctionSourceTerm(const InputParameters & parameters);

protected:
  ADReal precomputeQpResidual() override;

  const Function & _source;
  const ADMaterialProperty<Real> & _J;
  const Real _scale;
};
