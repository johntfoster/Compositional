#pragma once

#include "ADDGKernel.h"
#include "RankTwoTensor.h"

/** Off-diagonal component-block penalty and adjoint term for an EG enrichment row. */
class ADEnrichedGalerkinCrossFluxDG : public ADDGKernel
{
public:
  static InputParameters validParams();
  ADEnrichedGalerkinCrossFluxDG(const InputParameters & parameters);

protected:
  ADReal computeQpResidual(Moose::DGResidualType type) override;

  const ADVariableValue & _column_enrichment;
  const ADVariableValue & _column_enrichment_neighbor;
  const ADMaterialProperty<RankTwoTensor> & _mobility;
  const ADMaterialProperty<RankTwoTensor> & _mobility_neighbor;
  const Real _epsilon;
  const Real _sigma;
};
