#pragma once

#include "Material.h"
#include "RankTwoTensor.h"

/** Effective first Piola stress for a compressible Neo-Hookean solid skeleton. */
class ADCompressibleNeoHookeanReferenceStressMaterial : public Material
{
public:
  static InputParameters validParams();

  ADCompressibleNeoHookeanReferenceStressMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;

  const ADMaterialProperty<RankTwoTensor> & _F;
  const ADMaterialProperty<Real> & _J;
  const ADMaterialProperty<RankTwoTensor> & _F_inv;

  ADMaterialProperty<RankTwoTensor> & _effective_first_piola;

  const Real _shear_modulus;
  const Real _lame_lambda;
};
