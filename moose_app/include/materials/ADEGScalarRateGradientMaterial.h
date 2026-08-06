#pragma once

#include "Material.h"

/** Reference gradient of the material time rate of an EG scalar total. */
class ADEGScalarRateGradientMaterial : public Material
{
public:
  static InputParameters validParams();

  ADEGScalarRateGradientMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;

  const ADVariableGradient * _backbone_gradient_dot;
  const ADVariableGradient * _enrichment_gradient_dot;
  ADMaterialProperty<RealVectorValue> & _total_rate_gradient;
};
