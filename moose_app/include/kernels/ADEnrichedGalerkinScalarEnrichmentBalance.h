#pragma once

#include "ADTimeKernel.h"

class Function;

class ADEnrichedGalerkinScalarEnrichmentBalance : public ADTimeKernel
{
public:
  static InputParameters validParams();

  ADEnrichedGalerkinScalarEnrichmentBalance(const InputParameters & parameters);

protected:
  ADReal computeQpResidual() override;

  const ADVariableValue & _backbone_dot;
  const Real _time_coefficient;
  const ADMaterialProperty<Real> * _time_coefficient_property;
  const ADMaterialProperty<Real> * _reference_component_storage_rate;
  const ADMaterialProperty<Real> * _source;
  const Function & _source_function;
  const Real _anchor_coefficient;
  const Real _anchor_value;
};
