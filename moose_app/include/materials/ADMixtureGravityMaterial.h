#pragma once

#include "Material.h"

class ADMixtureGravityMaterial : public Material
{
public:
  static InputParameters validParams();
  ADMixtureGravityMaterial(const InputParameters & parameters);
protected:
  void computeQpProperties() override;
  std::vector<const ADMaterialProperty<Real> *> _densities;
  const RealVectorValue _gravity;
  ADMaterialProperty<Real> & _density;
  ADMaterialProperty<RealVectorValue> & _force;
};
