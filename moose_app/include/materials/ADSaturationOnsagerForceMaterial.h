#pragma once

#include "Material.h"

/**
 * Evaluates the manuscript saturation-force relation
 * L_f^sat-L_ref^sat = sum_g T_fg dot(S_g) for the independent fluid phases.
 */
class ADSaturationOnsagerForceMaterial : public Material
{
public:
  static InputParameters validParams();

  ADSaturationOnsagerForceMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;
  MaterialPropertyName prefixedName(const std::string & suffix) const;

  const std::vector<std::string> _independent_phase_names;
  const std::vector<Real> _resistance_matrix;
  const bool _resistance_property_mode;
  const Real _positive_semidefinite_tolerance;
  const Real _constant_porosity;
  const Real _constant_fluid_temperature;
  const std::string _property_prefix;

  std::vector<const ADMaterialProperty<Real> *> _saturation_rates;
  std::vector<const ADMaterialProperty<Real> *> _resistance_properties;
  const ADMaterialProperty<Real> * _porosity;
  const ADMaterialProperty<Real> * _fluid_temperature;
  std::vector<ADMaterialProperty<Real> *> _force_differences;
  ADMaterialProperty<Real> & _dissipation_rate;
  ADMaterialProperty<Real> & _entropy_production_rate;
  ADMaterialProperty<Real> & _minimum_resistance_eigenvalue;
  Real _constant_minimum_eigenvalue;
};
