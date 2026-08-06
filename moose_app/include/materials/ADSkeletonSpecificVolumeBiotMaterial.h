#pragma once

#include "DerivativeMaterialInterface.h"
#include "Material.h"

/**
 * Reduced explicit closure for the nonlinear finite-deformation Biot coefficient from an
 * intrinsic skeleton specific-volume tangent at fixed equivalent pressure.
 */
class ADSkeletonSpecificVolumeBiotMaterial : public DerivativeMaterialInterface<Material>
{
public:
  static InputParameters validParams();

  ADSkeletonSpecificVolumeBiotMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;

  const MaterialPropertyName _specific_volume_name;
  const MaterialPropertyName _specific_volume_jacobian_derivative_name;
  const ADMaterialProperty<Real> & _specific_volume;
  const ADMaterialProperty<Real> * _specific_volume_jacobian_derivative;
  const Real _reference_specific_volume;
  const ADMaterialProperty<Real> * _solid_J;
  const ADMaterialProperty<Real> * _aggregate_solid_volume_fraction;
  std::vector<const ADMaterialProperty<Real> *> _skeleton_component_reference_accumulations;
  const bool _check_mass_consistency;
  const Real _mass_consistency_tolerance;

  ADMaterialProperty<Real> & _biot_coefficient;
  ADMaterialProperty<Real> & _intrinsic_skeleton_density;
  ADMaterialProperty<Real> & _mass_consistency_residual;
};
