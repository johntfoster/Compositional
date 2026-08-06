#pragma once

#include "Material.h"

class PhaseRegistry;

/**
 * Comparison-only conventional equilibrium flash-state assembler.
 *
 * The material consumes phase amounts, phase compositions, and EOS-derived
 * pressure and chemical-potential properties. It exposes algebraic residual
 * properties that a deck may select for a traditional flash comparison and
 * computes reference component storage on the solid skeleton configuration.
 *
 * It deliberately does not represent the manuscript's Eqs. (182)--(183),
 * storage-multiplier recovery, or nonequilibrium tau/mu transfer system.
 */
class ADRegisteredPhaseFlashMaterial : public Material
{
public:
  static InputParameters validParams();

  ADRegisteredPhaseFlashMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;

  unsigned int phaseComponentIndex(const unsigned int phase, const unsigned int component) const;
  MaterialPropertyName prefixedName(const std::string & suffix) const;

  const PhaseRegistry & _phase_registry;
  const std::vector<std::string> _phases;
  const std::vector<std::string> _components;
  const unsigned int _n_phases;
  const unsigned int _n_components;
  unsigned int _equilibrium_reference_index;

  const ADMaterialProperty<Real> & _J;
  const ADVariableValue & _total_phase_fraction;
  std::vector<const ADVariableValue *> _phase_volume_fractions;
  std::vector<const ADVariableValue *> _phase_component_mass_fractions;
  std::vector<const ADVariableValue *> _overall_mass_fractions;

  std::vector<const ADMaterialProperty<Real> *> _phase_intrinsic_densities;
  std::vector<const ADMaterialProperty<Real> *> _phase_pressures;
  std::vector<const ADMaterialProperty<Real> *> _phase_chemical_potentials;

  const Real _active_tol;
  const bool _has_overall_mass_fractions;
  const std::string _property_prefix;

  ADMaterialProperty<Real> & _volume_constraint_residual;
  ADMaterialProperty<Real> & _total_current_mass_density;
  ADMaterialProperty<Real> & _total_reference_mass_storage;
  ADMaterialProperty<Real> & _overall_mass_fraction_sum;

  std::vector<ADMaterialProperty<Real> *> _phase_active;
  std::vector<ADMaterialProperty<Real> *> _phase_saturations;
  std::vector<ADMaterialProperty<Real> *> _phase_current_mass_densities;
  std::vector<ADMaterialProperty<Real> *> _phase_component_mass_fraction_sums;
  std::vector<ADMaterialProperty<Real> *> _phase_component_mass_fraction_residuals;
  std::vector<ADMaterialProperty<Real> *> _phase_pressure_equilibrium_residuals;

  std::vector<ADMaterialProperty<Real> *> _phase_reference_component_storages;
  std::vector<ADMaterialProperty<Real> *> _phase_current_component_densities;
  std::vector<ADMaterialProperty<Real> *> _phase_component_mass_fraction_properties;
  std::vector<ADMaterialProperty<Real> *> _chemical_equilibrium_residuals;

  std::vector<ADMaterialProperty<Real> *> _overall_mass_fractions_from_phases;
  std::vector<ADMaterialProperty<Real> *> _overall_composition_residuals;
  std::vector<ADMaterialProperty<Real> *> _total_current_component_densities;
  std::vector<ADMaterialProperty<Real> *> _total_reference_component_storages;
};
