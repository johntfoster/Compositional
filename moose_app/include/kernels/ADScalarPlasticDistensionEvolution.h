#pragma once

#include "ADTimeKernel.h"

/** Scalar associated plastic-distension evolution dot(a_p)/a_p=L_A tr(sigma')/3. */
class ADScalarPlasticDistensionEvolution : public ADTimeKernel
{
public:
  static InputParameters validParams();
  ADScalarPlasticDistensionEvolution(const InputParameters & parameters);

protected:
  ADReal computeQpResidual() override;

  const ADMaterialProperty<Real> & _plastic_distension_log_rate;
};
