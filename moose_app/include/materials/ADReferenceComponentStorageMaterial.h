#pragma once

#include "Material.h"

class ADReferenceComponentStorageMaterial : public Material
{
public:
  static InputParameters validParams();

  ADReferenceComponentStorageMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;

  const ADMaterialProperty<Real> & _J;
  const ADVariableValue & _porosity;
  const ADVariableValue & _intrinsic_density;
  const ADVariableValue & _component_mass_fraction;

  ADMaterialProperty<Real> & _current_component_partial_density;
  ADMaterialProperty<Real> & _reference_component_storage;
};
