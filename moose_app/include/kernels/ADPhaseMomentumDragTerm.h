#pragma once

#include "ADKernelValue.h"

/** Atomic linear fluid-skeleton drag term. */
class ADPhaseMomentumDragTerm : public ADKernelValue
{
public:
  static InputParameters validParams();
  ADPhaseMomentumDragTerm(const InputParameters & parameters);

protected:
  ADReal precomputeQpResidual() override;

  const unsigned int _component;
  const unsigned int _dim;
  std::vector<const ADVariableValue *> _phase_velocities;
  std::vector<const ADVariableValue *> _solid_velocities;
  const ADVariableValue & _phase_fraction;
  const ADMaterialProperty<Real> & _J;
  const ADMaterialProperty<Real> * _viscosity_property;
  const ADMaterialProperty<Real> * _permeability_property;
  const Real _viscosity;
  const Real _permeability;
};
