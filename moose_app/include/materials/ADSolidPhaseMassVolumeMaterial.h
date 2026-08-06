#pragma once

#include "Material.h"

/**
 * Solid-reference matrix-component storage and phase-volume closure.
 *
 * Implements the storage and source terms of
 * Eq. (solid_reference_solid_component_balance). The intrinsic density may be
 * constant or coupled, and the conserved-storage mode reconstructs the current
 * solid fraction. An optional distension coupling reports the integrated
 * relation a_s phi_s rho_s0 = J phi_s rho_s.
 */
class ADSolidPhaseMassVolumeMaterial : public Material {
public:
  static InputParameters validParams();

  ADSolidPhaseMassVolumeMaterial(const InputParameters &parameters);

protected:
  void computeQpProperties() override;

  const ADMaterialProperty<Real> &_J;
  const ADMaterialProperty<Real> &_J_dot;
  const ADVariableValue *_solid_volume_fraction;
  const ADVariableValue *_solid_volume_fraction_dot;
  const ADVariableValue *_reference_component_storage_variable;
  const ADVariableValue *_reference_component_storage_variable_dot;
  const ADVariableValue *_fluid_volume_fraction;
  const ADVariableValue *_fluid_volume_fraction_dot;
  const Real _constant_solid_intrinsic_density;
  const ADVariableValue *_solid_intrinsic_density;
  const ADVariableValue *_solid_intrinsic_density_dot;
  const ADVariableValue *_solid_distension;
  const Real _solid_reference_intrinsic_density;
  const ADMaterialProperty<Real> *_current_component_source;

  ADMaterialProperty<Real> &_reference_component_storage;
  ADMaterialProperty<Real> &_reference_component_storage_rate;
  ADMaterialProperty<Real> &_reference_component_balance_residual;
  ADMaterialProperty<Real> &_phase_volume_constraint_residual;
  ADMaterialProperty<Real> &_current_solid_volume_fraction;
  ADMaterialProperty<Real> &_current_solid_bulk_density;
  ADMaterialProperty<Real> &_current_fluid_volume_fraction;
  ADMaterialProperty<Real> &_current_fluid_volume_fraction_rate;
  ADMaterialProperty<Real> &_current_solid_intrinsic_density;
  ADMaterialProperty<Real> &_solid_distension_mass_relation_residual;
};
