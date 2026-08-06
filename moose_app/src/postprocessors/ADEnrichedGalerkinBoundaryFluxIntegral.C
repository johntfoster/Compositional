#include "ADEnrichedGalerkinBoundaryFluxIntegral.h"

#include "Function.h"
#include "metaphysicl/raw_type.h"

registerMooseObject("MulticomponentReactiveFlowApp",
                    ADEnrichedGalerkinBoundaryFluxIntegral);

InputParameters
ADEnrichedGalerkinBoundaryFluxIntegral::validParams()
{
  InputParameters params = SideIntegralPostprocessor::validParams();
  params.addClassDescription(
      "Integrates W dot N plus the current-mobility penalty flux used by the enriched-"
      "Galerkin weak Dirichlet boundary condition for a unit balance test function.");
  params.addRequiredCoupledVar("backbone", "Continuous P1 backbone field.");
  params.addRequiredCoupledVar("enrichment", "P0 enrichment field.");
  params.addRequiredParam<MaterialPropertyName>("reference_flux_name", "Full reference flux.");
  params.addRequiredParam<MaterialPropertyName>("mobility_name", "Reference mobility tensor.");
  params.addParam<Real>("value", 0.0, "Boundary value when no function is supplied.");
  params.addParam<FunctionName>("function", "Boundary value function.");
  params.addRangeCheckedParam<Real>("sigma", 4.0, "sigma>=0", "Boundary penalty multiplier.");
  params.addParam<bool>(
      "absolute_mobility_penalty",
      false,
      "Use the frozen absolute value of N dot M dot N for penalty coercivity.");
  return params;
}

ADEnrichedGalerkinBoundaryFluxIntegral::ADEnrichedGalerkinBoundaryFluxIntegral(
    const InputParameters & parameters)
  : SideIntegralPostprocessor(parameters),
    _backbone(adCoupledValue("backbone")),
    _enrichment(adCoupledValue("enrichment")),
    _reference_flux(
        getADMaterialProperty<RealVectorValue>(getParam<MaterialPropertyName>("reference_flux_name"))),
    _mobility(getADMaterialProperty<RankTwoTensor>(getParam<MaterialPropertyName>("mobility_name"))),
    _value(getParam<Real>("value")),
    _function(isParamValid("function") ? &getFunction("function") : nullptr),
    _sigma(getParam<Real>("sigma")),
    _absolute_mobility_penalty(getParam<bool>("absolute_mobility_penalty"))
{
}

Real
ADEnrichedGalerkinBoundaryFluxIntegral::computeQpIntegral()
{
  const auto normal = _normals[_qp];
  const Real prescribed_value = _function ? _function->value(_t, _q_point[_qp]) : _value;
  const ADReal mismatch = _backbone[_qp] + _enrichment[_qp] - prescribed_value;
  ADReal normal_mobility = normal * (_mobility[_qp] * normal);
  if (_absolute_mobility_penalty)
  {
    const Real sign = MetaPhysicL::raw_value(normal_mobility) >= 0.0 ? 1.0 : -1.0;
    normal_mobility *= sign;
  }
  const Real h = _current_elem->hmin();
  return MetaPhysicL::raw_value(_reference_flux[_qp] * normal +
                                _sigma / h * normal_mobility * mismatch);
}
