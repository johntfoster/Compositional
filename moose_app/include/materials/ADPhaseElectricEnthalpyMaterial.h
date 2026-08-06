#pragma once

#include "Material.h"
#include "RankTwoTensor.h"

/**
 * Converts declarative derivatives of a phase electric enthalpy into electric
 * displacement and Maxwell stresses.
 */
class ADPhaseElectricEnthalpyMaterial : public Material
{
public:
  static InputParameters validParams();
  ADPhaseElectricEnthalpyMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;

  const std::string _phase;
  const unsigned int _dim;
  std::vector<const ADVariableValue *> _electric_field;
  const ADVariableValue & _phase_fraction;
  const ADMaterialProperty<Real> & _electric_enthalpy;
  std::vector<const ADMaterialProperty<Real> *> _enthalpy_field_derivatives;
  const ADMaterialProperty<Real> & _J;
  const ADMaterialProperty<RankTwoTensor> & _F_inv;
  ADMaterialProperty<RealVectorValue> & _electric_displacement;
  ADMaterialProperty<RankTwoTensor> & _maxwell_cauchy_stress;
  ADMaterialProperty<RankTwoTensor> & _maxwell_piola_stress;
};

