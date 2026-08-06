#include "ADPlasticDeformationEvolution.h"

#include "Function.h"
#include "metaphysicl/raw_type.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADPlasticDeformationEvolution);

InputParameters
ADPlasticDeformationEvolution::validParams()
{
  InputParameters params = ADTimeKernel::validParams();
  params.addClassDescription(
      "Evolves one component of the manuscript true-plastic deformation law by the "
      "equivalent rate equation dot(Fbar_p)=Lbar_p Fbar_p.");
  params.addRequiredRangeCheckedParam<unsigned int>("row", "row<3", "Tensor row.");
  params.addRequiredRangeCheckedParam<unsigned int>("column", "column<3", "Tensor column.");
  params.addRequiredCoupledVar(
      "plastic_deformation_gradient", "Row-major dim*dim components of Fbar_p.");
  params.addCoupledVar(
      "isochoric_multiplier",
      "Optional multiplier for the determinant-constrained backward-Euler update.");
  params.addParam<MaterialPropertyName>("plastic_deformation_log_rate_name",
                                        "plastic_deformation_log_rate",
                                        "Associated Lbar_p property.");
  params.addParam<FunctionName>(
      "forcing",
      "0",
      "Optional manufactured component-rate forcing. This verification hook is zero by default.");
  return params;
}

ADPlasticDeformationEvolution::ADPlasticDeformationEvolution(
    const InputParameters & parameters)
  : ADTimeKernel(parameters),
    _dim(_mesh.dimension()),
    _row(getParam<unsigned int>("row")),
    _column(getParam<unsigned int>("column")),
    _isochoric_multiplier(isCoupled("isochoric_multiplier")
                              ? &adCoupledValue("isochoric_multiplier")
                              : nullptr),
    _plastic_log_rate(
        getADMaterialProperty<RankTwoTensor>("plastic_deformation_log_rate_name")),
    _forcing(getFunction("forcing"))
{
  if (_row >= _dim || _column >= _dim)
    paramError("row", "row and column must be smaller than the mesh dimension.");
  if (coupledComponents("plastic_deformation_gradient") != _dim * _dim)
    paramError("plastic_deformation_gradient", "Supply exactly dim*dim row-major components.");
  for (const auto c : make_range(_dim * _dim))
    _plastic_deformation_components.push_back(
        &adCoupledValue("plastic_deformation_gradient", c));
}

ADReal
ADPlasticDeformationEvolution::computeQpResidual()
{
  ADRankTwoTensor F_p(ADRankTwoTensor::initIdentity);
  for (const auto i : make_range(_dim))
    for (const auto j : make_range(_dim))
      F_p(i, j) = (*_plastic_deformation_components[i * _dim + j])[_qp];
  if (MetaPhysicL::raw_value(F_p.det()) <= 0.0)
    mooseError(name(), ": true-plastic deformation gradient must remain orientation preserving.");
  const ADRankTwoTensor F_p_dot = _plastic_log_rate[_qp] * F_p;
  ADReal constrained_rate = F_p_dot(_row, _column);
  if (_isochoric_multiplier)
    constrained_rate += (*_isochoric_multiplier)[_qp] * F_p.inverse().transpose()(_row, _column);
  return _test[_i][_qp] *
         (_u_dot[_qp] - constrained_rate - _forcing.value(_t, _q_point[_qp]));
}
