#include "ADReferenceEnergyStressPowerTerm.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADReferenceEnergyStressPowerTerm);

InputParameters
ADReferenceEnergyStressPowerTerm::validParams()
{
  InputParameters params = ADKernelValue::validParams();
  params.addClassDescription(
      "Atomic -scale*J*(sigma:L) residual power, with L=Grad_X(v)F^{-1}. Use scale=1 "
      "for RHS total reversible stress power and scale=-1 for the Maxwell power retained "
      "on the electric-enthalpy-rate side of Eq. (MC_energy_balance).");
  params.addRequiredCoupledVar("phase_velocity", "All phase velocity components.");
  params.addRequiredParam<MaterialPropertyName>("cauchy_stress_name", "AD Cauchy stress sigma.");
  params.addParam<Real>("scale", 1.0, "Signed RHS power multiplier.");
  params.addParam<MaterialPropertyName>("solid_jacobian_name", "solid_reference_J", "J.");
  params.addParam<MaterialPropertyName>(
      "solid_inverse_deformation_gradient_name", "solid_reference_F_inv", "F^{-1}.");
  return params;
}

ADReferenceEnergyStressPowerTerm::ADReferenceEnergyStressPowerTerm(
    const InputParameters & parameters)
  : ADKernelValue(parameters),
    _dim(_mesh.dimension()),
    _cauchy_stress(getADMaterialProperty<RankTwoTensor>("cauchy_stress_name")),
    _F_inv(getADMaterialProperty<RankTwoTensor>("solid_inverse_deformation_gradient_name")),
    _J(getADMaterialProperty<Real>("solid_jacobian_name")),
    _scale(getParam<Real>("scale"))
{
  if (coupledComponents("phase_velocity") != _dim)
    paramError("phase_velocity", "Provide exactly dim phase velocity components.");
  for (const auto i : make_range(_dim))
    _velocity_gradients.push_back(&adCoupledGradient("phase_velocity", i));
}

ADReal
ADReferenceEnergyStressPowerTerm::precomputeQpResidual()
{
  ADRankTwoTensor spatial_velocity_gradient;
  spatial_velocity_gradient.zero();
  for (const auto i : make_range(_dim))
    for (const auto j : make_range(_dim))
      for (const auto K : make_range(_dim))
        spatial_velocity_gradient(i, j) +=
            (*_velocity_gradients[i])[_qp](K) * _F_inv[_qp](K, j);
  return -_scale * _J[_qp] * _cauchy_stress[_qp].doubleContraction(spatial_velocity_gradient);
}
