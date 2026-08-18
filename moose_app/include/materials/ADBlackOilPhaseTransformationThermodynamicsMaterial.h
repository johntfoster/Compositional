#pragma once

#include "Material.h"

/**
 * Eq. (182) composition projection for dissolved/free black-oil gas.
 *
 * Stock-tank densities map R_s to the oil-phase gas mass fraction. A convex
 * penalty in the difference from the attainable mass fraction supplies the
 * oil Helmholtz potential. The fluid composition projection and phase-pressure
 * storage sum then recover absolute component potentials. The free-gas datum
 * is an explicitly synthetic isothermal SPE closure because SPE1 supplies no
 * caloric equation of state.
 */
class ADBlackOilPhaseTransformationThermodynamicsMaterial : public Material
{
public:
  static InputParameters validParams();
  ADBlackOilPhaseTransformationThermodynamicsMaterial(
      const InputParameters & parameters);

protected:
  void computeQpProperties() override;

  const ADMaterialProperty<Real> & _undersaturation_gap;
  const ADMaterialProperty<Real> & _oil_component_mass_fraction;
  const ADMaterialProperty<Real> & _dissolved_gas_mass_fraction;
  const ADMaterialProperty<Real> & _oil_intrinsic_density;
  const ADMaterialProperty<Real> & _gas_intrinsic_density;
  const ADMaterialProperty<Real> & _oil_bulk_density;
  const ADMaterialProperty<Real> & _gas_bulk_density;
  const ADMaterialProperty<Real> & _oil_pressure;
  const ADMaterialProperty<Real> & _gas_pressure;
  const Real _ratio_scale;
  const Real _chemical_stiffness;
  const Real _oil_surface_density;
  const Real _gas_surface_density;
  const Real _oil_reference_helmholtz;
  const Real _gas_helmholtz_offset;
  const Real _dissolved_specific_charge;
  const Real _free_specific_charge;
  const ADVariableValue * _electric_potential;
  const ADMaterialProperty<Real> * _phase_active;
  const Real _active_tol;
  const bool _deactivate_on_nonpositive_mass;

  ADMaterialProperty<Real> & _normalized_gap;
  ADMaterialProperty<Real> & _attainable_dissolved_gas_mass_fraction;
  ADMaterialProperty<Real> & _dissolved_gas_mass_fraction_gap;
  ADMaterialProperty<Real> & _mass_fraction_rs_derivative;
  ADMaterialProperty<Real> & _free_energy;
  ADMaterialProperty<Real> & _oil_phase_specific_helmholtz;
  ADMaterialProperty<Real> & _gas_phase_specific_helmholtz;
  ADMaterialProperty<Real> & _oil_helmholtz_gas_mass_fraction_derivative;
  ADMaterialProperty<Real> & _oil_component_specific_storage_work;
  ADMaterialProperty<Real> & _dissolved_gas_specific_storage_work;
  ADMaterialProperty<Real> & _free_gas_specific_storage_work;
  ADMaterialProperty<Real> & _oil_component_neutral_mu;
  ADMaterialProperty<Real> & _dissolved_neutral_mu;
  ADMaterialProperty<Real> & _free_neutral_mu;
  ADMaterialProperty<Real> & _dissolved_electrochemical_mu;
  ADMaterialProperty<Real> & _free_electrochemical_mu;
  ADMaterialProperty<Real> & _chemical_affinity;
  ADMaterialProperty<Real> & _mass_fraction_normalization_residual;
  ADMaterialProperty<Real> & _oil_pressure_storage_residual;
  ADMaterialProperty<Real> & _oil_composition_projection_residual;
  ADMaterialProperty<Real> & _oil_gas_euler_residual;
  ADMaterialProperty<Real> & _gas_pressure_storage_residual;
  ADMaterialProperty<Real> & _gas_euler_residual;
};
