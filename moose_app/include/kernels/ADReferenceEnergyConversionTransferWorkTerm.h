#pragma once

#include "ADKernelValue.h"

/** Atomic -sum_alpha L_xi^alpha dot(c)_xi^alpha conversion work. */
class ADReferenceEnergyConversionTransferWorkTerm : public ADKernelValue
{
public:
  static InputParameters validParams();
  ADReferenceEnergyConversionTransferWorkTerm(const InputParameters & parameters);

protected:
  ADReal precomputeQpResidual() override;

  std::vector<const ADMaterialProperty<Real> *> _transfer_works;
  std::vector<const ADMaterialProperty<Real> *> _component_sources;
  const ADMaterialProperty<Real> & _J;
  const Real _scale;
};
