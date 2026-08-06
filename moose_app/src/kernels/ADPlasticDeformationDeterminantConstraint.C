#include "ADPlasticDeformationDeterminantConstraint.h"

registerMooseObject("MulticomponentReactiveFlowApp",
                    ADPlasticDeformationDeterminantConstraint);

InputParameters
ADPlasticDeformationDeterminantConstraint::validParams()
{
  InputParameters params = ADKernelValue::validParams();
  params.addClassDescription(
      "Enforces the manuscript isochoric true-plastic constraint det(Fbar_p)=1. "
      "Use it as the equation for a multiplier coupled to every component-rate residual.");
  params.addRequiredCoupledVar(
      "plastic_deformation_gradient", "Row-major dim*dim components of Fbar_p.");
  params.addRangeCheckedParam<Real>(
      "target_determinant", 1.0, "target_determinant>0", "Prescribed plastic determinant.");
  return params;
}

ADPlasticDeformationDeterminantConstraint::ADPlasticDeformationDeterminantConstraint(
    const InputParameters & parameters)
  : ADKernelValue(parameters),
    _dim(_mesh.dimension()),
    _target_determinant(getParam<Real>("target_determinant"))
{
  if (coupledComponents("plastic_deformation_gradient") != _dim * _dim)
    paramError("plastic_deformation_gradient", "Supply exactly dim*dim row-major components.");
  for (const auto c : make_range(_dim * _dim))
    _plastic_deformation_components.push_back(
        &adCoupledValue("plastic_deformation_gradient", c));
}

ADReal
ADPlasticDeformationDeterminantConstraint::precomputeQpResidual()
{
  ADRankTwoTensor F_p(ADRankTwoTensor::initIdentity);
  for (const auto i : make_range(_dim))
    for (const auto j : make_range(_dim))
      F_p(i, j) = (*_plastic_deformation_components[i * _dim + j])[_qp];
  return F_p.det() - _target_determinant;
}
