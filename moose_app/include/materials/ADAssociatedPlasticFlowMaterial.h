#pragma once

#include "Material.h"

/** Associated true-plastic and scalar plastic-distension closures. */
class ADAssociatedPlasticFlowMaterial : public Material
{
public:
  static InputParameters validParams();
  ADAssociatedPlasticFlowMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;

  ADReal mobility(const std::vector<const ADMaterialProperty<Real> *> & properties,
                  Real constant,
                  const char * label) const;

  const ADMaterialProperty<RankTwoTensor> & _material_stress;
  const ADMaterialProperty<RankTwoTensor> & _elastic_true_deformation;
  const ADMaterialProperty<RankTwoTensor> & _distension_tensor;
  const ADMaterialProperty<RankTwoTensor> & _elastic_distension_tensor;
  const Real _plastic_deformation_mobility;
  const Real _plastic_distension_mobility;
  std::vector<const ADMaterialProperty<Real> *> _plastic_deformation_mobilities;
  std::vector<const ADMaterialProperty<Real> *> _plastic_distension_mobilities;
  ADMaterialProperty<RankTwoTensor> & _driving_stress;
  ADMaterialProperty<RankTwoTensor> & _plastic_deformation_log_rate;
  ADMaterialProperty<RankTwoTensor> & _plastic_distension_log_rate;
  ADMaterialProperty<Real> & _mean_material_stress;
  ADMaterialProperty<Real> & _scalar_plastic_distension_log_rate;
  ADMaterialProperty<Real> & _plastic_deformation_dissipation;
  ADMaterialProperty<Real> & _tensor_plastic_distension_dissipation;
  ADMaterialProperty<Real> & _plastic_distension_dissipation;
  ADMaterialProperty<Real> & _driving_stress_trace;
};
