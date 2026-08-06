#pragma once

#include "Material.h"

/**
 * Isothermal single-component fluid storage in the solid reference.
 *
 * For fluid volume fraction 1-phi_s and gauge pressure p, the object supports
 * either the isothermal ideal-gas law rho_f=rho_f0(1+p/p_0) or the
 * constant-bulk-modulus law rho_f=rho_f0 exp(p/K_f).  It returns both
 * J_s(1-phi_s)rho_f and its fully AD-valued material time rate.
 */
class ADBinaryFluidStorageMaterial : public Material
{
public:
  static InputParameters validParams();

  ADBinaryFluidStorageMaterial(const InputParameters & parameters);

protected:
  void initQpStatefulProperties() override;
  void computeQpProperties() override;

  const ADMaterialProperty<Real> & _J;
  const ADMaterialProperty<Real> & _J_dot;
  const ADMaterialProperty<Real> & _pressure;
  const ADMaterialProperty<Real> & _pressure_dot;
  const ADVariableValue & _solid_volume_fraction;
  const ADVariableValue & _solid_volume_fraction_dot;
  const MooseEnum _fluid_eos;
  const Real _reference_density;
  const Real _reference_absolute_pressure;
  const Real _bulk_modulus;

  ADMaterialProperty<Real> & _intrinsic_density;
  ADMaterialProperty<Real> & _reference_component_accumulation;
  const MaterialProperty<Real> & _reference_component_accumulation_old;
  ADMaterialProperty<Real> & _reference_component_storage_rate;
};
