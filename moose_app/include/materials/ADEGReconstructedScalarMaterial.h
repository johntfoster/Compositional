#pragma once

#include "Material.h"

class ADEGReconstructedScalarMaterial : public Material
{
public:
  static InputParameters validParams();

  ADEGReconstructedScalarMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;

  const ADVariableValue & _backbone;
  const ADVariableGradient & _grad_backbone;
  const ADVariableValue * _backbone_dot;
  const ADVariableValue * _enrichment;
  const ADVariableGradient * _grad_enrichment;
  const ADVariableValue * _enrichment_dot;
  const MooseEnum _value_transform;
  const Real _positive_regularization;

  ADMaterialProperty<Real> & _total_value;
  ADMaterialProperty<RealVectorValue> & _total_gradient;
  ADMaterialProperty<Real> & _total_dot;
};
