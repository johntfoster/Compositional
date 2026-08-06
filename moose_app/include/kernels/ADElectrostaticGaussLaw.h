#pragma once

#include "ADKernel.h"

/** Atomic solid-reference Gauss-law equation. */
class ADElectrostaticGaussLaw : public ADKernel
{
public:
  static InputParameters validParams();
  ADElectrostaticGaussLaw(const InputParameters & parameters);

protected:
  ADReal computeQpResidual() override;

  const ADMaterialProperty<RealVectorValue> & _reference_electric_displacement;
  const ADMaterialProperty<Real> & _reference_free_charge;
};
