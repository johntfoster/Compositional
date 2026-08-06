#pragma once

#include "ADTimeKernel.h"

/** Rate form dot(a)/a = dot(J)/J + dot(rhobar)/rhobar on the solid reference. */
class ADSolidDistensionEvolution : public ADTimeKernel
{
public:
  static InputParameters validParams();
  ADSolidDistensionEvolution(const InputParameters & parameters);

protected:
  ADReal computeQpResidual() override;

  const ADMaterialProperty<Real> & _solid_jacobian;
  const ADMaterialProperty<Real> & _solid_jacobian_dot;
  const ADVariableValue & _intrinsic_density;
  const ADVariableValue & _intrinsic_density_dot;
  const Function & _forcing;
};
