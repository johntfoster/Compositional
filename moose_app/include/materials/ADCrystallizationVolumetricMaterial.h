#pragma once

#include "Material.h"

/**
 * Scalar distension/true-volume specialization of the manuscript
 * crystallization volumetric energy and Biot stress split.
 */
class ADCrystallizationVolumetricMaterial : public Material
{
public:
  static InputParameters validParams();
  ADCrystallizationVolumetricMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;
  MaterialPropertyName prefixedName(const std::string & suffix) const;

  const ADMaterialProperty<Real> & _distension;
  const ADMaterialProperty<Real> & _true_jacobian;
  const ADMaterialProperty<Real> & _total_jacobian;
  const ADMaterialProperty<Real> & _equivalent_pressure;
  const ADMaterialProperty<Real> * _biot_coefficient;
  const Real _constant_biot_coefficient;
  const Real _bulk_modulus;
  const std::string _property_prefix;

  ADMaterialProperty<Real> & _reconstructed_jacobian;
  ADMaterialProperty<Real> & _volumetric_split_residual;
  ADMaterialProperty<Real> & _logarithmic_volume_strain;
  ADMaterialProperty<Real> & _transformed_volumetric_energy;
  ADMaterialProperty<Real> & _double_prime_mean_stress;
  ADMaterialProperty<Real> & _prime_mean_stress;
  ADMaterialProperty<Real> & _distension_conjugate;
  ADMaterialProperty<RankTwoTensor> & _double_prime_stress;
  ADMaterialProperty<RankTwoTensor> & _prime_stress;
};
