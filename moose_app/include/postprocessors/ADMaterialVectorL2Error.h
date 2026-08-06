#pragma once

#include "ElementIntegralPostprocessor.h"

class Function;

class ADMaterialVectorL2Error : public ElementIntegralPostprocessor
{
public:
  static InputParameters validParams();

  ADMaterialVectorL2Error(const InputParameters & parameters);

  Real getValue() const override;

protected:
  Real computeQpIntegral() override;

  const ADMaterialProperty<RealVectorValue> & _property;
  const Function & _function;
};
