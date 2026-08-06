#pragma once

#include "Material.h"

/**
 * Source-free single-component solid spatial mass pulled to the solid reference.
 *
 * The conserved storage is J_s phi_s rhobar_s. The material exposes the
 * storage and its complete AD material time rate without imposing a separate
 * intrinsic-density or volume-fraction constitutive law.
 */
class ADBinarySolidSpatialMassMaterial : public Material
{
public:
  static InputParameters validParams();

  ADBinarySolidSpatialMassMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;

  const ADMaterialProperty<Real> & _J;
  const ADMaterialProperty<Real> & _J_dot;
  const ADVariableValue & _solid_volume_fraction;
  const ADVariableValue & _solid_volume_fraction_dot;
  const ADVariableValue & _solid_intrinsic_density;
  const ADVariableValue & _solid_intrinsic_density_dot;

  ADMaterialProperty<Real> & _reference_component_accumulation;
  ADMaterialProperty<Real> & _reference_component_storage_rate;
};
