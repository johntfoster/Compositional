#pragma once

#include "ADDGKernel.h"

/** Conservative phase-by-phase upwind component flux for an elementwise balance row. */
class ADUpwindReferenceComponentFluxDG : public ADDGKernel
{
public:
  static InputParameters validParams();

  ADUpwindReferenceComponentFluxDG(const InputParameters & parameters);

protected:
  ADReal computeQpResidual(Moose::DGResidualType type) override;

  std::vector<const ADMaterialProperty<RealVectorValue> *> _phase_flux;
  std::vector<const ADMaterialProperty<RealVectorValue> *> _phase_flux_neighbor;
  std::vector<const ADMaterialProperty<Real> *> _phase_fraction;
  std::vector<const ADMaterialProperty<Real> *> _phase_fraction_neighbor;
  const ADMaterialProperty<RankTwoTensor> * const _mobility;
  const ADMaterialProperty<RankTwoTensor> * const _mobility_neighbor;
  const Real _sigma;
};
