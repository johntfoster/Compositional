#pragma once

#include "ElementIntegralPostprocessor.h"
#include "RankTwoTensor.h"

class Function;

/** L2 error of one component of an AD rank-two material property. */
class ADMaterialRankTwoComponentL2Error : public ElementIntegralPostprocessor
{
public:
  static InputParameters validParams();
  ADMaterialRankTwoComponentL2Error(const InputParameters & parameters);

  Real getValue() const override;

protected:
  Real computeQpIntegral() override;

  const ADMaterialProperty<RankTwoTensor> & _property;
  const unsigned int _row;
  const unsigned int _column;
  const Function & _function;
};
