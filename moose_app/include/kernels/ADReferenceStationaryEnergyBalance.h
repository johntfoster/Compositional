#pragma once

#include "ADKernel.h"

/** Weak residual of -Div_X(Q) + J w_E + J rho r = 0. */
class ADReferenceStationaryEnergyBalance : public ADKernel
{
public:
  static InputParameters validParams();

  ADReferenceStationaryEnergyBalance(const InputParameters & parameters);

protected:
  ADReal computeQpResidual() override;

  const ADMaterialProperty<RealVectorValue> & _reference_heat_flux;
  const ADMaterialProperty<Real> & _reference_electric_work;
  const ADMaterialProperty<Real> & _reference_heat_supply;
};
