#pragma once

#include "Material.h"
#include "RankTwoTensor.h"

/**
 * Finite-deformation solid-reference kinematics for a two-dimensional
 * axisymmetric RZ domain. Tensor indices 0, 1, and 2 denote the radial,
 * axial, and circumferential directions, respectively.
 */
class ADAxisymmetricSolidReferenceKinematics : public Material
{
public:
  static InputParameters validParams();

  ADAxisymmetricSolidReferenceKinematics(const InputParameters & parameters);

  void initialSetup() override;

protected:
  void computeQpProperties() override;

  const ADVariableValue & _radial_displacement;
  const ADVariableValue & _axial_displacement;
  const VariableValue * const _radial_displacement_old;
  const ADVariableGradient & _radial_displacement_gradient;
  const ADVariableGradient & _axial_displacement_gradient;
  const VariableGradient * const _radial_displacement_gradient_old;
  const VariableGradient * const _axial_displacement_gradient_old;

  ADMaterialProperty<RankTwoTensor> & _F;
  ADMaterialProperty<Real> & _J;
  ADMaterialProperty<Real> & _J_dot;
  ADMaterialProperty<RankTwoTensor> & _F_inv;
  ADMaterialProperty<RankTwoTensor> & _J_F_inv;
};
