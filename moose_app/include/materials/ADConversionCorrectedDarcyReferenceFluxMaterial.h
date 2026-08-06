#pragma once

#include "Material.h"
#include "RankTwoTensor.h"

/**
 * Generalized Darcy closure for a transforming fluid phase.
 *
 * Implements eqs. (modified_relative_flux_permeability) and
 * (generalized_fluid_darcy_mass_flux) from the manuscript, then applies the
 * Piola pull-back W = J F^{-1} w.  Optional force families are independently
 * selectable from the input deck.
 */
class ADConversionCorrectedDarcyReferenceFluxMaterial : public Material
{
public:
  static InputParameters validParams();
  ADConversionCorrectedDarcyReferenceFluxMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;

  const ADMaterialProperty<Real> & _J;
  const ADMaterialProperty<RankTwoTensor> & _F_inv;
  const ADMaterialProperty<Real> & _phase_fraction;
  const ADMaterialProperty<Real> & _bulk_density;
  const ADMaterialProperty<Real> & _conversion_source;
  const ADMaterialProperty<Real> * _relative_permeability;
  const ADMaterialProperty<Real> * _viscosity_property;
  const ADMaterialProperty<RealVectorValue> * _electrical_force;

  const ADVariableGradient & _grad_pressure;
  const ADVariableGradient * _grad_pressure_enrichment;
  const ADVariableGradient * _grad_capillary_pressure;
  const ADVariableGradient * _grad_capillary_pressure_enrichment;
  const ADVariableGradient * _grad_tau;
  const ADVariableGradient * _grad_tau_enrichment;
  std::vector<const ADVariableValue *> _solid_velocity;
  std::vector<const ADVariableValue *> _phase_acceleration;

  const Real _permeability;
  const Real _viscosity;
  const RealVectorValue _gravity;
  const bool _include_capillary_pressure;
  const bool _include_electrical_force;
  const bool _include_conversion_insertion;
  const bool _include_acceleration;
  const Real _minimum_resistance;
  const bool _require_positive_resistance;

  ADMaterialProperty<Real> & _combined_resistance;
  ADMaterialProperty<Real> & _resistance_margin;
  ADMaterialProperty<RealVectorValue> & _spatial_relative_mass_flux;
  ADMaterialProperty<RealVectorValue> & _reference_relative_mass_flux;
};
