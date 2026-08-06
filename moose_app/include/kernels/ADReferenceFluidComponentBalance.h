#pragma once

#include "ADTimeKernel.h"

class ADReferenceFluidComponentBalance : public ADTimeKernel
{
public:
  static InputParameters validParams();

  ADReferenceFluidComponentBalance(const InputParameters & parameters);

protected:
  ADReal computeQpResidual() override;

  const ADMaterialProperty<RealVectorValue> & _reference_component_flux;
  const ADMaterialProperty<Real> & _reference_component_source;
};
