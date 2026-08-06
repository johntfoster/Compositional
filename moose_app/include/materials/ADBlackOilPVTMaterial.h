#pragma once

#include "Material.h"

/**
 * Evaluates pressure-tabulated black-oil PVT data and component storage.
 *
 * Linear interpolation is performed directly on the AD pressure so the table
 * slope contributes to the application Jacobian on the active interval.
 */
class ADBlackOilPVTMaterial : public Material
{
public:
  static InputParameters validParams();

  ADBlackOilPVTMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;

  ADReal interpolate(const std::vector<Real> & values) const;
  Real tableSlope(const std::vector<Real> & values) const;
  ADReal pressure() const;
  ADReal pressureDot() const;
  ADReal waterSaturation() const;
  ADReal gasSaturation() const;
  ADReal waterSaturationDot() const;
  ADReal gasSaturationDot() const;
  MaterialPropertyName prefixedName(const std::string & suffix) const;

  const ADMaterialProperty<Real> & _J;
  const ADMaterialProperty<Real> * _J_dot;
  const ADVariableValue * _pressure;
  const ADMaterialProperty<Real> * _pressure_property;
  const ADVariableValue * _pressure_dot;
  const ADMaterialProperty<Real> * _pressure_property_dot;
  const ADVariableValue & _porosity;
  const ADVariableValue * _porosity_dot;
  const ADVariableValue * _water_saturation;
  const ADMaterialProperty<Real> * _water_saturation_property;
  const ADVariableValue * _water_saturation_dot;
  const ADMaterialProperty<Real> * _water_saturation_property_dot;
  const ADVariableValue * _gas_saturation;
  const ADMaterialProperty<Real> * _gas_saturation_property;
  const ADVariableValue * _gas_saturation_dot;
  const ADMaterialProperty<Real> * _gas_saturation_property_dot;

  const std::vector<Real> _pressure_points;
  const std::vector<Real> _water_fvf_values;
  const std::vector<Real> _oil_fvf_values;
  const std::vector<Real> _gas_fvf_values;
  const std::vector<Real> _solution_gas_oil_ratio_values;
  const std::vector<Real> _water_viscosity_values;
  const std::vector<Real> _oil_viscosity_values;
  const std::vector<Real> _gas_viscosity_values;
  const MooseEnum _out_of_range_policy;

  const Real _water_surface_density;
  const Real _oil_surface_density;
  const Real _gas_surface_density;
  const std::string _property_prefix;

  ADMaterialProperty<Real> & _water_fvf;
  ADMaterialProperty<Real> & _oil_fvf;
  ADMaterialProperty<Real> & _gas_fvf;
  ADMaterialProperty<Real> & _solution_gas_oil_ratio;
  ADMaterialProperty<Real> & _water_viscosity;
  ADMaterialProperty<Real> & _oil_viscosity;
  ADMaterialProperty<Real> & _gas_viscosity;
  ADMaterialProperty<Real> & _oil_saturation;

  ADMaterialProperty<Real> & _water_intrinsic_density;
  ADMaterialProperty<Real> & _oil_intrinsic_density;
  ADMaterialProperty<Real> & _gas_intrinsic_density;
  ADMaterialProperty<Real> & _oil_component_mass_fraction_in_oil;
  ADMaterialProperty<Real> & _gas_component_mass_fraction_in_oil;

  ADMaterialProperty<Real> & _water_current_component_storage;
  ADMaterialProperty<Real> & _oil_current_component_storage;
  ADMaterialProperty<Real> & _gas_current_component_storage;
  ADMaterialProperty<Real> & _water_reference_component_storage;
  ADMaterialProperty<Real> & _oil_reference_component_storage;
  ADMaterialProperty<Real> & _gas_reference_component_storage;
  ADMaterialProperty<Real> & _water_reference_component_storage_rate;
  ADMaterialProperty<Real> & _oil_reference_component_storage_rate;
  ADMaterialProperty<Real> & _gas_reference_component_storage_rate;
};
