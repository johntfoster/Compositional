#pragma once

#include "Material.h"

/**
 * Generic semismooth phase-appearance complementarity closure.
 *
 * For phase amount a and a nonnegative stability gap b, this material exposes
 * Phi_FB(a,b)=sqrt(a^2+b^2+2 epsilon^2)-a-b.  The exact epsilon=0 form
 * enforces a>=0, b>=0, and a*b=0 without imposing a traditional flash law.
 */
class ADPhaseAppearanceComplementarityMaterial : public Material
{
public:
  static InputParameters validParams();

  ADPhaseAppearanceComplementarityMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;
  MaterialPropertyName outputName(const std::string & suffix) const;

  const ADVariableValue & _phase_amount;
  const ADMaterialProperty<Real> & _stability_gap;
  const Real _gap_scale;
  const Real _smoothing;
  const std::string _property_prefix;

  ADMaterialProperty<Real> & _normalized_stability_gap;
  ADMaterialProperty<Real> & _complementarity_residual;
  ADMaterialProperty<Real> & _phase_availability;
};
