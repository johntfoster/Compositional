#pragma once

#include "ADTimeKernel.h"

class Function;

/** One component of dot(Fbar_p)=Lbar_p Fbar_p. */
class ADPlasticDeformationEvolution : public ADTimeKernel
{
public:
  static InputParameters validParams();
  ADPlasticDeformationEvolution(const InputParameters & parameters);

protected:
  ADReal computeQpResidual() override;

  const unsigned int _dim;
  const unsigned int _row;
  const unsigned int _column;
  std::vector<const ADVariableValue *> _plastic_deformation_components;
  const ADVariableValue * _isochoric_multiplier;
  const ADMaterialProperty<RankTwoTensor> & _plastic_log_rate;
  const Function & _forcing;
};
