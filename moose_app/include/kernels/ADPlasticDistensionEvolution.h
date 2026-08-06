#pragma once

#include "ADTimeKernel.h"

class Function;

/** One component of dot(A_p)=L_A A_p for tensor plastic distension. */
class ADPlasticDistensionEvolution : public ADTimeKernel
{
public:
  static InputParameters validParams();
  ADPlasticDistensionEvolution(const InputParameters & parameters);

protected:
  ADReal computeQpResidual() override;

  const unsigned int _dim;
  const unsigned int _row;
  const unsigned int _column;
  std::vector<const ADVariableValue *> _plastic_distension_components;
  const ADMaterialProperty<RankTwoTensor> & _plastic_distension_log_rate;
  const Function & _forcing;
};
