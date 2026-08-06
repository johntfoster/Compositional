#pragma once

#include "Material.h"

/** Reconstructs the manuscript solid distension/true-deformation plastic hierarchy. */
class ADSolidPlasticKinematicsMaterial : public Material
{
public:
  static InputParameters validParams();
  ADSolidPlasticKinematicsMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;
  ADRankTwoTensor coupledTensor(const std::vector<const ADVariableValue *> & components) const;

  const unsigned int _dim;
  const ADMaterialProperty<RankTwoTensor> & _solid_deformation_gradient;
  const ADMaterialProperty<RankTwoTensor> & _distension_stress_free_map;
  const ADMaterialProperty<RankTwoTensor> & _true_deformation_stress_free_map;
  std::vector<const ADVariableValue *> _distension_components;
  std::vector<const ADVariableValue *> _plastic_distension_components;
  std::vector<const ADVariableValue *> _plastic_true_deformation_components;

  ADMaterialProperty<RankTwoTensor> & _distension;
  ADMaterialProperty<RankTwoTensor> & _true_deformation;
  ADMaterialProperty<RankTwoTensor> & _elastic_distension;
  ADMaterialProperty<RankTwoTensor> & _elastic_true_deformation;
  ADMaterialProperty<Real> & _decomposition_error;
  ADMaterialProperty<Real> & _distension_split_error;
  ADMaterialProperty<Real> & _true_deformation_split_error;
};
