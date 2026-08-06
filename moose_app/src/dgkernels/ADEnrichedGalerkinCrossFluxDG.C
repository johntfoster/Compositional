#include "ADEnrichedGalerkinCrossFluxDG.h"

#include <algorithm>

registerMooseObject("MulticomponentReactiveFlowApp", ADEnrichedGalerkinCrossFluxDG);

InputParameters
ADEnrichedGalerkinCrossFluxDG::validParams()
{
  InputParameters params = ADDGKernel::validParams();
  params.addClassDescription(
      "Off-diagonal component-block EG facet term. For residual row a and component column b, "
      "it adds the signed D_ab penalty and adjoint-consistency contributions associated with "
      "the jump of the column enrichment. The full physical row flux is supplied once by the "
      "diagonal ADEnrichedGalerkinFluxDG object.");
  params.addRequiredCoupledVar("column_enrichment", "P0 enrichment of component column b.");
  params.addRequiredParam<MaterialPropertyName>(
      "cross_mobility_name", "AD spatial Onsager block D_ab.");
  params.addParam<Real>("epsilon", -1.0, "-1=SIPG, 0=IIPG, +1=NIPG.");
  params.addRangeCheckedParam<Real>(
      "sigma", 4.0, "sigma>=0", "Cross-component interior penalty multiplier.");
  return params;
}

ADEnrichedGalerkinCrossFluxDG::ADEnrichedGalerkinCrossFluxDG(
    const InputParameters & parameters)
  : ADDGKernel(parameters),
    _column_enrichment(adCoupledValue("column_enrichment")),
    _column_enrichment_neighbor(adCoupledNeighborValue("column_enrichment")),
    _mobility(getADMaterialProperty<RankTwoTensor>(
        getParam<MaterialPropertyName>("cross_mobility_name"))),
    _mobility_neighbor(getNeighborADMaterialProperty<RankTwoTensor>(
        getParam<MaterialPropertyName>("cross_mobility_name"))),
    _epsilon(getParam<Real>("epsilon")),
    _sigma(getParam<Real>("sigma"))
{
}

ADReal
ADEnrichedGalerkinCrossFluxDG::computeQpResidual(Moose::DGResidualType type)
{
  const auto normal = _normals[_qp];
  const ADReal jump = _column_enrichment[_qp] - _column_enrichment_neighbor[_qp];
  const ADRankTwoTensor average_mobility =
      0.5 * (_mobility[_qp] + _mobility_neighbor[_qp]);
  const Real h = std::min(_current_elem->hmin(), _neighbor_elem->hmin());
  const ADReal penalty = _sigma / h * (normal * (average_mobility * normal));

  switch (type)
  {
    case Moose::Element:
      return penalty * jump * _test[_i][_qp] +
             _epsilon * 0.5 * (_mobility[_qp].transpose() * _grad_test[_i][_qp]) * normal * jump;
    case Moose::Neighbor:
      return -penalty * jump * _test_neighbor[_i][_qp] +
             _epsilon * 0.5 *
                 (_mobility_neighbor[_qp].transpose() * _grad_test_neighbor[_i][_qp]) * normal *
                 jump;
  }
  return 0.0;
}
