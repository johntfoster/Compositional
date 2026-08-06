#pragma once

#include "Material.h"

/** Reconstructs water and gas pressures from the manuscript black-oil capillary closures. */
class ADBlackOilCapillaryPressureMaterial : public Material
{
public:
  static InputParameters validParams();

  ADBlackOilCapillaryPressureMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;

  ADReal interpolate(const ADReal & coordinate,
                     const std::vector<Real> & points,
                     const std::vector<Real> & values,
                     const std::string & coordinate_name) const;
  ADReal waterSaturation() const;
  ADReal gasSaturation() const;
  ADReal waterSaturationDot() const;
  ADReal gasSaturationDot() const;
  MaterialPropertyName prefixedName(const std::string & suffix) const;

  const ADVariableValue & _oil_pressure;
  const ADVariableValue & _water_pressure;
  const ADVariableValue & _gas_pressure;
  const ADVariableValue * _water_saturation;
  const ADMaterialProperty<Real> * _water_saturation_property;
  const ADVariableValue * _gas_saturation;
  const ADMaterialProperty<Real> * _gas_saturation_property;
  const ADVariableValue * _water_saturation_dot;
  const ADMaterialProperty<Real> * _water_saturation_property_dot;
  const ADVariableValue * _gas_saturation_dot;
  const ADMaterialProperty<Real> * _gas_saturation_property_dot;

  const std::vector<Real> _water_saturation_points;
  const std::vector<Real> _water_oil_capillary_pressure_values;
  const std::vector<Real> _gas_saturation_points;
  const std::vector<Real> _gas_oil_capillary_pressure_values;
  const Real _water_oil_dynamic_coefficient;
  const Real _gas_oil_dynamic_coefficient;
  const MooseEnum _out_of_range_policy;
  const std::string _property_prefix;

  ADMaterialProperty<Real> & _water_oil_capillary_pressure;
  ADMaterialProperty<Real> & _gas_oil_capillary_pressure;
  ADMaterialProperty<Real> & _reconstructed_water_pressure;
  ADMaterialProperty<Real> & _reconstructed_gas_pressure;
  ADMaterialProperty<Real> & _water_pressure_closure_residual;
  ADMaterialProperty<Real> & _gas_pressure_closure_residual;
};
