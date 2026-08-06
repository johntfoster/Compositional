#include "ADReferenceEnergySourceTerm.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADReferenceEnergySourceTerm);

InputParameters
ADReferenceEnergySourceTerm::validParams()
{
  InputParameters params = ADKernelValue::validParams();
  params.addClassDescription(
      "Atomic -J*source energy term. Instantiate for stress power, pressure/constraint power, "
      "conversion transfer work, relative-current electrical work, external heat, interphase "
      "internal-energy exchange, Maxwell power, or other terms of Eq. (MC_energy_balance).");
  params.addRequiredParam<MaterialPropertyName>("source_name", "AD current-volume power/source.");
  params.addParam<Real>("scale", 1.0, "Signed RHS source multiplier.");
  params.addParam<bool>("multiply_by_jacobian", true, "Multiply by solid-reference J.");
  params.addParam<MaterialPropertyName>("solid_jacobian_name", "solid_reference_J", "J.");
  return params;
}

ADReferenceEnergySourceTerm::ADReferenceEnergySourceTerm(
    const InputParameters & parameters)
  : ADKernelValue(parameters),
    _source(getADMaterialProperty<Real>("source_name")),
    _J(getADMaterialProperty<Real>("solid_jacobian_name")),
    _scale(getParam<Real>("scale")),
    _multiply_by_J(getParam<bool>("multiply_by_jacobian"))
{
}

ADReal
ADReferenceEnergySourceTerm::precomputeQpResidual()
{
  return -(_multiply_by_J ? _J[_qp] : ADReal(1.0)) * _scale * _source[_qp];
}
