#pragma once

#include "ADIntegratedBC.h"

class Function;
class PhaseRegistry;

/** Prescribed reference-area traction for one component of a full phase momentum solve. */
class ADRegisteredPhaseMomentumTractionBC : public ADIntegratedBC
{
public:
  static InputParameters validParams();
  ADRegisteredPhaseMomentumTractionBC(const InputParameters & parameters);

protected:
  ADReal computeQpResidual() override;

  const std::string _phase_name;
  const PhaseRegistry & _phase_registry;
  const Function & _traction;
};
