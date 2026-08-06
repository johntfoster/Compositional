#pragma once

#include "ADKernelValue.h"
#include "RankTwoTensor.h"

/** Atomic open-system momentum insertion by one conversion mechanism. */
class ADPhaseMomentumConversionInsertionTerm : public ADKernelValue {
public:
  static InputParameters validParams();
  ADPhaseMomentumConversionInsertionTerm(const InputParameters &parameters);

protected:
  ADReal precomputeQpResidual() override;

  const unsigned int _component;
  const ADVariableValue &_rate;
  const Real _rate_scale;
  const ADVariableGradient &_tau_gradient;
  const ADVariableGradient *_tau_enrichment_gradient;
  const ADVariableValue *_phase_velocity_component;
  std::vector<const ADVariableValue *> _solid_displacement_dot;
  const ADMaterialProperty<Real> &_J;
  const ADMaterialProperty<RankTwoTensor> &_F_inv;
  const ADMaterialProperty<RankTwoTensor> *_F;
  const ADMaterialProperty<RealVectorValue> *_reference_relative_velocity;
};
