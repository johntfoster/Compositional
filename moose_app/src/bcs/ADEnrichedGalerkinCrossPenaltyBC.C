#include "ADEnrichedGalerkinCrossPenaltyBC.h"

#include "Function.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADEnrichedGalerkinCrossPenaltyBC);

InputParameters
ADEnrichedGalerkinCrossPenaltyBC::validParams()
{
  InputParameters params = ADIntegratedBC::validParams();
  params.addClassDescription(
      "Off-diagonal component-block EG weak-boundary term. For residual row a and component "
      "column b it adds the D_ab penalty and adjoint-consistency terms for the prescribed "
      "total column field; the physical row flux is supplied once by the diagonal EG BC.");
  params.addRequiredCoupledVar("column_backbone", "Continuous backbone of component column b.");
  params.addRequiredCoupledVar("column_enrichment", "P0 enrichment of component column b.");
  params.addRequiredParam<MaterialPropertyName>(
      "cross_mobility_name", "AD spatial Onsager block D_ab.");
  params.addParam<Real>("value", 0.0, "Boundary value when no function is supplied.");
  params.addParam<FunctionName>("function", "Boundary value function for component column b.");
  params.addParam<Real>("epsilon", -1.0, "-1=SIPG, 0=IIPG, +1=NIPG.");
  params.addRangeCheckedParam<Real>(
      "sigma", 4.0, "sigma>=0", "Cross-component boundary penalty multiplier.");
  return params;
}

ADEnrichedGalerkinCrossPenaltyBC::ADEnrichedGalerkinCrossPenaltyBC(
    const InputParameters & parameters)
  : ADIntegratedBC(parameters),
    _column_backbone(adCoupledValue("column_backbone")),
    _column_enrichment(adCoupledValue("column_enrichment")),
    _mobility(getADMaterialProperty<RankTwoTensor>(
        getParam<MaterialPropertyName>("cross_mobility_name"))),
    _value(getParam<Real>("value")),
    _function(isParamValid("function") ? &getFunction("function") : nullptr),
    _epsilon(getParam<Real>("epsilon")),
    _sigma(getParam<Real>("sigma"))
{
}

ADReal
ADEnrichedGalerkinCrossPenaltyBC::computeQpResidual()
{
  const auto normal = _normals[_qp];
  const ADReal total_column_value =
      _column_backbone[_qp] + _column_enrichment[_qp];
  const Real prescribed_value = _function ? _function->value(_t, _q_point[_qp]) : _value;
  const ADReal mismatch = total_column_value - prescribed_value;
  const ADReal normal_mobility = normal * (_mobility[_qp] * normal);
  const Real h = _current_elem->hmin();

  return _epsilon * (_mobility[_qp].transpose() * _grad_test[_i][_qp]) * normal * mismatch +
         _sigma / h * normal_mobility * mismatch * _test[_i][_qp];
}
