#pragma once

#include "ADDGKernel.h"

class ADEnrichedGalerkinFluxDG : public ADDGKernel
{
public:
  static InputParameters validParams();

  ADEnrichedGalerkinFluxDG(const InputParameters & parameters);

protected:
  ADReal computeQpResidual(Moose::DGResidualType type) override;

  const ADMaterialProperty<RealVectorValue> & _reference_flux;
  const ADMaterialProperty<RealVectorValue> & _reference_flux_neighbor;
  const ADMaterialProperty<RankTwoTensor> & _mobility;
  const ADMaterialProperty<RankTwoTensor> & _mobility_neighbor;
  const Real _epsilon;
  const Real _sigma;
  const bool _absolute_mobility_penalty;
};
