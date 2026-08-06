#pragma once

#include "Material.h"

#include <utility>

/**
 * Evaluates ECLIPSE-style PVTW, PVDG, and PVTO data for SPE black-oil benchmarks.
 */
class ADBlackOilBenchmarkPVTMaterial : public Material
{
public:
  static InputParameters validParams();

  ADBlackOilBenchmarkPVTMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;

  ADReal interpolate1D(const std::vector<Real> & coordinates,
                       const std::vector<Real> & values,
                       const ADReal & coordinate,
                       const std::string & table_name) const;
  ADReal interpolateOilBranchAtPressure(unsigned int branch,
                                        const std::vector<Real> & values,
                                        const ADReal & pressure) const;
  ADReal interpolateOilBranch(unsigned int branch, const std::vector<Real> & values) const;
  ADReal interpolateUndersaturatedOil(const std::vector<Real> & values) const;
  Real interpolate1DSlope(const std::vector<Real> & coordinates,
                          const std::vector<Real> & values,
                          const ADReal & coordinate,
                          const std::string & table_name) const;
  Real oilBranchPressureSlopeAtPressure(unsigned int branch,
                                        const std::vector<Real> & values,
                                        const ADReal & pressure) const;
  Real oilBranchPressureSlope(unsigned int branch, const std::vector<Real> & values) const;
  std::pair<ADReal, ADReal> undersaturatedOilDerivatives(
      const std::vector<Real> & values) const;
  ADReal oilPressure() const;
  ADReal oilPressureDot() const;
  ADReal waterSaturation() const;
  ADReal waterSaturationDot() const;
  ADReal gasSaturation() const;
  ADReal gasSaturationDot() const;
  MaterialPropertyName prefixedName(const std::string & suffix) const;

  const ADMaterialProperty<Real> & _J;
  const ADMaterialProperty<Real> * _J_dot;
  const ADVariableValue * _oil_pressure;
  const ADMaterialProperty<Real> * _oil_pressure_property;
  const ADVariableValue * _oil_pressure_dot;
  const ADMaterialProperty<Real> * _oil_pressure_property_dot;
  const ADVariableValue & _solution_gas_oil_ratio_state;
  const ADVariableValue * _solution_gas_oil_ratio_state_dot;
  const Moose::Functor<ADReal> & _solution_gas_oil_ratio_functor;
  const ADVariableValue * _porosity;
  const ADMaterialProperty<Real> * _porosity_property;
  const ADVariableValue * _porosity_dot;
  const ADMaterialProperty<Real> * _porosity_property_dot;
  const ADVariableValue * _water_saturation;
  const ADMaterialProperty<Real> * _water_saturation_property;
  const ADVariableValue * _water_saturation_dot;
  const ADMaterialProperty<Real> * _water_saturation_property_dot;
  const ADVariableValue * _gas_saturation;
  const ADMaterialProperty<Real> * _gas_saturation_property;
  const ADVariableValue * _gas_saturation_dot;
  const ADMaterialProperty<Real> * _gas_saturation_property_dot;
  const bool _compute_storage_rates;
  const bool _use_pressure_dependent_rock_porosity;
  const Real _rock_reference_pressure;
  const Real _rock_compressibility;

  const Real _water_reference_pressure;
  const Real _water_reference_fvf;
  const Real _water_compressibility;
  const Real _water_reference_viscosity;
  const Real _water_viscosibility;

  const std::vector<Real> _gas_pressure_points;
  const std::vector<Real> _gas_fvf_values;
  const std::vector<Real> _gas_viscosity_values;
  std::vector<Real> _gas_inverse_fvf_values;
  std::vector<Real> _gas_inverse_fvf_viscosity_values;

  const std::vector<Real> _oil_rs_points;
  const std::vector<Real> _oil_bubble_pressure_points;
  const std::vector<unsigned int> _oil_branch_offsets;
  const std::vector<Real> _oil_pressure_points;
  const std::vector<Real> _oil_fvf_values;
  const std::vector<Real> _oil_viscosity_values;
  const std::vector<Real> _saturated_oil_fvf_values;
  const std::vector<Real> _saturated_oil_viscosity_values;
  std::vector<unsigned int> _interpolation_oil_branch_offsets;
  std::vector<Real> _interpolation_oil_pressure_points;
  std::vector<Real> _oil_inverse_fvf_values;
  std::vector<Real> _oil_inverse_fvf_viscosity_values;
  std::vector<Real> _saturated_oil_inverse_fvf_values;
  std::vector<Real> _saturated_oil_inverse_fvf_viscosity_values;

  const MooseEnum _out_of_range_policy;
  const Real _gas_active_tol;
  const bool _equilibrate_solution_gas_with_free_gas;
  const Real _solution_gas_oil_ratio_scale;
  const Real _maximum_solution_gas_oil_ratio;
  const Real _solution_gas_transition_width;
  const bool _enforce_nonincreasing_solution_gas;
  const bool _reject_oversaturated_state;
  const Real _water_surface_density;
  const Real _oil_surface_density;
  const Real _gas_surface_density;
  const std::string _property_prefix;

  ADMaterialProperty<Real> & _water_fvf;
  ADMaterialProperty<Real> & _oil_fvf;
  ADMaterialProperty<Real> & _gas_fvf;
  ADMaterialProperty<Real> & _water_viscosity;
  ADMaterialProperty<Real> & _oil_viscosity;
  ADMaterialProperty<Real> & _gas_viscosity;
  ADMaterialProperty<Real> & _solution_gas_oil_ratio;
  ADMaterialProperty<Real> & _saturated_solution_gas_oil_ratio;
  ADMaterialProperty<Real> & _undersaturation_gap;
  ADMaterialProperty<Real> & _gas_appearance_complementarity_residual;
  ADMaterialProperty<Real> & _solution_gas_constraint_residual;
  ADMaterialProperty<Real> & _oil_saturation;
  ADMaterialProperty<Real> & _water_intrinsic_density;
  ADMaterialProperty<Real> & _oil_intrinsic_density;
  ADMaterialProperty<Real> & _gas_intrinsic_density;
  ADMaterialProperty<Real> & _water_component_mass_fraction_in_water;
  ADMaterialProperty<Real> & _oil_component_mass_fraction_in_oil;
  ADMaterialProperty<Real> & _gas_component_mass_fraction_in_oil;
  ADMaterialProperty<Real> & _gas_component_mass_fraction_in_gas;
  ADMaterialProperty<Real> & _water_reference_component_storage;
  ADMaterialProperty<Real> & _oil_reference_component_storage;
  ADMaterialProperty<Real> & _gas_reference_component_storage;
  ADMaterialProperty<Real> & _dissolved_gas_reference_component_storage;
  ADMaterialProperty<Real> & _free_gas_reference_component_storage;
  ADMaterialProperty<Real> & _water_reference_phase_mass_coefficient;
  ADMaterialProperty<Real> & _free_gas_reference_phase_mass_coefficient;
  ADMaterialProperty<Real> & _water_reference_phase_mass_coefficient_rate;
  ADMaterialProperty<Real> & _free_gas_reference_phase_mass_coefficient_rate;
  ADMaterialProperty<Real> & _water_reference_component_storage_rate;
  ADMaterialProperty<Real> & _oil_reference_component_storage_rate;
  ADMaterialProperty<Real> & _gas_reference_component_storage_rate;
  ADMaterialProperty<Real> & _dissolved_gas_reference_component_storage_rate;
  ADMaterialProperty<Real> & _free_gas_reference_component_storage_rate;
  ADMaterialProperty<Real> & _water_bulk_phase_density;
  ADMaterialProperty<Real> & _oil_bulk_phase_density;
  ADMaterialProperty<Real> & _gas_bulk_phase_density;
  ADMaterialProperty<Real> & _oil_phase_availability;
  ADMaterialProperty<Real> & _gas_phase_availability;
  ADMaterialProperty<Real> & _oil_active;
  ADMaterialProperty<Real> & _gas_active;
};
