#pragma once

#include "Material.h"

/**
 * Couples a temperature-weighted reaction rate and physical inter-subsystem
 * reaction-energy transfer through a symmetric positive-semidefinite Onsager block.
 */
class ADReactionEnergyOnsagerMaterial : public Material
{
public:
  static InputParameters validParams();

  ADReactionEnergyOnsagerMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;

  MaterialPropertyName prefixedName(const std::string & suffix) const;

  const ADMaterialProperty<Real> & _reaction_force;
  const ADMaterialProperty<Real> & _fluid_temperature;
  const ADMaterialProperty<Real> & _solid_temperature;
  const ADVariableValue & _reaction_rate;
  const ADVariableValue & _reaction_energy_transfer_rate;

  const Real _L_00;
  const Real _L_01;
  const Real _L_11;
  const Real _determinant;
  const std::string _property_prefix;

  ADMaterialProperty<Real> & _energy_force;
  ADMaterialProperty<Real> & _predicted_reaction_rate;
  ADMaterialProperty<Real> & _predicted_reaction_energy_transfer_rate;
  ADMaterialProperty<Real> & _actual_reaction_energy_transfer_rate;
  ADMaterialProperty<Real> & _reaction_rate_residual;
  ADMaterialProperty<Real> & _reaction_energy_transfer_rate_residual;
  ADMaterialProperty<Real> & _reaction_entropy_production;
  ADMaterialProperty<Real> & _reaction_energy_entropy_production;
  ADMaterialProperty<Real> & _total_entropy_production;
  ADMaterialProperty<Real> & _onsager_quadratic_dissipation;
  ADMaterialProperty<Real> & _onsager_determinant;
};

