#pragma once

#include "FunctionInterface.h"
#include "Material.h"
#include "RankTwoTensor.h"

/**
 * Fourier heat flux and source terms for a stationary solid-reference energy
 * balance.
 */
class ADReferenceThermalEnergyMaterial : public Material
{
public:
  static InputParameters validParams();

  ADReferenceThermalEnergyMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;

  const ADMaterialProperty<RealVectorValue> & _reference_temperature_gradient;
  const Real _thermal_conductivity;
  const ADMaterialProperty<Real> * _thermal_conductivity_property;
  const ADMaterialProperty<RankTwoTensor> & _F_inv;
  const ADMaterialProperty<RankTwoTensor> & _J_F_inv;
  const ADMaterialProperty<Real> & _J;
  std::vector<const ADMaterialProperty<Real> *> _electric_field_work;
  const Function & _current_volumetric_heat_supply;

  ADMaterialProperty<RealVectorValue> & _current_heat_flux;
  ADMaterialProperty<RealVectorValue> & _reference_heat_flux;
  ADMaterialProperty<Real> & _reference_electric_work;
  ADMaterialProperty<Real> & _reference_heat_supply;
  ADMaterialProperty<Real> & _reference_energy_source;
};
