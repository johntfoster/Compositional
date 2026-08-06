#include "ADReferenceEnergyPropertyRateTerm.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADReferenceEnergyPropertyRateTerm);

InputParameters
ADReferenceEnergyPropertyRateTerm::validParams()
{
  InputParameters params = ADKernelValue::validParams();
  params.addClassDescription(
      "Atomic J*a*r energy term for reconstructed CG/EG, constitutive, or other AD material "
      "property rates that are not represented by one primitive variable dot.");
  params.addRequiredParam<MaterialPropertyName>("rate_name", "AD state-rate property r.");
  params.addRequiredParam<MaterialPropertyName>("coefficient_name", "AD conjugate coefficient a.");
  params.addParam<Real>("scale", 1.0, "Signed multiplier.");
  params.addParam<bool>("multiply_by_jacobian", true, "Multiply by solid-reference J.");
  params.addParam<MaterialPropertyName>("solid_jacobian_name", "solid_reference_J", "J.");
  return params;
}

ADReferenceEnergyPropertyRateTerm::ADReferenceEnergyPropertyRateTerm(
    const InputParameters & parameters)
  : ADKernelValue(parameters),
    _rate(getADMaterialProperty<Real>("rate_name")),
    _coefficient(getADMaterialProperty<Real>("coefficient_name")),
    _J(getADMaterialProperty<Real>("solid_jacobian_name")),
    _scale(getParam<Real>("scale")),
    _multiply_by_J(getParam<bool>("multiply_by_jacobian"))
{
}

ADReal
ADReferenceEnergyPropertyRateTerm::precomputeQpResidual()
{
  return (_multiply_by_J ? _J[_qp] : ADReal(1.0)) * _scale * _coefficient[_qp] * _rate[_qp];
}
