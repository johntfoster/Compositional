#pragma once

#include "Material.h"

/** Spatial gradients of generalized saturation-force differences. */
class ADSaturationOnsagerForceGradientMaterial : public Material
{
public:
  static InputParameters validParams();

  ADSaturationOnsagerForceGradientMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;
  MaterialPropertyName prefixedName(const std::string & suffix) const;

  const std::vector<std::string> _independent_phase_names;
  const std::vector<Real> _resistance_matrix;
  const bool _resistance_property_mode;
  const Real _positive_semidefinite_tolerance;
  const std::string _property_prefix;
  std::vector<const ADMaterialProperty<Real> *> _saturation_rates;
  std::vector<const ADMaterialProperty<RealVectorValue> *> _saturation_rate_gradients;
  std::vector<const ADMaterialProperty<Real> *> _resistance_properties;
  std::vector<const ADMaterialProperty<RealVectorValue> *> _resistance_gradients;
  std::vector<ADMaterialProperty<RealVectorValue> *> _force_difference_gradients;
};
