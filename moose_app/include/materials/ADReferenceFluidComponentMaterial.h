#pragma once

#include "Material.h"
#include "RankTwoTensor.h"

class ADReferenceFluidComponentMaterial : public Material
{
public:
  static InputParameters validParams();

  ADReferenceFluidComponentMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;

  const ADMaterialProperty<Real> & _J;
  const ADMaterialProperty<RankTwoTensor> & _J_F_inv;

  const Function & _current_relative_mass_flux;
  const Function & _current_component_extra_flux;
  const Function & _component_mass_fraction;
  const Function & _current_component_source;

  ADMaterialProperty<RealVectorValue> & _reference_relative_mass_flux;
  ADMaterialProperty<RealVectorValue> & _reference_component_flux;
  ADMaterialProperty<Real> & _reference_component_source;
};
