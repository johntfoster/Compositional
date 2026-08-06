#pragma once

#include "Material.h"

/** Crystallization pressure, affinity, and equilibrium supersaturation closure. */
class ADCrystallizationPressureMaterial : public Material
{
public:
  static InputParameters validParams();
  ADCrystallizationPressureMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;
  MaterialPropertyName prefixedName(const std::string & suffix) const;

  const MooseEnum _pressure_model;
  const ADMaterialProperty<Real> & _intrinsic_density;
  const ADMaterialProperty<RankTwoTensor> & _material_stress;
  const ADMaterialProperty<Real> & _fluid_temperature;
  const ADMaterialProperty<Real> * _supersaturation;
  const ADMaterialProperty<Real> * _prescribed_pressure;
  const ADMaterialProperty<Real> * _reaction_affinity;
  const Real _gas_constant;
  const Real _molar_volume;
  const std::string _property_prefix;

  ADMaterialProperty<Real> & _specific_volume;
  ADMaterialProperty<Real> & _mean_material_stress;
  ADMaterialProperty<Real> & _crystallization_pressure;
  ADMaterialProperty<Real> & _volumetric_affinity;
  ADMaterialProperty<Real> & _equilibrium_supersaturation;
  ADMaterialProperty<Real> & _affinity_residual;
};
