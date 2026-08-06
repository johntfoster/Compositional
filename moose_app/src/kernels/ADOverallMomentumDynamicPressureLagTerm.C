#include "ADOverallMomentumDynamicPressureLagTerm.h"

registerMooseObject("MulticomponentReactiveFlowApp",
                    ADOverallMomentumDynamicPressureLagTerm);

InputParameters
ADOverallMomentumDynamicPressureLagTerm::validParams()
{
  InputParameters params = ADKernelValue::validParams();
  params.addClassDescription(
      "Atomic -J*phi*sum_f[(p_f-p_E-gamma_f-omega_f^+) grad_x(S_f)] residual term "
      "from Eq. (solid_reference_overall_momentum).");
  params.addRequiredRangeCheckedParam<unsigned int>("component", "component<3",
                                                     "Momentum component.");
  params.addRequiredCoupledVar("saturations", "Fluid saturations in phase order.");
  params.addRequiredCoupledVar("fluid_fraction", "Total fluid volume fraction phi.");
  params.addRequiredParam<std::vector<MaterialPropertyName>>(
      "pressure_lag_names",
      "Properties p_f-p_E-gamma_f-omega_f^+ in saturation order.");
  params.addParam<MaterialPropertyName>("solid_jacobian_name", "solid_reference_J", "J.");
  params.addParam<MaterialPropertyName>(
      "solid_inverse_deformation_gradient_name", "solid_reference_F_inv", "F^{-1}.");
  return params;
}

ADOverallMomentumDynamicPressureLagTerm::ADOverallMomentumDynamicPressureLagTerm(
    const InputParameters & parameters)
  : ADKernelValue(parameters),
    _component(getParam<unsigned int>("component")),
    _fluid_fraction(adCoupledValue("fluid_fraction")),
    _J(getADMaterialProperty<Real>("solid_jacobian_name")),
    _F_inv(getADMaterialProperty<RankTwoTensor>("solid_inverse_deformation_gradient_name"))
{
  if (_component >= _mesh.dimension())
    paramError("component", "component must be smaller than mesh dimension.");
  const auto names = getParam<std::vector<MaterialPropertyName>>("pressure_lag_names");
  if (names.size() != coupledComponents("saturations"))
    paramError("pressure_lag_names", "Supply one pressure-lag property per saturation.");
  for (const auto f : make_range(names.size()))
  {
    _saturation_gradients.push_back(&adCoupledGradient("saturations", f));
    _pressure_lags.push_back(&getADMaterialProperty<Real>(names[f]));
  }
}

ADReal
ADOverallMomentumDynamicPressureLagTerm::precomputeQpResidual()
{
  ADReal force_component = 0.0;
  for (const auto f : make_range(_saturation_gradients.size()))
  {
    const ADRealVectorValue current_gradient =
        _F_inv[_qp].transpose() * (*_saturation_gradients[f])[_qp];
    force_component += (*_pressure_lags[f])[_qp] * current_gradient(_component);
  }
  return -_J[_qp] * _fluid_fraction[_qp] * force_component;
}
