#pragma once

#include "ADIntegratedBC.h"
#include "RankTwoTensor.h"

class Function;

/** Off-diagonal component-block weak Dirichlet term for an EG enrichment row. */
class ADEnrichedGalerkinCrossPenaltyBC : public ADIntegratedBC
{
public:
  static InputParameters validParams();
  ADEnrichedGalerkinCrossPenaltyBC(const InputParameters & parameters);

protected:
  ADReal computeQpResidual() override;

  const ADVariableValue & _column_backbone;
  const ADVariableValue & _column_enrichment;
  const ADMaterialProperty<RankTwoTensor> & _mobility;
  const Real _value;
  const Function * _function;
  const Real _epsilon;
  const Real _sigma;
};
