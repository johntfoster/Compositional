#include "ADOverallMomentumCapillaryHistoryGradientTerm.h"

registerMooseObject("MulticomponentReactiveFlowApp",
                    ADOverallMomentumCapillaryHistoryGradientTerm);

InputParameters
ADOverallMomentumCapillaryHistoryGradientTerm::validParams()
{
  InputParameters params = ADKernelValue::validParams();
  params.addClassDescription(
      "Atomic +J*phi*sum_k[(partial gamma/partial h_k) grad_x(h_k)] residual term from "
      "Eq. (solid_reference_overall_momentum).");
  params.addRequiredRangeCheckedParam<unsigned int>("component", "component<3",
                                                     "Momentum component.");
  params.addRequiredCoupledVar("history_variables", "All continuous capillary-history fields.");
  params.addRequiredCoupledVar("fluid_fraction", "Total fluid volume fraction phi.");
  params.addRequiredParam<std::vector<MaterialPropertyName>>(
      "surface_energy_history_derivative_names",
      "Properties partial gamma/partial h_k in history-variable order.");
  params.addParam<MaterialPropertyName>("solid_jacobian_name", "solid_reference_J", "J.");
  params.addParam<MaterialPropertyName>(
      "solid_inverse_deformation_gradient_name", "solid_reference_F_inv", "F^{-1}.");
  return params;
}

ADOverallMomentumCapillaryHistoryGradientTerm::
    ADOverallMomentumCapillaryHistoryGradientTerm(const InputParameters & parameters)
  : ADKernelValue(parameters),
    _component(getParam<unsigned int>("component")),
    _fluid_fraction(adCoupledValue("fluid_fraction")),
    _J(getADMaterialProperty<Real>("solid_jacobian_name")),
    _F_inv(getADMaterialProperty<RankTwoTensor>("solid_inverse_deformation_gradient_name"))
{
  if (_component >= _mesh.dimension())
    paramError("component", "component must be smaller than mesh dimension.");
  const auto names =
      getParam<std::vector<MaterialPropertyName>>("surface_energy_history_derivative_names");
  if (names.size() != coupledComponents("history_variables"))
    paramError("surface_energy_history_derivative_names",
               "Supply one surface-energy derivative for each history variable.");
  for (const auto k : make_range(names.size()))
  {
    _history_gradients.push_back(&adCoupledGradient("history_variables", k));
    _surface_energy_history_derivatives.push_back(&getADMaterialProperty<Real>(names[k]));
  }
}

ADReal
ADOverallMomentumCapillaryHistoryGradientTerm::precomputeQpResidual()
{
  ADReal force_component = 0.0;
  for (const auto k : make_range(_history_gradients.size()))
  {
    const ADRealVectorValue current_gradient =
        _F_inv[_qp].transpose() * (*_history_gradients[k])[_qp];
    force_component +=
        (*_surface_energy_history_derivatives[k])[_qp] * current_gradient(_component);
  }
  return _J[_qp] * _fluid_fraction[_qp] * force_component;
}
