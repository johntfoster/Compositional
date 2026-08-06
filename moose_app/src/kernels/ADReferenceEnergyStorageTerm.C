#include "ADReferenceEnergyStorageTerm.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADReferenceEnergyStorageTerm);

InputParameters
ADReferenceEnergyStorageTerm::validParams()
{
  InputParameters params = ADTimeKernel::validParams();
  params.addClassDescription(
      "Atomic test*J*a*dot(u) storage term for internal energy or temperature-based "
      "constitutive storage in Eq. (MC_energy_balance).");
  params.addParam<Real>("coefficient", 1.0, "Constant storage coefficient.");
  params.addParam<MaterialPropertyName>("coefficient_name", "", "Optional AD coefficient.");
  params.addParam<bool>("multiply_by_jacobian", true, "Multiply by solid-reference J.");
  params.addParam<MaterialPropertyName>("solid_jacobian_name", "solid_reference_J", "J.");
  return params;
}

ADReferenceEnergyStorageTerm::ADReferenceEnergyStorageTerm(
    const InputParameters & parameters)
  : ADTimeKernel(parameters),
    _coefficient(getParam<Real>("coefficient")),
    _coefficient_property(getParam<MaterialPropertyName>("coefficient_name").empty()
                              ? nullptr
                              : &getADMaterialProperty<Real>("coefficient_name")),
    _J(getADMaterialProperty<Real>("solid_jacobian_name")),
    _multiply_by_J(getParam<bool>("multiply_by_jacobian"))
{
  if (_coefficient_property && isParamSetByUser("coefficient"))
    paramError("coefficient_name", "Choose coefficient or coefficient_name.");
}

ADReal
ADReferenceEnergyStorageTerm::computeQpResidual()
{
  const ADReal coefficient =
      _coefficient_property ? (*_coefficient_property)[_qp] : ADReal(_coefficient);
  return _test[_i][_qp] * (_multiply_by_J ? _J[_qp] : ADReal(1.0)) * coefficient *
         _u_dot[_qp];
}
