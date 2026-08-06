#include "ADBlackOilRateBHPComplementarity.h"

#include "Function.h"
#include "metaphysicl/raw_type.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADBlackOilRateBHPComplementarity);

InputParameters
ADBlackOilRateBHPComplementarity::validParams()
{
  InputParameters params = ADScalarKernel::validParams();
  params.addClassDescription(
      "Enforces a time-dependent total surface-rate schedule and optional datum-BHP "
      "complementarity using a shared AD well-rate scalar.");
  params.addRequiredCoupledVar("well_rate", "Shared total surface-rate scalar.");
  params.addRequiredParam<Real>("target_surface_rate", "Constant signed surface-rate target.");
  params.addParam<FunctionName>(
      "target_surface_rate_function",
      "",
      "Optional time-dependent signed surface-rate target; when supplied, it overrides "
      "target_surface_rate.");
  params.addParam<bool>("apply_bhp_limit", false, "Apply a datum-BHP limit.");
  params.addParam<MooseEnum>(
      "bhp_limit_type", MooseEnum("minimum maximum", "minimum"), "Type of datum-BHP limit.");
  params.addParam<Real>("bhp_limit", 0.0, "Datum-BHP limit.");
  return params;
}

ADBlackOilRateBHPComplementarity::ADBlackOilRateBHPComplementarity(
    const InputParameters & parameters)
  : ADScalarKernel(parameters),
    _well_rate(adCoupledScalarValue("well_rate")),
    _target_surface_rate(getParam<Real>("target_surface_rate")),
    _target_surface_rate_function(
        getParam<FunctionName>("target_surface_rate_function").empty()
            ? nullptr
            : &getFunction("target_surface_rate_function")),
    _apply_bhp_limit(getParam<bool>("apply_bhp_limit")),
    _bhp_limit_type(getParam<MooseEnum>("bhp_limit_type")),
    _bhp_limit(getParam<Real>("bhp_limit"))
{
}

ADReal
ADBlackOilRateBHPComplementarity::computeQpResidual()
{
  const Real target_surface_rate =
      _target_surface_rate_function
          ? _target_surface_rate_function->value(_t, Point())
          : _target_surface_rate;
  if (!_apply_bhp_limit)
    return _well_rate[0] - target_surface_rate;

  const bool minimum = _bhp_limit_type == "minimum";
  const ADReal a =
      minimum ? target_surface_rate - _well_rate[0] : _well_rate[0] - target_surface_rate;
  const ADReal b = minimum ? _u[_i] - _bhp_limit : _bhp_limit - _u[_i];
  const ADReal norm_squared = a * a + b * b;
  if (MetaPhysicL::raw_value(norm_squared) == 0.0)
    return -a - b;
  return sqrt(norm_squared) - a - b;
}

