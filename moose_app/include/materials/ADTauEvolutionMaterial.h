#pragma once

#include "Material.h"

/**
 * Solid-reference transfer-potential evolution residual.
 *
 * The material forms the pointwise residual associated with the tau evolution
 * equation. Optional thermodynamic material properties supply the full
 * reference-solid right-hand side; a forcing function is available for
 * manufactured-solution tests.
 */
class ADTauEvolutionMaterial : public Material
{
public:
  static InputParameters validParams();

  ADTauEvolutionMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;

  const ADVariableValue & _tau_dot;
  const unsigned int _dim;
  std::vector<const ADVariableValue *> _reference_phase_velocity;
  std::vector<const ADVariableValue *> _reference_phase_displacement_dot;
  const ADVariableValue * _tau_enrichment_dot;

  const bool _use_thermodynamic_rhs;
  const ADMaterialProperty<Real> * _reference_neutral_potential;
  const ADMaterialProperty<Real> * _reference_specific_helmholtz;
  const ADMaterialProperty<Real> * _reference_pressure_work;
  const Function & _forcing;

  ADMaterialProperty<Real> & _tau_evolution_residual;
};
