#pragma once

#include "ADIntegratedBC.h"

class Function;

/** Prescribed solid-skeleton traction component per unit reference area. */
class ADReferenceSolidTractionBC : public ADIntegratedBC
{
public:
  static InputParameters validParams();

  ADReferenceSolidTractionBC(const InputParameters & parameters);

protected:
  ADReal computeQpResidual() override;

  const Function & _traction;
};
