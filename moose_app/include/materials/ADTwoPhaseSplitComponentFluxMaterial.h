#pragma once

#include "Material.h"

class ADTwoPhaseSplitComponentFluxMaterial : public Material
{
public:
  static InputParameters validParams();

  ADTwoPhaseSplitComponentFluxMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;

  const unsigned int _component;
  const ADMaterialProperty<RealVectorValue> & _phase0_reference_relative_mass_flux;
  const ADMaterialProperty<RealVectorValue> & _phase1_reference_relative_mass_flux;
  const ADMaterialProperty<Real> & _phase0_component_mass_fraction;
  const ADMaterialProperty<Real> & _phase1_component_mass_fraction;
  const ADMaterialProperty<Real> & _J;
  const Function & _current_component_source;

  ADMaterialProperty<RealVectorValue> & _reference_component_flux;
  ADMaterialProperty<Real> & _reference_component_source;
};
