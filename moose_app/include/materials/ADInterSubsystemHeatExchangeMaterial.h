#pragma once

#include "Material.h"

/** Conservative, entropy-producing heat exchange between fluid and solid subsystems. */
class ADInterSubsystemHeatExchangeMaterial : public Material
{
public:
  static InputParameters validParams();
  ADInterSubsystemHeatExchangeMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;

  const ADVariableValue * _fluid_temperature_variable;
  const ADVariableValue * _solid_temperature_variable;
  const ADMaterialProperty<Real> * _fluid_temperature_property;
  const ADMaterialProperty<Real> * _solid_temperature_property;
  const ADMaterialProperty<Real> * _coefficient_property;
  const Real _coefficient;
  ADMaterialProperty<Real> & _fluid_source;
  ADMaterialProperty<Real> & _solid_source;
  ADMaterialProperty<Real> & _exchange_cancellation;
  ADMaterialProperty<Real> & _entropy_production;
};
