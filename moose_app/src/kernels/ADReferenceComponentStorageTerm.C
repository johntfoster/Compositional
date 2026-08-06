#include "ADReferenceComponentStorageTerm.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADReferenceComponentStorageTerm);

InputParameters
ADReferenceComponentStorageTerm::validParams()
{
  InputParameters params = ADTimeKernel::validParams();
  params.addClassDescription(
      "Atomic solid-reference component-storage term. Implements the time part of the fluid "
      "and solid component balances, including "
      "eq:solid_reference_solid_component_balance.");
  params.addParam<Real>("coefficient", 1.0, "Constant storage multiplier.");
  params.addParam<MaterialPropertyName>(
      "coefficient_name", "", "Optional AD material storage multiplier; replaces coefficient.");
  return params;
}

ADReferenceComponentStorageTerm::ADReferenceComponentStorageTerm(
    const InputParameters & parameters)
  : ADTimeKernel(parameters),
    _coefficient(getParam<Real>("coefficient")),
    _coefficient_property(getParam<MaterialPropertyName>("coefficient_name").empty()
                              ? nullptr
                              : &getADMaterialProperty<Real>("coefficient_name"))
{
  if (_coefficient_property && isParamSetByUser("coefficient"))
    paramError("coefficient_name", "Choose either coefficient or coefficient_name.");
}

ADReal
ADReferenceComponentStorageTerm::computeQpResidual()
{
  return _test[_i][_qp] *
         (_coefficient_property ? (*_coefficient_property)[_qp] : _coefficient) * _u_dot[_qp];
}
