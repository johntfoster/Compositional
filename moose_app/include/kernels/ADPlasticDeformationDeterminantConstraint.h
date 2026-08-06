#pragma once

#include "ADKernelValue.h"

/** Enforces det(Fbar_p)=1 in a selected component equation. */
class ADPlasticDeformationDeterminantConstraint : public ADKernelValue
{
public:
  static InputParameters validParams();
  ADPlasticDeformationDeterminantConstraint(const InputParameters & parameters);

protected:
  ADReal precomputeQpResidual() override;

  const unsigned int _dim;
  std::vector<const ADVariableValue *> _plastic_deformation_components;
  const Real _target_determinant;
};
