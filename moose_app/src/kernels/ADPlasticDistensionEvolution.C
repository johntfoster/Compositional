#include "ADPlasticDistensionEvolution.h"

#include "Function.h"
#include "metaphysicl/raw_type.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADPlasticDistensionEvolution);

InputParameters
ADPlasticDistensionEvolution::validParams()
{
  InputParameters params = ADTimeKernel::validParams();
  params.addClassDescription(
      "Evolves one component of the manuscript tensor plastic-distension law by "
      "dot(A_p)=L_A A_p.");
  params.addRequiredRangeCheckedParam<unsigned int>("row", "row<3", "Tensor row.");
  params.addRequiredRangeCheckedParam<unsigned int>("column", "column<3", "Tensor column.");
  params.addRequiredCoupledVar(
      "plastic_distension_tensor", "Row-major dim*dim components of A_p.");
  params.addParam<MaterialPropertyName>("plastic_distension_log_rate_name",
                                        "plastic_distension_log_rate",
                                        "Associated tensor L_A property.");
  params.addParam<FunctionName>(
      "forcing",
      "0",
      "Optional manufactured component-rate forcing. This verification hook is zero by default.");
  return params;
}

ADPlasticDistensionEvolution::ADPlasticDistensionEvolution(const InputParameters & parameters)
  : ADTimeKernel(parameters),
    _dim(_mesh.dimension()),
    _row(getParam<unsigned int>("row")),
    _column(getParam<unsigned int>("column")),
    _plastic_distension_log_rate(
        getADMaterialProperty<RankTwoTensor>("plastic_distension_log_rate_name")),
    _forcing(getFunction("forcing"))
{
  if (_row >= _dim || _column >= _dim)
    paramError("row", "row and column must be smaller than the mesh dimension.");
  if (coupledComponents("plastic_distension_tensor") != _dim * _dim)
    paramError("plastic_distension_tensor", "Supply exactly dim*dim row-major components.");
  for (const auto c : make_range(_dim * _dim))
    _plastic_distension_components.push_back(
        &adCoupledValue("plastic_distension_tensor", c));
}

ADReal
ADPlasticDistensionEvolution::computeQpResidual()
{
  ADRankTwoTensor A_p(ADRankTwoTensor::initIdentity);
  for (const auto i : make_range(_dim))
    for (const auto j : make_range(_dim))
      A_p(i, j) = (*_plastic_distension_components[i * _dim + j])[_qp];
  if (MetaPhysicL::raw_value(A_p.det()) <= 0.0)
    mooseError(name(), ": plastic distension tensor must remain orientation preserving.");
  const ADRankTwoTensor A_p_dot = _plastic_distension_log_rate[_qp] * A_p;
  return _test[_i][_qp] *
         (_u_dot[_qp] - A_p_dot(_row, _column) - _forcing.value(_t, _q_point[_qp]));
}
