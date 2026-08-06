#pragma once

#include "Material.h"
#include "RankTwoTensor.h"

class PhaseRegistry;

class ADStandardDarcyReferenceFluxMaterial : public Material
{
public:
  static InputParameters validParams();

  ADStandardDarcyReferenceFluxMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;

  const ADMaterialProperty<Real> & _J;
  const ADMaterialProperty<RankTwoTensor> & _F_inv;
  const ADVariableGradient & _grad_pressure;
  const ADVariableGradient * _grad_pressure_enrichment;
  const bool _include_capillary_pressure;
  const ADVariableGradient * _grad_capillary_pressure;
  const ADVariableGradient * _grad_capillary_pressure_enrichment;
  const MooseEnum _intrinsic_density_source;
  const ADVariableValue * _intrinsic_density_var;
  const ADMaterialProperty<Real> * _intrinsic_density_mat;
  const std::string _phase_name;
  const PhaseRegistry * _phase_registry;

  const Real _permeability;
  const Real _viscosity;
  const ADMaterialProperty<Real> * _viscosity_property;
  const ADMaterialProperty<Real> * _relative_permeability;
  const RealVectorValue _gravity;
  const bool _include_acceleration;
  std::vector<const ADVariableValue *> _phase_acceleration;

  ADMaterialProperty<RankTwoTensor> & _darcy_mobility_ref;
  ADMaterialProperty<RealVectorValue> & _reference_relative_mass_flux;
};
