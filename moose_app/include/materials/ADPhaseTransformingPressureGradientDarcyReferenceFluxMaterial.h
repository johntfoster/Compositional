#pragma once

#include "Material.h"
#include "RankTwoTensor.h"

class PhaseRegistry;

/** Generalized Darcy closure driven by a modularly assembled phase-pressure gradient. */
class ADPhaseTransformingPressureGradientDarcyReferenceFluxMaterial : public Material
{
public:
  static InputParameters validParams();

  ADPhaseTransformingPressureGradientDarcyReferenceFluxMaterial(
      const InputParameters & parameters);

protected:
  void computeQpProperties() override;

  const ADMaterialProperty<Real> & _J;
  const ADMaterialProperty<RankTwoTensor> & _F_inv;
  const ADMaterialProperty<RealVectorValue> & _phase_pressure_gradient;
  const ADVariableGradient & _grad_tau;
  const ADVariableGradient * _grad_tau_enrichment;
  std::vector<const ADVariableValue *> _solid_displacement_dot;
  std::vector<const ADVariableValue *> _phase_acceleration;

  const MooseEnum _intrinsic_density_source;
  const ADVariableValue * _intrinsic_density_var;
  const ADMaterialProperty<Real> * _intrinsic_density_mat;
  const ADMaterialProperty<Real> & _bulk_density;
  const ADMaterialProperty<Real> & _conversion_source;
  const ADMaterialProperty<Real> * _phase_active;
  const ADMaterialProperty<Real> * _relative_permeability;
  const ADMaterialProperty<Real> * _viscosity_property;
  const ADMaterialProperty<RealVectorValue> * _electrical_force;
  const ADMaterialProperty<RankTwoTensor> * _permeability_property;

  const std::string _phase_name;
  const PhaseRegistry * _phase_registry;
  const Real _permeability;
  const Real _viscosity;
  const RealVectorValue _gravity;
  const bool _include_acceleration;
  const bool _include_electrical_force;
  const Real _minimum_denominator;
  const Real _active_tolerance;

  ADMaterialProperty<RankTwoTensor> & _darcy_mobility_ref;
  ADMaterialProperty<Real> & _combined_resistance;
  ADMaterialProperty<Real> & _resistance_denominator;
  ADMaterialProperty<RankTwoTensor> & _combined_resistance_tensor;
  ADMaterialProperty<RankTwoTensor> & _resistance_denominator_tensor;
  ADMaterialProperty<RealVectorValue> & _spatial_relative_mass_flux;
  ADMaterialProperty<RealVectorValue> & _reference_relative_mass_flux;
};
