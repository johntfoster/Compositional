#include "ADReferenceFluidComponentFluxBC.h"

#include "Function.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADReferenceFluidComponentFluxBC);

InputParameters
ADReferenceFluidComponentFluxBC::validParams()
{
  InputParameters params = ADIntegratedBC::validParams();
  params += FunctionInterface::validParams();
  params.addClassDescription("Natural boundary residual for prescribed outward solid-reference "
                             "phase flux, multiplied by the component mass fraction.");
  params.addParam<FunctionName>(
      "outward_reference_phase_flux",
      "0",
      "Prescribed outward reference phase mass flux Wbar_f = W_f dot N.");
  params.addParam<FunctionName>(
      "component_mass_fraction", "1", "Component mass fraction eta_f^alpha on the boundary.");
  return params;
}

ADReferenceFluidComponentFluxBC::ADReferenceFluidComponentFluxBC(
    const InputParameters & parameters)
  : ADIntegratedBC(parameters),
    _outward_reference_phase_flux(getFunction("outward_reference_phase_flux")),
    _component_mass_fraction(getFunction("component_mass_fraction"))
{
}

ADReal
ADReferenceFluidComponentFluxBC::computeQpResidual()
{
  return _test[_i][_qp] * _component_mass_fraction.value(_t, _q_point[_qp]) *
         _outward_reference_phase_flux.value(_t, _q_point[_qp]);
}
