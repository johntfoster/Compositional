#include "ADEnrichedGalerkinSymmetryDG.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADEnrichedGalerkinSymmetryDG);

InputParameters
ADEnrichedGalerkinSymmetryDG::validParams()
{
  InputParameters params = ADDGKernel::validParams();
  params.addClassDescription(
      "Continuous-row adjoint-consistency term for a scalar EG interior penalty form.");
  params.addRequiredCoupledVar("enrichment", "P0 enrichment variable whose jump is used.");
  params.addRequiredParam<MaterialPropertyName>("mobility_name", "Reference mobility tensor.");
  params.addParam<Real>("epsilon", -1.0, "-1=SIPG, 0=IIPG, +1=NIPG.");
  return params;
}

ADEnrichedGalerkinSymmetryDG::ADEnrichedGalerkinSymmetryDG(const InputParameters & parameters)
  : ADDGKernel(parameters),
    _enrichment(adCoupledValue("enrichment")),
    _enrichment_neighbor(adCoupledNeighborValue("enrichment")),
    _mobility(getADMaterialProperty<RankTwoTensor>(getParam<MaterialPropertyName>("mobility_name"))),
    _mobility_neighbor(
        getNeighborADMaterialProperty<RankTwoTensor>(getParam<MaterialPropertyName>("mobility_name"))),
    _epsilon(getParam<Real>("epsilon"))
{
}

ADReal
ADEnrichedGalerkinSymmetryDG::computeQpResidual(Moose::DGResidualType type)
{
  const auto normal = _normals[_qp];
  const ADReal jump = _enrichment[_qp] - _enrichment_neighbor[_qp];
  switch (type)
  {
    case Moose::Element:
      return _epsilon * 0.5 * (_mobility[_qp] * _grad_test[_i][_qp]) * normal * jump;
    case Moose::Neighbor:
      return _epsilon * 0.5 * (_mobility_neighbor[_qp] * _grad_test_neighbor[_i][_qp]) *
             normal * jump;
  }
  return 0.0;
}
