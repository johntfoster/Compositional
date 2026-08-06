#pragma once

#include "ADKernel.h"
#include "RankTwoTensor.h"

/** Atomic weak divergence of a reference Piola stress. */
class ADPhaseMomentumStressTerm : public ADKernel
{
public:
  static InputParameters validParams();
  ADPhaseMomentumStressTerm(const InputParameters & parameters);

protected:
  ADReal computeQpResidual() override;

  const unsigned int _component;
  const ADMaterialProperty<RankTwoTensor> & _piola_stress;
  const Real _scale;
};
