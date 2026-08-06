#pragma once

#include "Material.h"

/**
 * Exposes the absolute fluid saturation/pressure identities and the solid-phase
 * Legendre/equivalent-pressure identities as independently named AD properties.
 */
class ADPhaseThermodynamicIdentityMaterial : public Material
{
public:
  static InputParameters validParams();

  ADPhaseThermodynamicIdentityMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;

  const bool _include_fluid_identities;
  const bool _include_fluid_gradients;
  const bool _include_solid_legendre;
  const bool _check_admissible_saturations;
  const bool _enforce_identity_residuals;
  const Real _dimensionless_identity_tolerance;
  const Real _pressure_identity_tolerance;
  const Real _rate_identity_tolerance;
  const Real _entropy_production_tolerance;

  std::vector<const ADMaterialProperty<Real> *> _fluid_saturations;
  std::vector<const ADMaterialProperty<Real> *> _fluid_pressures;
  std::vector<const ADMaterialProperty<Real> *> _fluid_primitive_potentials;
  std::vector<const ADMaterialProperty<Real> *> _fluid_electric_enthalpies;
  std::vector<const ADMaterialProperty<Real> *> _fluid_saturation_forces;
  std::vector<const ADMaterialProperty<Real> *> _fluid_saturation_rates;
  std::vector<const ADMaterialProperty<Real> *> _predicted_force_differences;
  std::vector<const ADMaterialProperty<RealVectorValue> *> _fluid_saturation_gradients;
  std::vector<const ADMaterialProperty<RealVectorValue> *> _fluid_primitive_potential_gradients;
  std::vector<const ADMaterialProperty<RealVectorValue> *> _fluid_electric_enthalpy_gradients;
  std::vector<const ADMaterialProperty<RealVectorValue> *> _fluid_saturation_force_gradients;
  const ADMaterialProperty<Real> * _volume_constraint_multiplier;
  const ADMaterialProperty<Real> * _interfacial_helmholtz;
  const ADMaterialProperty<Real> * _equivalent_pressure;
  const ADMaterialProperty<Real> * _reference_saturation_force;
  const ADMaterialProperty<Real> * _fluid_fraction;
  const ADMaterialProperty<Real> * _fluid_temperature;
  const ADMaterialProperty<RealVectorValue> * _equivalent_pressure_gradient;
  const unsigned int _reference_fluid_index;

  std::vector<ADMaterialProperty<Real> *> _fluid_volume_fraction_el_residuals;
  std::vector<ADMaterialProperty<Real> *> _exposed_saturation_forces;
  std::vector<ADMaterialProperty<Real> *> _force_differences;
  std::vector<ADMaterialProperty<Real> *> _force_rate_residuals;
  std::vector<ADMaterialProperty<Real> *> _reconstructed_fluid_pressures;
  std::vector<ADMaterialProperty<Real> *> _fluid_pressure_residuals;
  std::vector<ADMaterialProperty<RealVectorValue> *> _reconstructed_fluid_pressure_gradients;
  std::vector<ADMaterialProperty<RealVectorValue> *>
      _phase_momentum_pressure_potential_gradients;
  ADMaterialProperty<Real> & _saturation_sum;
  ADMaterialProperty<Real> & _saturation_sum_residual;
  ADMaterialProperty<Real> & _saturation_weighted_primitive_potential;
  ADMaterialProperty<Real> & _primitive_potential_sum_residual;
  ADMaterialProperty<Real> & _saturation_weighted_saturation_force;
  ADMaterialProperty<Real> & _computed_equivalent_pressure;
  ADMaterialProperty<Real> & _equivalent_pressure_residual;
  ADMaterialProperty<Real> & _multiplier_equivalent_pressure_residual;
  ADMaterialProperty<Real> & _reference_force_gauge_residual;
  ADMaterialProperty<Real> & _saturation_rate_sum_residual;
  ADMaterialProperty<Real> & _saturation_force_rate_power;
  ADMaterialProperty<Real> & _saturation_entropy_production;
  ADMaterialProperty<RealVectorValue> & _saturation_weighted_saturation_force_gradient;

  const ADMaterialProperty<Real> * _solid_specific_helmholtz;
  const ADMaterialProperty<Real> * _solid_electric_enthalpy;
  const ADMaterialProperty<Real> * _solid_intrinsic_specific_volume;
  const ADMaterialProperty<Real> * _solid_phase_pressure;
  const ADMaterialProperty<Real> * _solid_equivalent_pressure;

  ADMaterialProperty<Real> & _phase_legendre_transform;
  ADMaterialProperty<Real> & _phase_legendre_pressure_derivative;
  ADMaterialProperty<Real> & _phase_equivalent_pressure;
  ADMaterialProperty<Real> & _phase_equivalent_pressure_residual;
};
