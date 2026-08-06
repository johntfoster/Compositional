#include "ADElectrostaticGaussLaw.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADElectrostaticGaussLaw);

InputParameters
ADElectrostaticGaussLaw::validParams()
{
  InputParameters params = ADKernel::validParams();
  params.addClassDescription(
      "Weak solid-reference Gauss law -Div_X(D)+rho_q0=0, corresponding to "
      "div_x(d)=varrho and the global field-power identity.");
  params.addRequiredParam<MaterialPropertyName>(
      "reference_electric_displacement_name", "D=J F^{-1} d.");
  params.addRequiredParam<MaterialPropertyName>("reference_free_charge_name",
                                                 "J times current free charge density.");
  return params;
}

ADElectrostaticGaussLaw::ADElectrostaticGaussLaw(const InputParameters & parameters)
  : ADKernel(parameters),
    _reference_electric_displacement(
        getADMaterialProperty<RealVectorValue>("reference_electric_displacement_name")),
    _reference_free_charge(getADMaterialProperty<Real>("reference_free_charge_name"))
{
}

ADReal
ADElectrostaticGaussLaw::computeQpResidual()
{
  return _grad_test[_i][_qp] * _reference_electric_displacement[_qp] +
         _test[_i][_qp] * _reference_free_charge[_qp];
}
