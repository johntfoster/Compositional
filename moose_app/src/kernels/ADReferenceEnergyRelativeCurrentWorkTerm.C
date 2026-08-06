#include "ADReferenceEnergyRelativeCurrentWorkTerm.h"

registerMooseObject("MulticomponentReactiveFlowApp",
                    ADReferenceEnergyRelativeCurrentWorkTerm);

InputParameters
ADReferenceEnergyRelativeCurrentWorkTerm::validParams()
{
  InputParameters params = ADKernelValue::validParams();
  params.addClassDescription(
      "Atomic -J*j_q,rel dot E residual source with E=-F^{-T}Grad_X(varphi), implementing "
      "the gauge-invariant relative-current work in Eq. (MC_energy_balance).");
  params.addRequiredParam<MaterialPropertyName>("current_relative_charge_flux_name",
                                                 "Sum_alpha z_alpha(j_disp+j_diff).");
  params.addRequiredCoupledVar("electric_potential", "Shared electrostatic potential varphi.");
  params.addParam<Real>("scale", 1.0, "Signed RHS power multiplier.");
  params.addParam<MaterialPropertyName>("solid_jacobian_name", "solid_reference_J", "J.");
  params.addParam<MaterialPropertyName>(
      "solid_inverse_deformation_gradient_name", "solid_reference_F_inv", "F^{-1}.");
  return params;
}

ADReferenceEnergyRelativeCurrentWorkTerm::ADReferenceEnergyRelativeCurrentWorkTerm(
    const InputParameters & parameters)
  : ADKernelValue(parameters),
    _relative_charge_current(
        getADMaterialProperty<RealVectorValue>("current_relative_charge_flux_name")),
    _electric_potential_gradient(adCoupledGradient("electric_potential")),
    _F_inv(getADMaterialProperty<RankTwoTensor>("solid_inverse_deformation_gradient_name")),
    _J(getADMaterialProperty<Real>("solid_jacobian_name")),
    _scale(getParam<Real>("scale"))
{
}

ADReal
ADReferenceEnergyRelativeCurrentWorkTerm::precomputeQpResidual()
{
  const ADRealVectorValue electric_field =
      -_F_inv[_qp].transpose() * _electric_potential_gradient[_qp];
  return -_scale * _J[_qp] * (_relative_charge_current[_qp] * electric_field);
}
