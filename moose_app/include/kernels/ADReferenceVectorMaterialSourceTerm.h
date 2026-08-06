#pragma once
#include "ADKernelValue.h"
class ADReferenceVectorMaterialSourceTerm : public ADKernelValue
{
public:
  static InputParameters validParams();
  ADReferenceVectorMaterialSourceTerm(const InputParameters & parameters);
protected:
  ADReal precomputeQpResidual() override;
  const unsigned int _component;
  const ADMaterialProperty<Real> & _J;
  const ADMaterialProperty<RealVectorValue> & _source;
};
