#pragma once

#include "ADTimeKernel.h"

class PhaseRegistry;
#include "RankTwoTensor.h"

class Function;

class ADPhaseDeformationGradientHistory : public ADTimeKernel
{
public:
  static InputParameters validParams();

  ADPhaseDeformationGradientHistory(const InputParameters & parameters);

protected:
  ADReal computeQpResidual() override;

  const std::string _phase_name;
  const PhaseRegistry & _phase_registry;
  const unsigned int _row;
  const unsigned int _col;
  const ADMaterialProperty<RealVectorValue> & _phase_reference_convective_velocity;
  const ADMaterialProperty<RankTwoTensor> & _phase_velocity_gradient_current;
  const ADMaterialProperty<RankTwoTensor> & _phase_F;
  const Function & _forcing;
};
