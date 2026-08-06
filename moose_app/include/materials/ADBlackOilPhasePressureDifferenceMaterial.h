#pragma once

#include "Material.h"

/**
 * Reconstructs black-oil water/oil and gas/oil pressure differences from separate stored
 * surface-energy, electrical-enthalpy, and generalized saturation-force contributions.
 */
class ADBlackOilPhasePressureDifferenceMaterial : public Material
{
public:
  static InputParameters validParams();

  ADBlackOilPhasePressureDifferenceMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;
  ADReal interpolate(const ADReal & coordinate,
                     const std::vector<Real> & points,
                     const std::vector<Real> & values,
                     const std::string & coordinate_name) const;
  ADReal waterSaturation() const;
  ADReal gasSaturation() const;
  ADReal waterPressureDifference() const;
  ADReal gasPressureDifference() const;
  MaterialPropertyName prefixedName(const std::string & suffix) const;

  const ADVariableValue * _water_pressure_difference;
  const ADMaterialProperty<Real> * _water_pressure_difference_property;
  const ADVariableValue * _gas_pressure_difference;
  const ADMaterialProperty<Real> * _gas_pressure_difference_property;
  const ADVariableValue * _water_saturation;
  const ADMaterialProperty<Real> * _water_saturation_property;
  const ADVariableValue * _gas_saturation;
  const ADMaterialProperty<Real> * _gas_saturation_property;
  const ADMaterialProperty<Real> * _water_electrical_enthalpy_difference_input;
  const ADMaterialProperty<Real> * _gas_electrical_enthalpy_difference_input;
  const ADMaterialProperty<Real> * _water_saturation_force_difference_input;
  const ADMaterialProperty<Real> * _gas_saturation_force_difference_input;

  const std::vector<Real> _water_saturation_points;
  const std::vector<Real> _water_oil_capillary_pressure_values;
  const std::vector<Real> _gas_saturation_points;
  const std::vector<Real> _gas_oil_capillary_pressure_values;
  const MooseEnum _out_of_range_policy;
  const std::string _property_prefix;

  ADMaterialProperty<Real> & _water_stored_surface_energy_difference;
  ADMaterialProperty<Real> & _gas_stored_surface_energy_difference;
  ADMaterialProperty<Real> & _water_electrical_enthalpy_difference;
  ADMaterialProperty<Real> & _gas_electrical_enthalpy_difference;
  ADMaterialProperty<Real> & _water_saturation_force_difference;
  ADMaterialProperty<Real> & _gas_saturation_force_difference;
  ADMaterialProperty<Real> & _water_reconstructed_pressure_difference;
  ADMaterialProperty<Real> & _gas_reconstructed_pressure_difference;
  ADMaterialProperty<Real> & _water_pressure_difference_closure_residual;
  ADMaterialProperty<Real> & _gas_pressure_difference_closure_residual;
};
