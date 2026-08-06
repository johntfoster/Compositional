#include "ADReferenceEnergyStateRateTerm.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADReferenceEnergyStateRateTerm);

InputParameters
ADReferenceEnergyStateRateTerm::validParams()
{
  InputParameters params = ADKernelValue::validParams();
  params.addClassDescription(
      "Atomic J*a*dot(y) energy term. Instantiate for omega*dot(phi), "
      "phi*omega_rho*dot(rhobar), phi*omega_eta*dot(eta), phi*omega_theta*dot(theta), "
      "gamma_f*dot(phi_f), phi*gamma_h dot dot(h), and phi*gamma_theta*dot(theta).");
  params.addRequiredCoupledVar("state", "State variable whose time rate appears.");
  params.addRequiredParam<MaterialPropertyName>("coefficient_name", "AD coefficient a.");
  params.addParam<Real>("scale", 1.0, "Signed multiplier.");
  params.addParam<bool>("multiply_by_jacobian", true, "Multiply by solid-reference J.");
  params.addParam<MaterialPropertyName>("solid_jacobian_name", "solid_reference_J", "J.");
  return params;
}

ADReferenceEnergyStateRateTerm::ADReferenceEnergyStateRateTerm(
    const InputParameters & parameters)
  : ADKernelValue(parameters),
    _state_dot(adCoupledDot("state")),
    _coefficient(getADMaterialProperty<Real>("coefficient_name")),
    _J(getADMaterialProperty<Real>("solid_jacobian_name")),
    _scale(getParam<Real>("scale")),
    _multiply_by_J(getParam<bool>("multiply_by_jacobian"))
{
}

ADReal
ADReferenceEnergyStateRateTerm::precomputeQpResidual()
{
  return (_multiply_by_J ? _J[_qp] : ADReal(1.0)) * _scale * _coefficient[_qp] *
         _state_dot[_qp];
}
