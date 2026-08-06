#pragma once

#include "FVFluxKernel.h"

/**
 * Conservative first-order upstream component flux for a fixed-reference black-oil balance.
 */
class FVBlackOilPhaseUpwindComponentFlux : public FVFluxKernel
{
public:
  static InputParameters validParams();

  FVBlackOilPhaseUpwindComponentFlux(const InputParameters & parameters);

protected:
  ADReal computeQpResidual() override;

  std::vector<const ADMaterialProperty<Real> *> _phase_pressure;
  std::vector<const ADMaterialProperty<Real> *> _phase_pressure_neighbor;
  std::vector<const ADMaterialProperty<Real> *> _phase_density;
  std::vector<const ADMaterialProperty<Real> *> _phase_density_neighbor;
  std::vector<const ADMaterialProperty<Real> *> _phase_viscosity;
  std::vector<const ADMaterialProperty<Real> *> _phase_viscosity_neighbor;
  std::vector<const ADMaterialProperty<Real> *> _phase_relative_permeability;
  std::vector<const ADMaterialProperty<Real> *> _phase_relative_permeability_neighbor;
  std::vector<const ADMaterialProperty<Real> *> _phase_component_mass_fraction;
  std::vector<const ADMaterialProperty<Real> *> _phase_component_mass_fraction_neighbor;
  const ADMaterialProperty<Real> & _permeability;
  const ADMaterialProperty<Real> & _permeability_neighbor;
  const RealVectorValue _gravity;
};
