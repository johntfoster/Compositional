#pragma once

#include "Material.h"

/** Composes L = mu_hat - psi + tau_offset and, optionally, psi + L. */
class ADGeneralizedTransferWorkMaterial : public Material {
public:
  static InputParameters validParams();
  ADGeneralizedTransferWorkMaterial(const InputParameters &parameters);

protected:
  void computeQpProperties() override;

  const ADMaterialProperty<Real> &_chemical_potential;
  const ADMaterialProperty<Real> &_specific_helmholtz;
  const ADMaterialProperty<Real> &_tau_transfer_offset;
  ADMaterialProperty<Real> &_generalized_transfer_work;
  ADMaterialProperty<Real> *_neutral_conversion_coefficient;
};

