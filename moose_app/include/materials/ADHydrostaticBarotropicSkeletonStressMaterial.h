#pragma once

#include "Material.h"
#include "RankTwoTensor.h"

/**
 * Pressure-coupled effective skeleton stress for the hydrostatic barotropic
 * mineral-density closure used by the nonreacting binary benchmark.
 *
 * The double-prime potential is chosen so that its p=0 stress is the
 * compressible Neo-Hookean skeleton stress while
 *   rhobar_s/rhobar_s0 = exp((p_E + q_s(J_s))/K_s).
 * Its fixed-p_E deformation derivative gives P_s'' directly.  The Biot
 * transform recovers P_s'=P_s''+(1-B_s)p_E J_s F_s^{-T}; consequently the
 * momentum stress is equivalently P_s'-p_E J_s F_s^{-T} or
 * P_s''-B_s p_E J_s F_s^{-T}.
 */
class ADHydrostaticBarotropicSkeletonStressMaterial : public Material
{
public:
  static InputParameters validParams();

  ADHydrostaticBarotropicSkeletonStressMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;

  const ADMaterialProperty<RankTwoTensor> & _F;
  const ADMaterialProperty<Real> & _J;
  const ADMaterialProperty<RankTwoTensor> & _F_inv;
  const ADVariableValue & _equivalent_pressure;
  const ADVariableValue * _equivalent_pressure_enrichment;

  const Real _shear_modulus;
  const Real _lame_lambda;
  const Real _mineral_bulk_modulus;
  const Real _reference_solid_volume_fraction;

  ADMaterialProperty<RankTwoTensor> & _effective_first_piola;
  ADMaterialProperty<Real> & _mineral_effective_pressure;
  ADMaterialProperty<Real> & _mineral_effective_pressure_jacobian_derivative;
};
