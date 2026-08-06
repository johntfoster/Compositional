#pragma once

#include "Material.h"

/**
 * Applies a symmetric positive-definite two-component Onsager matrix to two
 * spatial transport forces.
 */
class ADTwoComponentOnsagerFluxMaterial : public Material
{
public:
  static InputParameters validParams();

  ADTwoComponentOnsagerFluxMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;

  std::vector<const ADMaterialProperty<RealVectorValue> *> _transport_forces;
  const std::vector<Real> _onsager_matrix;

  ADMaterialProperty<RealVectorValue> & _component_0_flux;
  ADMaterialProperty<RealVectorValue> & _component_1_flux;
  ADMaterialProperty<Real> & _reciprocity_residual;
  ADMaterialProperty<Real> & _positive_definite_determinant;
  ADMaterialProperty<Real> & _dissipation;
};
