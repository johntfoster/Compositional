#pragma once

#include "Material.h"

/** Uncoupled admissible capillary-history evolution for arbitrary local coordinates h_k. */
class ADCapillaryHistoryOnsagerMaterial : public Material
{
public:
  static InputParameters validParams();

  ADCapillaryHistoryOnsagerMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;

  MaterialPropertyName prefixedName(const std::string & suffix) const;

  const std::vector<Real> _mobilities;
  const ADMaterialProperty<Real> & _porosity;
  const ADMaterialProperty<Real> & _fluid_temperature;
  const std::string _property_prefix;

  std::vector<const ADVariableValue *> _history_rates;
  std::vector<const ADMaterialProperty<Real> *> _history_derivatives;
  std::vector<ADMaterialProperty<Real> *> _predicted_history_rates;
  std::vector<ADMaterialProperty<Real> *> _history_rate_residuals;
  ADMaterialProperty<Real> & _history_dissipation_rate;
  ADMaterialProperty<Real> & _predicted_history_dissipation_rate;
  ADMaterialProperty<Real> & _history_entropy_production_rate;
};
