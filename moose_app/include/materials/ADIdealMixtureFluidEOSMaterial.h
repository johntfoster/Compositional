#pragma once

#include "Material.h"

class ADIdealMixtureFluidEOSMaterial : public Material
{
public:
  static InputParameters validParams();

  ADIdealMixtureFluidEOSMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;

  const unsigned int _n_components;

  const ADMaterialProperty<Real> & _J;
  const ADVariableValue & _pressure;
  const ADVariableValue * _pressure_enrichment;
  const ADVariableValue & _temperature;
  const ADVariableValue & _porosity;
  std::vector<const ADVariableValue *> _component_mass_fractions;

  const Real _reference_density;
  const Real _reference_pressure;
  const Real _compressibility;
  const Real _mixture_constant;
  const bool _enforce_mass_fraction_sum;
  const Real _mass_fraction_sum_tol;
  const std::vector<Real> _component_reference_potentials;

  ADMaterialProperty<Real> & _intrinsic_density;
  ADMaterialProperty<Real> & _specific_helmholtz_free_energy;
  ADMaterialProperty<Real> & _current_phase_mass_density;
  ADMaterialProperty<Real> & _mass_fraction_sum;
  ADMaterialProperty<Real> & _pressure_from_helmholtz_density_derivative;
  ADMaterialProperty<Real> & _pressure_identity_residual;
  std::vector<ADMaterialProperty<Real> *> _reference_component_storages;
  std::vector<ADMaterialProperty<Real> *> _neutral_component_potentials;
};
