#include "ADOverallMomentumThermocapillaryTerm.h"

registerMooseObject("MulticomponentReactiveFlowApp",
                    ADOverallMomentumThermocapillaryTerm);

InputParameters
ADOverallMomentumThermocapillaryTerm::validParams()
{
  InputParameters params = ADKernelValue::validParams();
  params.addClassDescription(
      "Atomic +J*phi*(partial gamma/partial theta)*F^{-T}Grad(theta) residual term from "
      "Eq. (solid_reference_overall_momentum).");
  params.addRequiredRangeCheckedParam<unsigned int>("component", "component<3",
                                                     "Momentum component.");
  params.addRequiredCoupledVar("temperature", "Fluid-subsystem temperature.");
  params.addRequiredCoupledVar("fluid_fraction", "Total fluid volume fraction phi.");
  params.addRequiredParam<MaterialPropertyName>(
      "surface_energy_temperature_derivative_name", "Property partial gamma/partial theta.");
  params.addParam<MaterialPropertyName>("solid_jacobian_name", "solid_reference_J", "J.");
  params.addParam<MaterialPropertyName>(
      "solid_inverse_deformation_gradient_name", "solid_reference_F_inv", "F^{-1}.");
  return params;
}

ADOverallMomentumThermocapillaryTerm::ADOverallMomentumThermocapillaryTerm(
    const InputParameters & parameters)
  : ADKernelValue(parameters),
    _component(getParam<unsigned int>("component")),
    _temperature_gradient(adCoupledGradient("temperature")),
    _fluid_fraction(adCoupledValue("fluid_fraction")),
    _surface_energy_temperature_derivative(
        getADMaterialProperty<Real>("surface_energy_temperature_derivative_name")),
    _J(getADMaterialProperty<Real>("solid_jacobian_name")),
    _F_inv(getADMaterialProperty<RankTwoTensor>("solid_inverse_deformation_gradient_name"))
{
  if (_component >= _mesh.dimension())
    paramError("component", "component must be smaller than mesh dimension.");
}

ADReal
ADOverallMomentumThermocapillaryTerm::precomputeQpResidual()
{
  const ADRealVectorValue current_gradient =
      _F_inv[_qp].transpose() * _temperature_gradient[_qp];
  return _J[_qp] * _fluid_fraction[_qp] *
         _surface_energy_temperature_derivative[_qp] * current_gradient(_component);
}
