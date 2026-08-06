#pragma once

#include "Material.h"

/** Tabulated stored capillary-pressure differences and their reference gradients. */
class ADBlackOilStoredCapillaryGradientMaterial : public Material
{
public:
  static InputParameters validParams();

  ADBlackOilStoredCapillaryGradientMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;

  std::pair<ADReal, Real> interpolateValueAndSlope(const ADReal & coordinate,
                                                   const std::vector<Real> & points,
                                                   const std::vector<Real> & values,
                                                   const std::string & coordinate_name) const;
  MaterialPropertyName prefixedName(const std::string & suffix) const;

  const ADMaterialProperty<Real> & _water_saturation;
  const ADMaterialProperty<RealVectorValue> & _water_saturation_gradient;
  const ADMaterialProperty<Real> & _gas_saturation;
  const ADMaterialProperty<RealVectorValue> & _gas_saturation_gradient;
  const std::vector<Real> _water_saturation_points;
  const std::vector<Real> _water_oil_capillary_pressure_values;
  const std::vector<Real> _gas_saturation_points;
  const std::vector<Real> _gas_oil_capillary_pressure_values;
  const MooseEnum _out_of_range_policy;
  const std::string _property_prefix;

  ADMaterialProperty<Real> & _water_stored_pressure_difference;
  ADMaterialProperty<RealVectorValue> & _water_stored_pressure_difference_gradient;
  ADMaterialProperty<Real> & _gas_stored_pressure_difference;
  ADMaterialProperty<RealVectorValue> & _gas_stored_pressure_difference_gradient;
};
