#pragma once

#include "Material.h"

class ADTwoPhaseConstantKEquilibriumMaterial : public Material
{
public:
  static InputParameters validParams();

  ADTwoPhaseConstantKEquilibriumMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;

  const ADMaterialProperty<Real> & _J;
  const ADVariableValue & _total_porosity;
  const ADVariableValue & _phase0_density;
  const ADVariableValue & _phase1_density;
  std::vector<const ADVariableValue *> _overall_mass_fractions;

  const std::vector<Real> _k_values;
  const Real _sum_tol;
  const Real _interior_tol;

  ADMaterialProperty<Real> & _phase1_mass_fraction;
  ADMaterialProperty<Real> & _phase0_saturation;
  ADMaterialProperty<Real> & _phase1_saturation;
  ADMaterialProperty<Real> & _phase0_volume_fraction;
  ADMaterialProperty<Real> & _phase1_volume_fraction;
  ADMaterialProperty<Real> & _volume_constraint_residual;
  ADMaterialProperty<Real> & _overall_mass_fraction_sum;
  ADMaterialProperty<Real> & _phase0_mass_fraction_sum;
  ADMaterialProperty<Real> & _phase1_mass_fraction_sum;

  std::vector<ADMaterialProperty<Real> *> _phase0_mass_fractions;
  std::vector<ADMaterialProperty<Real> *> _phase1_mass_fractions;
  std::vector<ADMaterialProperty<Real> *> _equilibrium_residuals;
  std::vector<ADMaterialProperty<Real> *> _overall_composition_residuals;
  std::vector<ADMaterialProperty<Real> *> _total_reference_component_storages;
};
