#include "ADMaterialRankTwoComponentL2Error.h"

#include "Function.h"
#include "metaphysicl/raw_type.h"

#include <cmath>

registerMooseObject("MulticomponentReactiveFlowApp", ADMaterialRankTwoComponentL2Error);

InputParameters
ADMaterialRankTwoComponentL2Error::validParams()
{
  InputParameters params = ElementIntegralPostprocessor::validParams();
  params.addRequiredParam<MaterialPropertyName>("property", "AD rank-two material property.");
  params.addRequiredRangeCheckedParam<unsigned int>("row", "row<3", "Tensor row.");
  params.addRequiredRangeCheckedParam<unsigned int>("column", "column<3", "Tensor column.");
  params.addRequiredParam<FunctionName>("function", "Analytic component function.");
  params.addClassDescription(
      "Computes the L2 error of one component of an AD rank-two material property.");
  return params;
}

ADMaterialRankTwoComponentL2Error::ADMaterialRankTwoComponentL2Error(
    const InputParameters & parameters)
  : ElementIntegralPostprocessor(parameters),
    _property(getADMaterialProperty<RankTwoTensor>(getParam<MaterialPropertyName>("property"))),
    _row(getParam<unsigned int>("row")),
    _column(getParam<unsigned int>("column")),
    _function(getFunction("function"))
{
}

Real
ADMaterialRankTwoComponentL2Error::getValue() const
{
  return std::sqrt(ElementIntegralPostprocessor::getValue());
}

Real
ADMaterialRankTwoComponentL2Error::computeQpIntegral()
{
  const Real diff = MetaPhysicL::raw_value(_property[_qp](_row, _column)) -
                    _function.value(_t, _q_point[_qp]);
  return diff * diff;
}
