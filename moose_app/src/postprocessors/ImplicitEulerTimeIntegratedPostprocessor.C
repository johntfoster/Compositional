#include "ImplicitEulerTimeIntegratedPostprocessor.h"

registerMooseObject("MulticomponentReactiveFlowApp", ImplicitEulerTimeIntegratedPostprocessor);

InputParameters
ImplicitEulerTimeIntegratedPostprocessor::validParams()
{
  InputParameters params = GeneralPostprocessor::validParams();
  params.addClassDescription(
      "Integrates a postprocessor rate using cumulative_n = cumulative_old + dt * rate_n.");
  params.addRequiredParam<PostprocessorName>("value", "Postprocessor rate to integrate.");
  return params;
}

ImplicitEulerTimeIntegratedPostprocessor::ImplicitEulerTimeIntegratedPostprocessor(
    const InputParameters & parameters)
  : GeneralPostprocessor(parameters),
    _value(0.0),
    _value_old(getPostprocessorValueOldByName(name())),
    _rate(getPostprocessorValue("value"))
{
}

void
ImplicitEulerTimeIntegratedPostprocessor::initialize()
{
}

void
ImplicitEulerTimeIntegratedPostprocessor::execute()
{
  _value = _value_old + _dt * _rate;
}

Real
ImplicitEulerTimeIntegratedPostprocessor::getValue() const
{
  return _value;
}
