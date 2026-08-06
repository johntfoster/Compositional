#pragma once

#include "FunctionInterface.h"
#include "Material.h"
#include "RankTwoTensor.h"

class ADReferenceFluidComponentFluxMaterial : public Material {
public:
  static InputParameters validParams();

  ADReferenceFluidComponentFluxMaterial(const InputParameters &parameters);

protected:
  void computeQpProperties() override;

  const ADMaterialProperty<Real> &_J;
  const ADMaterialProperty<RankTwoTensor> &_J_F_inv;
  const ADMaterialProperty<RealVectorValue> &_reference_relative_mass_flux;

  const Function &_component_mass_fraction;
  const bool _use_current_component_extra_flux_function;
  const Function &_current_component_extra_flux;
  const ADMaterialProperty<RealVectorValue>
      *_current_component_extra_flux_material;
  const Function &_current_component_source;

  ADMaterialProperty<RealVectorValue> &_reference_component_flux;
  ADMaterialProperty<Real> &_reference_component_source;
};
