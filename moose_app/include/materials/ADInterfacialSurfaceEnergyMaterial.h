#pragma once

#include "Material.h"

/**
 * Assembles the general interfacial Helmholtz state
 * gamma({S_f}, h, theta_F) from user-provided AD values and derivatives.
 */
class ADInterfacialSurfaceEnergyMaterial : public Material
{
public:
  static InputParameters validParams();

  ADInterfacialSurfaceEnergyMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;

  MaterialPropertyName prefixedName(const std::string & suffix) const;

  const std::vector<std::string> _phase_names;
  const std::string _property_prefix;
  const ADMaterialProperty<Real> & _surface_energy;
  const ADMaterialProperty<Real> * _fluid_temperature;
  const ADMaterialProperty<Real> * _temperature_derivative;
  const ADMaterialProperty<Real> * _temperature_rate;

  std::vector<const ADMaterialProperty<Real> *> _phase_volume_fractions;
  std::vector<const ADMaterialProperty<Real> *> _phase_volume_fraction_rates;
  std::vector<const ADMaterialProperty<Real> *> _saturation_derivatives;
  std::vector<const ADMaterialProperty<Real> *> _history_derivatives;
  std::vector<const ADMaterialProperty<Real> *> _history_rates;

  ADMaterialProperty<Real> & _fluid_volume_fraction;
  ADMaterialProperty<Real> & _stored_interfacial_energy_density;
  ADMaterialProperty<Real> & _stored_interfacial_energy_rate;
  ADMaterialProperty<Real> & _history_storage_rate;
  ADMaterialProperty<Real> & _temperature_storage_rate;
  ADMaterialProperty<Real> & _history_dissipation_rate;
  ADMaterialProperty<Real> & _history_entropy_production_rate;
  std::vector<ADMaterialProperty<Real> *> _saturations;
  std::vector<ADMaterialProperty<Real> *> _phase_interfacial_potentials;
  std::vector<ADMaterialProperty<Real> *> _phase_storage_rate_contributions;
  std::vector<ADMaterialProperty<Real> *> _history_rate_coefficients;
  ADMaterialProperty<Real> * _temperature_rate_coefficient;
};
