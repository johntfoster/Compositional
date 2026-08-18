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
  const Real _nonnegativity_regularization;

  // Saturation-complement totals (value, gradient, and rate) that supply the
  // upper bound of the simplex-bounded transform.  For the gas saturation the
  // complement is the reconstructed water saturation, so the bounded gas
  // total lies pointwise in [0, 1 - Sw] and the oil saturation never leaves
  // the saturation simplex.
  const ADMaterialProperty<Real> * _complement_value;
  const ADMaterialProperty<RealVectorValue> * _complement_gradient;
  const ADMaterialProperty<Real> * _complement_dot;

  ADMaterialProperty<Real> & _total_value;
  ADMaterialProperty<RealVectorValue> & _total_gradient;
  ADMaterialProperty<Real> & _total_dot;
};
