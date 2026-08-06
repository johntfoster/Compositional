#pragma once

#include "Material.h"
#include "RankTwoTensor.h"

/** Phase-volume weighted electric displacement, its Piola pull-back, and charge. */
class ADMixtureElectricFieldMaterial : public Material
{
public:
  static InputParameters validParams();
  ADMixtureElectricFieldMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;

  std::vector<const ADVariableValue *> _phase_fractions;
  std::vector<const ADMaterialProperty<RealVectorValue> *> _phase_displacements;
  std::vector<const ADVariableValue *> _component_densities;
  const std::vector<Real> _specific_charges;
  const ADMaterialProperty<Real> & _J;
  const ADMaterialProperty<RankTwoTensor> & _F_inv;
  ADMaterialProperty<RealVectorValue> & _mixture_displacement;
  ADMaterialProperty<RealVectorValue> & _reference_displacement;
  ADMaterialProperty<Real> & _current_free_charge;
  ADMaterialProperty<Real> & _reference_free_charge;
};
