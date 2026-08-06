#include "ADEnrichedGalerkinCrossSymmetryDG.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADEnrichedGalerkinCrossSymmetryDG);

InputParameters
ADEnrichedGalerkinCrossSymmetryDG::validParams()
{
  InputParameters params = ADDGKernel::validParams();
  params.addClassDescription(
      "Off-diagonal component-block adjoint-consistency term for a continuous EG backbone "
      "row, using the jump of component-column enrichment b and spatial block D_ab.");
  params.addRequiredCoupledVar("column_enrichment", "P0 enrichment of component column b.");
  params.addRequiredParam<MaterialPropertyName>(
      "cross_mobility_name", "AD spatial Onsager block D_ab.");
  params.addParam<Real>("epsilon", -1.0, "-1=SIPG, 0=IIPG, +1=NIPG.");
  return params;
}

ADEnrichedGalerkinCrossSymmetryDG::ADEnrichedGalerkinCrossSymmetryDG(
    const InputParameters & parameters)
  : ADDGKernel(parameters),
    _column_enrichment(adCoupledValue("column_enrichment")),
    _column_enrichment_neighbor(adCoupledNeighborValue("column_enrichment")),
    _mobility(getADMaterialProperty<RankTwoTensor>(
        getParam<MaterialPropertyName>("cross_mobility_name"))),
    _mobility_neighbor(getNeighborADMaterialProperty<RankTwoTensor>(
        getParam<MaterialPropertyName>("cross_mobility_name"))),
    _epsilon(getParam<Real>("epsilon"))
{
}

ADReal
ADEnrichedGalerkinCrossSymmetryDG::computeQpResidual(Moose::DGResidualType type)
{
  const auto normal = _normals[_qp];
  const ADReal jump = _column_enrichment[_qp] - _column_enrichment_neighbor[_qp];
  switch (type)
  {
    case Moose::Element:
      return _epsilon * 0.5 *
             (_mobility[_qp].transpose() * _grad_test[_i][_qp]) * normal * jump;
    case Moose::Neighbor:
      return _epsilon * 0.5 *
             (_mobility_neighbor[_qp].transpose() * _grad_test_neighbor[_i][_qp]) * normal *
             jump;
  }
  return 0.0;
}
