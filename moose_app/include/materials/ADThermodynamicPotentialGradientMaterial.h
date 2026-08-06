#pragma once

#include "Material.h"

/**
 * Forms the reference gradient of a state-dependent thermodynamic potential.
 *
 * For a potential psi(y_1,...,y_n), the object evaluates
 *
 *   Grad_X(psi) = direct_gradient + sum_a psi_,y_a Grad_X(y_a).
 *
 * The derivatives and state gradients are supplied as named AD material
 * properties.  This makes electrical enthalpy, chemical potential, surface
 * energy, and other constitutive potentials independently composable from an
 * input deck.
 */
class ADThermodynamicPotentialGradientMaterial : public Material
{
public:
  static InputParameters validParams();
  ADThermodynamicPotentialGradientMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;

  std::vector<const ADMaterialProperty<Real> *> _derivatives;
  std::vector<const ADMaterialProperty<RealVectorValue> *> _state_gradients;
  const ADMaterialProperty<RealVectorValue> * _direct_gradient;
  ADMaterialProperty<RealVectorValue> & _potential_gradient;
};
