#pragma once

#include "Material.h"
#include "RankTwoTensor.h"

class PhaseRegistry;

/** Production generalized-Darcy closure compatible with standard Darcy deck blocks. */
class ADPhaseTransformingDarcyReferenceFluxMaterial : public Material
{
public:
  static InputParameters validParams();
  ADPhaseTransformingDarcyReferenceFluxMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;

  const ADMaterialProperty<Real> & _J;
  const ADMaterialProperty<RankTwoTensor> & _F_inv;
  const ADVariableGradient & _grad_pressure;
  const ADVariableGradient * _grad_pressure_enrichment;
  const ADVariableGradient * _grad_capillary_pressure;
  const ADVariableGradient * _grad_capillary_pressure_enrichment;
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

  const std::string _phase_name;
  const PhaseRegistry * _phase_registry;
  const Real _permeability;
  const Real _viscosity;
  const RealVectorValue _gravity;
  const bool _include_capillary_pressure;
  const bool _include_acceleration;
  const bool _include_electrical_force;
  const Real _minimum_denominator;
  const Real _active_tolerance;

  ADMaterialProperty<RankTwoTensor> & _darcy_mobility_ref;
  ADMaterialProperty<Real> & _combined_resistance;
  ADMaterialProperty<Real> & _resistance_denominator;
  ADMaterialProperty<RealVectorValue> & _spatial_relative_mass_flux;
  ADMaterialProperty<RealVectorValue> & _reference_relative_mass_flux;
};

