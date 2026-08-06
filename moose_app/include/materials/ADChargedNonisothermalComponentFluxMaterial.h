#pragma once

#include "Material.h"

/**
 * Current component flux driven by neutral-potential, electric, and thermal
 * gradients.
 */
class ADChargedNonisothermalComponentFluxMaterial : public Material {
public:
  static InputParameters validParams();

  ADChargedNonisothermalComponentFluxMaterial(
      const InputParameters &parameters);

protected:
  void computeQpProperties() override;

  const ADVariableGradient *_grad_neutral_potential;
  const ADMaterialProperty<RealVectorValue> *_neutral_potential_gradient;
  const ADVariableGradient *_grad_electric_potential;
  const ADMaterialProperty<RealVectorValue> *_electric_potential_gradient;
  const ADVariableGradient *_grad_temperature;
  const ADMaterialProperty<RealVectorValue> *_temperature_gradient;
  const Real _mobility;
  const ADMaterialProperty<Real> *_mobility_property;
  const Real _charge_number;
  const Real _thermal_force_coefficient;

  ADMaterialProperty<RealVectorValue> &_transport_force;
  ADMaterialProperty<RealVectorValue> &_current_component_flux;
  ADMaterialProperty<RealVectorValue> &_current_charge_flux;
  ADMaterialProperty<Real> &_electric_field_work;
};
