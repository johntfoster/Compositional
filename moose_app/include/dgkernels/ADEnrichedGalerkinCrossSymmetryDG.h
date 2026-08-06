#pragma once

#include "ADDGKernel.h"
#include "RankTwoTensor.h"

/** Off-diagonal component-block adjoint term for a continuous EG backbone row. */
class ADEnrichedGalerkinCrossSymmetryDG : public ADDGKernel
{
public:
  static InputParameters validParams();
  ADEnrichedGalerkinCrossSymmetryDG(const InputParameters & parameters);

protected:
  ADReal computeQpResidual(Moose::DGResidualType type) override;

  const ADVariableValue & _column_enrichment;
  const ADVariableValue & _column_enrichment_neighbor;
  const ADMaterialProperty<RankTwoTensor> & _mobility;
  const ADMaterialProperty<RankTwoTensor> & _mobility_neighbor;
  const Real _epsilon;
};
