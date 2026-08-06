#pragma once

#include "Material.h"

/**
 * Assembles one selectable stress-free-map composition correction from theory Eq. (183):
 *   sign tr[C (dG0/deta_alpha) G0^{-1}].
 *
 * Use one instance for the distension map A0 and another for the true-deformation
 * map Fbar0.  Their scalar outputs are stitched into ADTheoryCompositionProjectionMaterial.
 */
class ADCompositionStressMapCorrectionMaterial : public Material
{
public:
  static InputParameters validParams();

  ADCompositionStressMapCorrectionMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;

  const ADMaterialProperty<RankTwoTensor> & _coefficient_tensor;
  const ADMaterialProperty<RankTwoTensor> & _stress_free_map_inverse;
  const Real _sign;
  std::vector<const ADMaterialProperty<RankTwoTensor> *> _map_derivatives;
  std::vector<ADMaterialProperty<Real> *> _corrections;
};
