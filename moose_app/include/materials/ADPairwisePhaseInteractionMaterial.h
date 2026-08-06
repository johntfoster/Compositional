#pragma once

#include "Material.h"

/** Antisymmetric pairwise phase drag with conservative internal-energy allocation. */
class ADPairwisePhaseInteractionMaterial : public Material
{
public:
  static InputParameters validParams();
  ADPairwisePhaseInteractionMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;
  ADRankTwoTensor pairResistance(unsigned int pair) const;
  Real validateResistanceAndMinimumEigenvalue(const RankTwoTensor & resistance) const;

  const unsigned int _dim;
  const unsigned int _n_phases;
  const std::vector<unsigned int> _pair_first;
  const std::vector<unsigned int> _pair_second;
  std::vector<Real> _heating_fraction_to_first;
  std::vector<const ADMaterialProperty<RealVectorValue> *> _phase_velocities;
  std::vector<const ADVariableValue *> _phase_velocity_components;
  std::vector<const ADMaterialProperty<Real> *> _phase_temperatures;
  std::vector<const ADMaterialProperty<RankTwoTensor> *> _pair_resistances;
  std::vector<const ADMaterialProperty<Real> *> _pair_resistance_components;
  const bool _resistance_tensors_are_constant;
  std::vector<bool> _resistance_validated;
  std::vector<Real> _cached_minimum_eigenvalues;
  std::vector<ADMaterialProperty<RealVectorValue> *> _phase_forces;
  std::vector<ADMaterialProperty<Real> *> _phase_energy_supplies;
  ADMaterialProperty<RealVectorValue> & _momentum_cancellation;
  ADMaterialProperty<Real> & _energy_cancellation;
  ADMaterialProperty<Real> & _total_drag_dissipation;
  ADMaterialProperty<Real> & _entropy_production;
  ADMaterialProperty<Real> & _minimum_resistance_eigenvalue;
};
