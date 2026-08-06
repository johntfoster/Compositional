#pragma once

#include "Material.h"

/** Computes the solid-reference relative transport velocity c = W/(J rho_bulk). */
class ADReferenceRelativeVelocityMaterial : public Material
{
public:
  static InputParameters validParams();

  ADReferenceRelativeVelocityMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;

  const ADMaterialProperty<RealVectorValue> & _reference_relative_mass_flux;
  const ADMaterialProperty<Real> & _J;
  const ADMaterialProperty<Real> & _bulk_density;
  const ADMaterialProperty<Real> * _phase_active;
  const Real _active_tolerance;
  const bool _deactivate_on_nonpositive_mass;
  ADMaterialProperty<RealVectorValue> & _reference_relative_velocity;
};
