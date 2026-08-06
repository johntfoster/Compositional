#include "ADReferenceStationaryEnergyBalance.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADReferenceStationaryEnergyBalance);

InputParameters
ADReferenceStationaryEnergyBalance::validParams()
{
  InputParameters params = ADKernel::validParams();
  params.addClassDescription(
      "Weak residual of the stationary solid-reference thermal reduction "
      "-Div_X(Q) + J electric_work + J rho r = 0.");
  params.addParam<MaterialPropertyName>(
      "reference_heat_flux_name", "reference_heat_flux", "Reference heat flux Q=J F^{-1}q.");
  params.addParam<MaterialPropertyName>(
      "reference_electric_work_name",
      "reference_electric_work",
      "J-weighted direct work of the electric field on relative charge current.");
  params.addParam<MaterialPropertyName>(
      "reference_heat_supply_name",
      "reference_heat_supply",
      "J-weighted volumetric heat supply rho r.");
  return params;
}

ADReferenceStationaryEnergyBalance::ADReferenceStationaryEnergyBalance(
    const InputParameters & parameters)
  : ADKernel(parameters),
    _reference_heat_flux(getADMaterialProperty<RealVectorValue>("reference_heat_flux_name")),
    _reference_electric_work(getADMaterialProperty<Real>("reference_electric_work_name")),
    _reference_heat_supply(getADMaterialProperty<Real>("reference_heat_supply_name"))
{
}

ADReal
ADReferenceStationaryEnergyBalance::computeQpResidual()
{
  return _grad_test[_i][_qp] * _reference_heat_flux[_qp] +
         _test[_i][_qp] * (_reference_electric_work[_qp] + _reference_heat_supply[_qp]);
}
