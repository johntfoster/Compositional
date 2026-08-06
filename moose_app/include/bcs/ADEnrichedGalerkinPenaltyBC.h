#pragma once

#include "ADIntegratedBC.h"

class ADEnrichedGalerkinPenaltyBC : public ADIntegratedBC
{
public:
  static InputParameters validParams();

  ADEnrichedGalerkinPenaltyBC(const InputParameters & parameters);

protected:
  ADReal computeQpResidual() override;

  const ADVariableValue & _backbone;
  const ADMaterialProperty<RealVectorValue> & _reference_flux;
  const ADMaterialProperty<RankTwoTensor> & _mobility;
  const Real _value;
  const Function * _function;
  const Real _epsilon;
  const Real _sigma;
  const bool _absolute_mobility_penalty;
};
