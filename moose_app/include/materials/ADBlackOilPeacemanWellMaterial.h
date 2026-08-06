#pragma once

#include "Material.h"

/** Computes completion-local black-oil sources for BHP- or surface-rate-controlled wells. */
class ADBlackOilPeacemanWellMaterial : public Material
{
public:
  static InputParameters validParams();

  ADBlackOilPeacemanWellMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;

  const MooseEnum _pressure_source;
  const ADMaterialProperty<Real> * _water_pressure_property;
  const ADMaterialProperty<Real> * _oil_pressure_property;
  const ADMaterialProperty<Real> * _gas_pressure_property;
  const ADVariableValue * _water_pressure_variable;
  const ADVariableValue * _oil_pressure_variable;
  const ADVariableValue * _gas_pressure_variable;
  const ADMaterialProperty<Real> * _wellbore_density_property;
  const ADVariableValue * _bottom_hole_pressure_variable;
  const MooseEnum _mobility_source;
  const ADMaterialProperty<Real> * _water_mobility;
  const ADMaterialProperty<Real> * _oil_mobility;
  const ADMaterialProperty<Real> * _gas_mobility;
  const ADMaterialProperty<Real> * _water_relative_permeability;
  const ADMaterialProperty<Real> * _oil_relative_permeability;
  const ADMaterialProperty<Real> * _gas_relative_permeability;
  const ADMaterialProperty<Real> * _water_viscosity;
  const ADMaterialProperty<Real> * _oil_viscosity;
  const ADMaterialProperty<Real> * _gas_viscosity;
  const ADMaterialProperty<Real> & _water_fvf;
  const ADMaterialProperty<Real> & _oil_fvf;
  const ADMaterialProperty<Real> & _gas_fvf;
  const ADMaterialProperty<Real> & _solution_gas_oil_ratio;

  const Real _well_index;
  const MooseEnum _control_mode;
  const MooseEnum _injection_phase;
  const Real _bottom_hole_pressure;
  const Real _target_surface_rate;
  const bool _apply_datum_correction;
  const MooseEnum _wellbore_density_source;
  const Real _wellbore_density;
  const Real _completion_depth;
  const Real _bhp_datum_depth;
  const Real _gravity_magnitude;
  const bool _apply_bhp_limit;
  const MooseEnum _bhp_limit_type;
  const Real _bhp_limit;
  const Real _completion_reference_volume;
  const Real _water_surface_density;
  const Real _oil_surface_density;
  const Real _gas_surface_density;

  ADMaterialProperty<Real> & _water_reservoir_rate;
  ADMaterialProperty<Real> & _oil_reservoir_rate;
  ADMaterialProperty<Real> & _gas_reservoir_rate;
  ADMaterialProperty<Real> & _water_surface_rate;
  ADMaterialProperty<Real> & _oil_surface_rate;
  ADMaterialProperty<Real> & _free_gas_surface_rate;
  ADMaterialProperty<Real> & _gas_surface_rate;
  ADMaterialProperty<Real> & _water_reference_component_source;
  ADMaterialProperty<Real> & _oil_reference_component_source;
  ADMaterialProperty<Real> & _free_gas_reference_component_source;
  ADMaterialProperty<Real> & _gas_reference_component_source;
  ADMaterialProperty<Real> & _effective_bottom_hole_pressure;
  ADMaterialProperty<Real> & _datum_bottom_hole_pressure;
  ADMaterialProperty<Real> & _datum_pressure_correction;
  ADMaterialProperty<Real> & _control_surface_rate_residual;
  ADMaterialProperty<Real> & _control_surface_productivity;
};
