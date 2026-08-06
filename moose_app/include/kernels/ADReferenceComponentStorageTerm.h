#pragma once

#include "ADTimeKernel.h"

/**
 * Atomic storage term in a solid-reference component mass balance.
 *
 * Implements int test * a * d(variable)/dt dV.  The coefficient may be a
 * constant or an AD material property, so J, phase fraction, intrinsic density,
 * and composition factors can be assembled declaratively.
 */
class ADReferenceComponentStorageTerm : public ADTimeKernel
{
public:
  static InputParameters validParams();
  ADReferenceComponentStorageTerm(const InputParameters & parameters);

protected:
  ADReal computeQpResidual() override;

  const Real _coefficient;
  const ADMaterialProperty<Real> * _coefficient_property;
};
