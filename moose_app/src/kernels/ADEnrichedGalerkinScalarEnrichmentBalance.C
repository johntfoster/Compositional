#include "ADEnrichedGalerkinScalarEnrichmentBalance.h"

#include "Function.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADEnrichedGalerkinScalarEnrichmentBalance);

InputParameters
ADEnrichedGalerkinScalarEnrichmentBalance::validParams()
{
  InputParameters params = ADTimeKernel::validParams();
  params += FunctionInterface::validParams();
  params.addClassDescription(
      "Elementwise enrichment row for a scalar enriched-Galerkin balance. The row tests "
      "the same storage/source term as the continuous backbone against the P0 basis. A "
      "zero-mean anchor may be added for fluxless algebraic tau reductions.");
  params.addRequiredCoupledVar("backbone", "Continuous P1 backbone paired with this enrichment.");
  params.addParam<Real>("time_coefficient", 1.0, "Constant multiplier on the total time rate.");
  params.addParam<MaterialPropertyName>(
      "time_coefficient_name", "", "Optional material multiplier on the total time rate.");
  params.addParam<MaterialPropertyName>(
      "reference_component_storage_rate_name",
      "",
      "Optional AD reference component storage rate. When supplied, this property replaces "
      "the coefficient times the total scalar-field rate.");
  params.addParam<MaterialPropertyName>("source_name", "", "Optional reference source term.");
  params.addParam<FunctionName>(
      "source_function", "0", "Reference source function used when source_name is empty.");
  params.addRangeCheckedParam<Real>(
      "anchor_coefficient", 0.0, "anchor_coefficient>=0", "Optional P0 anchor coefficient.");
  params.addParam<Real>("anchor_value", 0.0, "Value used by the optional P0 anchor.");
  return params;
}

ADEnrichedGalerkinScalarEnrichmentBalance::ADEnrichedGalerkinScalarEnrichmentBalance(
    const InputParameters & parameters)
  : ADTimeKernel(parameters),
    _backbone_dot(adCoupledDot("backbone")),
    _time_coefficient(getParam<Real>("time_coefficient")),
    _time_coefficient_property(getParam<MaterialPropertyName>("time_coefficient_name").empty()
                                   ? nullptr
                                   : &getADMaterialProperty<Real>(
                                         getParam<MaterialPropertyName>("time_coefficient_name"))),
    _reference_component_storage_rate(
        getParam<MaterialPropertyName>("reference_component_storage_rate_name").empty()
            ? nullptr
            : &getADMaterialProperty<Real>(
                  getParam<MaterialPropertyName>("reference_component_storage_rate_name"))),
    _source(getParam<MaterialPropertyName>("source_name").empty()
                ? nullptr
                : &getADMaterialProperty<Real>(getParam<MaterialPropertyName>("source_name"))),
    _source_function(getFunction("source_function")),
    _anchor_coefficient(getParam<Real>("anchor_coefficient")),
    _anchor_value(getParam<Real>("anchor_value"))
{
  if (_reference_component_storage_rate &&
      (isParamSetByUser("time_coefficient") || isParamSetByUser("time_coefficient_name")))
    paramError("reference_component_storage_rate_name",
               "Do not also supply time_coefficient or time_coefficient_name when an AD "
               "reference component storage rate is used.");
}

ADReal
ADEnrichedGalerkinScalarEnrichmentBalance::computeQpResidual()
{
  const ADReal source = _source ? (*_source)[_qp] : _source_function.value(_t, _q_point[_qp]);
  ADReal storage_rate;
  if (_reference_component_storage_rate)
    storage_rate = (*_reference_component_storage_rate)[_qp];
  else
  {
    const ADReal coefficient =
        _time_coefficient_property ? (*_time_coefficient_property)[_qp] : _time_coefficient;
    const ADReal total_dot = _backbone_dot[_qp] + _u_dot[_qp];
    storage_rate = coefficient * total_dot;
  }
  return _test[_i][_qp] * (storage_rate - source +
                           _anchor_coefficient * (_u[_qp] - _anchor_value));
}
