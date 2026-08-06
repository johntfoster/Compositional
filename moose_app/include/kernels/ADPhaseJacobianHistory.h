#pragma once

#include "ADTimeKernel.h"

class PhaseRegistry;
#include "RankTwoTensor.h"

class Function;

class ADPhaseJacobianHistory : public ADTimeKernel
{
public:
  static InputParameters validParams();

  ADPhaseJacobianHistory(const InputParameters & parameters);

protected:
  ADReal computeQpResidual() override;

  const std::string _phase_name;
  const PhaseRegistry & _phase_registry;
  const ADMaterialProperty<RealVectorValue> & _phase_reference_convective_velocity;
  const ADMaterialProperty<RankTwoTensor> & _phase_velocity_gradient_current;
  const ADMaterialProperty<Real> & _phase_J_history;
  const Function & _forcing;
};
