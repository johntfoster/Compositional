#pragma once

#include "Material.h"

/** Computes one phase's net current conversion source q_f from mechanism rates. */
class ADPhaseConversionSourceMaterial : public Material
{
public:
  static InputParameters validParams();
  ADPhaseConversionSourceMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;

  std::vector<const ADVariableValue *> _reaction_rates;
  const std::vector<Real> _phase_stoichiometric_mass_coefficients;
  ADMaterialProperty<Real> & _phase_current_conversion_source;
};
