#pragma once

#include "ADKernelValue.h"
#include "RankTwoTensor.h"

/** Atomic bulk thermocapillary source from explicit interfacial-temperature dependence. */
class ADOverallMomentumThermocapillaryTerm : public ADKernelValue
{
public:
  static InputParameters validParams();
  ADOverallMomentumThermocapillaryTerm(const InputParameters & parameters);

protected:
  ADReal precomputeQpResidual() override;

  const unsigned int _component;
  const ADVariableGradient & _temperature_gradient;
  const ADVariableValue & _fluid_fraction;
  const ADMaterialProperty<Real> & _surface_energy_temperature_derivative;
  const ADMaterialProperty<Real> & _J;
  const ADMaterialProperty<RankTwoTensor> & _F_inv;
};
