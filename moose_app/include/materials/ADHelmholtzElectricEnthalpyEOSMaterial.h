#pragma once

#include "DerivativeMaterialInterface.h"
#include "Material.h"

class PhaseRegistry;

/**
 * Thermodynamic closure for the combined phase storage A + omega^+ at fixed
 * phase volume, retaining material internal energy and electrical state rates separately.
 */
class ADHelmholtzElectricEnthalpyEOSMaterial
  : public DerivativeMaterialInterface<Material>
{
public:
  static InputParameters validParams();

  ADHelmholtzElectricEnthalpyEOSMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;

  const std::string _phase_name;
  const PhaseRegistry & _phase_registry;
  const unsigned int _n_components;
  const MaterialPropertyName _helmholtz_density_name;
  const MaterialPropertyName _electric_enthalpy_name;
  const ADMaterialProperty<Real> & _helmholtz_density;
  const ADMaterialProperty<Real> & _electric_enthalpy;
  const ADVariableValue & _temperature;
  const VariableName _temperature_name;
  const ADVariableValue & _phase_fraction;
  std::vector<const ADVariableValue *> _partial_densities;
  std::vector<VariableName> _partial_density_names;
  std::vector<const ADMaterialProperty<Real> *> _helmholtz_density_derivatives;
  std::vector<const ADMaterialProperty<Real> *> _electric_enthalpy_density_derivatives;
  const ADMaterialProperty<Real> & _helmholtz_temperature_derivative;
  const ADMaterialProperty<Real> & _electric_enthalpy_temperature_derivative;

  ADMaterialProperty<Real> & _pressure;
  ADMaterialProperty<Real> & _material_pressure;
  ADMaterialProperty<Real> & _dielectric_pressure_correction;
  ADMaterialProperty<Real> & _intrinsic_density;
  ADMaterialProperty<Real> & _bulk_phase_density;
  ADMaterialProperty<Real> & _specific_helmholtz_free_energy;
  ADMaterialProperty<Real> & _specific_internal_energy;
  ADMaterialProperty<Real> & _entropy_density;
  ADMaterialProperty<Real> & _electric_phase_fraction_rate_coefficient;
  ADMaterialProperty<Real> & _electric_temperature_rate_coefficient;
  std::vector<ADMaterialProperty<Real> *> _neutral_chemical_potentials;
  std::vector<ADMaterialProperty<Real> *> _electric_partial_density_rate_coefficients;
};
