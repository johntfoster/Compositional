#pragma once

#include "Material.h"
#include "RankTwoTensor.h"

class ADScalarDiffusionReferenceFluxMaterial : public Material
{
public:
  static InputParameters validParams();

  ADScalarDiffusionReferenceFluxMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;

  const ADVariableGradient & _grad_backbone;
  const ADVariableGradient * const _grad_enrichment;
  const ADVariableSecond & _second_backbone;
  const ADVariableSecond * const _second_enrichment;
  const Real _diffusivity;
  ADMaterialProperty<RankTwoTensor> & _mobility;
  ADMaterialProperty<RealVectorValue> & _reference_flux;
  ADMaterialProperty<Real> * const _reference_flux_divergence;
};
