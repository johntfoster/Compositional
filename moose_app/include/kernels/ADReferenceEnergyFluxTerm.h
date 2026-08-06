#pragma once

#include "ADKernel.h"

/** Atomic weak-divergence term for an energy flux already pulled to the solid reference. */
class ADReferenceEnergyFluxTerm : public ADKernel
{
public:
  static InputParameters validParams();
  ADReferenceEnergyFluxTerm(const InputParameters & parameters);

protected:
  ADReal computeQpResidual() override;

  const ADMaterialProperty<RealVectorValue> & _flux;
  const Real _scale;
};
