#include "ADEnrichedGalerkinPenaltyBC.h"

#include "Function.h"
#include "metaphysicl/raw_type.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADEnrichedGalerkinPenaltyBC);

InputParameters
ADEnrichedGalerkinPenaltyBC::validParams()
{
  InputParameters params = ADIntegratedBC::validParams();
  params.addClassDescription(
      "Weak Dirichlet boundary term for an EG enrichment variable with total field "
      "u_hat = u_backbone + u_enrichment.");
  params.addRequiredCoupledVar("backbone", "Continuous P1 backbone field.");
  params.addRequiredParam<MaterialPropertyName>("reference_flux_name", "Full reference flux.");
  params.addRequiredParam<MaterialPropertyName>("mobility_name", "Reference mobility tensor.");
  params.addParam<Real>("value", 0.0, "Boundary value when no function is supplied.");
  params.addParam<FunctionName>("function", "Boundary value function.");
  params.addParam<Real>("epsilon", -1.0, "-1=SIPG, 0=IIPG, +1=NIPG.");
  params.addRangeCheckedParam<Real>("sigma", 4.0, "sigma>=0", "Boundary penalty multiplier.");
  params.addParam<bool>(
      "absolute_mobility_penalty",
      false,
      "Use the frozen absolute value of n.M.n for penalty coercivity.");
  return params;
}

ADEnrichedGalerkinPenaltyBC::ADEnrichedGalerkinPenaltyBC(const InputParameters & parameters)
  : ADIntegratedBC(parameters),
    _backbone(adCoupledValue("backbone")),
    _reference_flux(
        getADMaterialProperty<RealVectorValue>(getParam<MaterialPropertyName>("reference_flux_name"))),
    _mobility(getADMaterialProperty<RankTwoTensor>(getParam<MaterialPropertyName>("mobility_name"))),
    _value(getParam<Real>("value")),
    _function(isParamValid("function") ? &getFunction("function") : nullptr),
    _epsilon(getParam<Real>("epsilon")),
    _sigma(getParam<Real>("sigma")),
    _absolute_mobility_penalty(getParam<bool>("absolute_mobility_penalty"))
{
}

ADReal
ADEnrichedGalerkinPenaltyBC::computeQpResidual()
{
  const auto normal = _normals[_qp];
  const ADReal total_boundary_value = _backbone[_qp] + _u[_qp];
  const Real prescribed_value = _function ? _function->value(_t, _q_point[_qp]) : _value;
  const ADReal mismatch = total_boundary_value - prescribed_value;
  ADReal normal_mobility = normal * (_mobility[_qp] * normal);
  if (_absolute_mobility_penalty)
  {
    const Real sign = MetaPhysicL::raw_value(normal_mobility) >= 0.0 ? 1.0 : -1.0;
    normal_mobility *= sign;
  }
  const Real h = _current_elem->hmin();

  return (_reference_flux[_qp] * normal) * _test[_i][_qp] +
         _epsilon * (_mobility[_qp] * _grad_test[_i][_qp]) * normal * mismatch +
         _sigma / h * normal_mobility * mismatch * _test[_i][_qp];
}
