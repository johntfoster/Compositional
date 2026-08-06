#pragma once

#include "Material.h"

class PhaseRegistry;

/**
 * General mechanism-major reaction network on the solid reference mesh.
 */
class ADReactionNetworkMaterial : public Material
{
public:
  static InputParameters validParams();

  ADReactionNetworkMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;

  unsigned int phaseComponentIndex(unsigned int phase, unsigned int component) const;
  unsigned int mechanismComponentIndex(unsigned int mechanism, unsigned int component) const;
  unsigned int mechanismPhaseIndex(unsigned int mechanism, unsigned int phase) const;
  unsigned int mechanismPhaseComponentIndex(unsigned int mechanism,
                                            unsigned int phase,
                                            unsigned int component) const;
  MaterialPropertyName prefixedName(const std::string & suffix) const;

  const PhaseRegistry & _phase_registry;
  const std::vector<std::string> _phases;
  const std::vector<std::string> _components;
  const unsigned int _n_phases;
  const unsigned int _n_components;
  const unsigned int _n_mechanisms;

  const ADMaterialProperty<Real> & _J;
  std::vector<const ADVariableValue *> _reaction_rates;
  const std::vector<Real> _stoichiometric_coefficients;
  std::vector<const ADMaterialProperty<Real> *> _chemical_potentials;
  std::vector<const ADMaterialProperty<Real> *> _phase_tau_offsets;
  std::vector<const ADMaterialProperty<Real> *> _neutral_conversion_coefficients;
  std::vector<const ADMaterialProperty<Real> *> _phase_temperatures;
  const bool _use_tau_offsets;
  const bool _use_temperature_weighted_force;
  const MooseEnum _kinetic_force;
  const bool _use_kinetic_mobilities;
  const std::vector<Real> _kinetic_mobilities;
  std::vector<const ADMaterialProperty<Real> *> _forward_phase_active;
  std::vector<const ADMaterialProperty<Real> *> _reverse_phase_active;
  const bool _use_directional_availability;
  const std::string _property_prefix;

  std::vector<ADMaterialProperty<Real> *> _phase_current_component_sources;
  std::vector<ADMaterialProperty<Real> *> _phase_reference_component_sources;
  std::vector<ADMaterialProperty<Real> *> _mechanism_current_component_sources;
  std::vector<ADMaterialProperty<Real> *> _mechanism_reference_component_sources;
  std::vector<ADMaterialProperty<Real> *> _total_current_component_sources;
  std::vector<ADMaterialProperty<Real> *> _total_reference_component_sources;
  std::vector<ADMaterialProperty<Real> *> _mechanism_affinities;
  std::vector<ADMaterialProperty<Real> *> _mechanism_phase_mass_sums;
  std::vector<ADMaterialProperty<Real> *> _mechanism_transfer_work_corrections;
  std::vector<ADMaterialProperty<Real> *> _mechanism_generalized_conversion_coefficients;
  std::vector<ADMaterialProperty<Real> *> _mechanism_temperature_weighted_forces;
  std::vector<ADMaterialProperty<Real> *> _mechanism_kinetic_forces;
  std::vector<ADMaterialProperty<Real> *> _mechanism_kinetic_residuals;
  std::vector<ADMaterialProperty<Real> *> _mechanism_reaction_powers;
  std::vector<ADMaterialProperty<Real> *> _mechanism_temperature_weighted_reaction_powers;
};

