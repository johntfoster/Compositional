#pragma once

#include "Material.h"

/** Evaluates SWOF/SGOF curves and the Stone second three-phase oil model used by SPE2. */
class ADBlackOilStoneIIRelativePermeabilityMaterial : public Material
{
public:
  static InputParameters validParams();

  ADBlackOilStoneIIRelativePermeabilityMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;
  ADReal interpolate(const ADReal & coordinate,
                     const std::vector<Real> & points,
                     const std::vector<Real> & values) const;
  MaterialPropertyName prefixedName(const std::string & suffix) const;

  const ADVariableValue * _water_saturation;
  const ADMaterialProperty<Real> * _water_saturation_property;
  const ADVariableValue * _gas_saturation;
  const ADMaterialProperty<Real> * _gas_saturation_property;
  const std::vector<Real> _water_saturation_points;
  const std::vector<Real> _water_relative_permeability_values;
  const std::vector<Real> _oil_water_relative_permeability_values;
  const std::vector<Real> _gas_saturation_points;
  const std::vector<Real> _gas_relative_permeability_values;
  const std::vector<Real> _oil_gas_relative_permeability_values;
  const MooseEnum _out_of_range_policy;
  const bool _clamp_oil_relative_permeability;
  const std::string _property_prefix;

  ADMaterialProperty<Real> & _water_relative_permeability;
  ADMaterialProperty<Real> & _oil_relative_permeability;
  ADMaterialProperty<Real> & _gas_relative_permeability;
  ADMaterialProperty<Real> & _oil_water_relative_permeability;
  ADMaterialProperty<Real> & _oil_gas_relative_permeability;
  ADMaterialProperty<Real> & _unclamped_oil_relative_permeability;
};
