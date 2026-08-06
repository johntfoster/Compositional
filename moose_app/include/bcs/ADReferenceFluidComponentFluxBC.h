#pragma once

#include "ADIntegratedBC.h"

class ADReferenceFluidComponentFluxBC : public ADIntegratedBC
{
public:
  static InputParameters validParams();

  ADReferenceFluidComponentFluxBC(const InputParameters & parameters);

protected:
  ADReal computeQpResidual() override;

  const Function & _outward_reference_phase_flux;
  const Function & _component_mass_fraction;
};
