#pragma once

#include "RankTwoTensor.h"
#include "SideIntegralPostprocessor.h"

class Function;

/** Integrates the numerical outward flux used by ADEnrichedGalerkinPenaltyBC. */
class ADEnrichedGalerkinBoundaryFluxIntegral : public SideIntegralPostprocessor
{
public:
  static InputParameters validParams();

  ADEnrichedGalerkinBoundaryFluxIntegral(const InputParameters & parameters);

protected:
  Real computeQpIntegral() override;

  const ADVariableValue & _backbone;
  const ADVariableValue & _enrichment;
  const ADMaterialProperty<RealVectorValue> & _reference_flux;
  const ADMaterialProperty<RankTwoTensor> & _mobility;
  const Real _value;
  const Function * _function;
  const Real _sigma;
  const bool _absolute_mobility_penalty;
};
