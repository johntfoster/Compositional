#pragma once

#include "ADDGKernel.h"

class ADEnrichedGalerkinSymmetryDG : public ADDGKernel
{
public:
  static InputParameters validParams();

  ADEnrichedGalerkinSymmetryDG(const InputParameters & parameters);

protected:
  ADReal computeQpResidual(Moose::DGResidualType type) override;

  const ADVariableValue & _enrichment;
  const ADVariableValue & _enrichment_neighbor;
  const ADMaterialProperty<RankTwoTensor> & _mobility;
  const ADMaterialProperty<RankTwoTensor> & _mobility_neighbor;
  const Real _epsilon;
};
