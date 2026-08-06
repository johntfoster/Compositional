#include "ADEnrichedGalerkinScalarBalance.h"

#include "Function.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADEnrichedGalerkinScalarBalance);

InputParameters
ADEnrichedGalerkinScalarBalance::validParams()
{
  InputParameters params = ADTimeKernel::validParams();
  params += FunctionInterface::validParams();
  params.addClassDescription(
      "Continuous backbone row for a scalar enriched-Galerkin balance. The storage term "
      "uses the total rate of backbone plus optional enrichment; the volume flux term is "
      "paired with enrichment DG facet fluxes.");
  params.addCoupledVar("enrichment", "P0 enrichment variable paired with this backbone.");
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
  params.addParam<MaterialPropertyName>(
      "reference_flux_name", "", "Optional full reference flux for this balance.");
  return params;
}

ADEnrichedGalerkinScalarBalance::ADEnrichedGalerkinScalarBalance(
    const InputParameters & parameters)
  : ADTimeKernel(parameters),
    _enrichment_dot(isCoupled("enrichment") ? &adCoupledDot("enrichment") : nullptr),
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
    _reference_flux(getParam<MaterialPropertyName>("reference_flux_name").empty()
                        ? nullptr
                        : &getADMaterialProperty<RealVectorValue>(
                              getParam<MaterialPropertyName>("reference_flux_name")))
{
  if (_reference_component_storage_rate &&
      (isParamSetByUser("time_coefficient") || isParamSetByUser("time_coefficient_name")))
    paramError("reference_component_storage_rate_name",
               "Do not also supply time_coefficient or time_coefficient_name when an AD "
               "reference component storage rate is used.");
}

ADReal
ADEnrichedGalerkinScalarBalance::computeQpResidual()
{
  ADReal storage_rate;
  if (_reference_component_storage_rate)
    storage_rate = (*_reference_component_storage_rate)[_qp];
  else
  {
    const ADReal coefficient =
        _time_coefficient_property ? (*_time_coefficient_property)[_qp] : _time_coefficient;
    const ADReal total_dot = _u_dot[_qp] + (_enrichment_dot ? (*_enrichment_dot)[_qp] : 0.0);
    storage_rate = coefficient * total_dot;
  }
  const ADReal source = _source ? (*_source)[_qp] : _source_function.value(_t, _q_point[_qp]);

  ADReal residual = _test[_i][_qp] * (storage_rate - source);
  if (_reference_flux)
    residual -= _grad_test[_i][_qp] * (*_reference_flux)[_qp];
  return residual;
}
