#pragma once

#include "Material.h"

/** Adds independently selectable pressure-gradient contributions. */
class ADPhasePressureGradientAssemblerMaterial : public Material
{
public:
  static InputParameters validParams();

  ADPhasePressureGradientAssemblerMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;

  const ADMaterialProperty<RealVectorValue> & _base_pressure_gradient;
  std::vector<const ADMaterialProperty<RealVectorValue> *> _correction_gradients;
  const std::vector<Real> _correction_scales;
  ADMaterialProperty<RealVectorValue> & _phase_pressure_gradient;
};
