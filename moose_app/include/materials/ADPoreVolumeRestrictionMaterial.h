#pragma once

#include "Material.h"

/** Shared-multiplier solid-phase and total-fluid pore-volume restrictions. */
class ADPoreVolumeRestrictionMaterial : public Material
{
public:
  static InputParameters validParams();
  ADPoreVolumeRestrictionMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;

  const ADVariableValue & _lambda;
  std::vector<const ADVariableValue *> _fluid_saturations;
  std::vector<const ADMaterialProperty<Real> *> _solid_pressures;
  std::vector<const ADMaterialProperty<Real> *> _solid_omega_plus;
  std::vector<const ADMaterialProperty<Real> *> _fluid_pressures;
  std::vector<const ADMaterialProperty<Real> *> _fluid_omega_plus;
  std::vector<const ADMaterialProperty<Real> *> _fluid_gamma;
  std::vector<ADMaterialProperty<Real> *> _solid_residuals;
  ADMaterialProperty<Real> & _fluid_residual;
  ADMaterialProperty<Real> & _saturation_sum_residual;
};
