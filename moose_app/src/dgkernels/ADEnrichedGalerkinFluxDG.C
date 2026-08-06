#include "ADEnrichedGalerkinFluxDG.h"

#include "metaphysicl/raw_type.h"

#include <algorithm>

registerMooseObject("MulticomponentReactiveFlowApp", ADEnrichedGalerkinFluxDG);

InputParameters
ADEnrichedGalerkinFluxDG::validParams()
{
  InputParameters params = ADDGKernel::validParams();
  params.addClassDescription(
      "Generic interior EG flux and penalty row for a P0 enrichment variable. The "
      "continuous backbone carries no jump, so the total-field jump is the enrichment "
      "jump.");
  params.addRequiredParam<MaterialPropertyName>("reference_flux_name", "Full reference flux.");
  params.addRequiredParam<MaterialPropertyName>("mobility_name", "Reference mobility tensor.");
  params.addParam<Real>("epsilon", -1.0, "-1=SIPG, 0=IIPG, +1=NIPG.");
  params.addRangeCheckedParam<Real>("sigma", 4.0, "sigma>=0", "Interior penalty multiplier.");
  params.addParam<bool>(
      "absolute_mobility_penalty",
      false,
      "Use the frozen absolute value of n.M.n for penalty coercivity.");
  return params;
}

ADEnrichedGalerkinFluxDG::ADEnrichedGalerkinFluxDG(const InputParameters & parameters)
  : ADDGKernel(parameters),
    _reference_flux(
        getADMaterialProperty<RealVectorValue>(getParam<MaterialPropertyName>("reference_flux_name"))),
    _reference_flux_neighbor(getNeighborADMaterialProperty<RealVectorValue>(
        getParam<MaterialPropertyName>("reference_flux_name"))),
    _mobility(getADMaterialProperty<RankTwoTensor>(getParam<MaterialPropertyName>("mobility_name"))),
    _mobility_neighbor(
        getNeighborADMaterialProperty<RankTwoTensor>(getParam<MaterialPropertyName>("mobility_name"))),
    _epsilon(getParam<Real>("epsilon")),
    _sigma(getParam<Real>("sigma")),
    _absolute_mobility_penalty(getParam<bool>("absolute_mobility_penalty"))
{
}

ADReal
ADEnrichedGalerkinFluxDG::computeQpResidual(Moose::DGResidualType type)
{
  const auto normal = _normals[_qp];
  const ADReal flux_normal = 0.5 * (_reference_flux[_qp] + _reference_flux_neighbor[_qp]) * normal;
  const ADReal jump = _u[_qp] - _u_neighbor[_qp];
  ADReal normal_mobility =
      0.5 * (normal * (_mobility[_qp] * normal) +
             normal * (_mobility_neighbor[_qp] * normal));
  if (_absolute_mobility_penalty)
  {
    const Real sign = MetaPhysicL::raw_value(normal_mobility) >= 0.0 ? 1.0 : -1.0;
    normal_mobility *= sign;
  }
  const Real h = std::min(_current_elem->hmin(), _neighbor_elem->hmin());
  const ADReal penalty = _sigma / h * normal_mobility;

  switch (type)
  {
    case Moose::Element:
      return (flux_normal + penalty * jump) * _test[_i][_qp] +
             _epsilon * 0.5 * (_mobility[_qp] * _grad_test[_i][_qp]) * normal * jump;
    case Moose::Neighbor:
      return -(flux_normal + penalty * jump) * _test_neighbor[_i][_qp] +
             _epsilon * 0.5 * (_mobility_neighbor[_qp] * _grad_test_neighbor[_i][_qp]) *
                 normal * jump;
  }
  return 0.0;
}
