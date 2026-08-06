#include "ADMaterialVectorL2Error.h"

#include "Function.h"
#include "metaphysicl/raw_type.h"

#include <cmath>

registerMooseObject("MulticomponentReactiveFlowApp", ADMaterialVectorL2Error);

InputParameters
ADMaterialVectorL2Error::validParams()
{
  InputParameters params = ElementIntegralPostprocessor::validParams();
  params.addRequiredParam<MaterialPropertyName>("property", "AD vector material property.");
  params.addRequiredParam<FunctionName>(
      "gradient_function", "Analytic function whose gradient is the reference vector.");
  params.addClassDescription("Computes the L2 error between an AD vector material property and "
                             "the gradient of an analytic function.");
  return params;
}

ADMaterialVectorL2Error::ADMaterialVectorL2Error(const InputParameters & parameters)
  : ElementIntegralPostprocessor(parameters),
    _property(getADMaterialProperty<RealVectorValue>(getParam<MaterialPropertyName>("property"))),
    _function(getFunction("gradient_function"))
{
}

Real
ADMaterialVectorL2Error::getValue() const
{
  return std::sqrt(ElementIntegralPostprocessor::getValue());
}

Real
ADMaterialVectorL2Error::computeQpIntegral()
{
  const RealVectorValue diff =
      MetaPhysicL::raw_value(_property[_qp]) - _function.gradient(_t, _q_point[_qp]);
  return diff * diff;
}
