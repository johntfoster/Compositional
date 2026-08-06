#pragma once

#include "ADTimeKernel.h"

class Function;

class ADEnrichedGalerkinScalarBalance : public ADTimeKernel
{
public:
  static InputParameters validParams();

  ADEnrichedGalerkinScalarBalance(const InputParameters & parameters);

protected:
  ADReal computeQpResidual() override;

  const ADVariableValue * _enrichment_dot;
  const Real _time_coefficient;
  const ADMaterialProperty<Real> * _time_coefficient_property;
  const ADMaterialProperty<Real> * _reference_component_storage_rate;
  const ADMaterialProperty<Real> * _source;
  const Function & _source_function;
  const ADMaterialProperty<RealVectorValue> * _reference_flux;
};
