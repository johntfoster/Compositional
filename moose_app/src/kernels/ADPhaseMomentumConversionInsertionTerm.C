#include "ADPhaseMomentumConversionInsertionTerm.h"

registerMooseObject("MulticomponentReactiveFlowApp",
                    ADPhaseMomentumConversionInsertionTerm);

InputParameters ADPhaseMomentumConversionInsertionTerm::validParams() {
  InputParameters params = ADKernelValue::validParams();
  params.addClassDescription(
      "Atomic -J*dot(c)_xi*(F^{-T}Grad(tau)-v_xi)_i residual contribution from "
      "Eq. (solid_reference_overall_momentum). Add one instance per "
      "mechanism/phase pair.");
  params.addRequiredRangeCheckedParam<unsigned int>("component", "component<3",
                                                    "Momentum component.");
  params.addRequiredCoupledVar("conversion_rate",
                               "Mechanism progress or phase source rate.");
  params.addParam<Real>(
      "rate_scale", 1.0,
      "Signed stoichiometric phase-mass multiplier for this mechanism.");
  params.addRequiredCoupledVar("tau", "CG transfer-potential backbone.");
  params.addCoupledVar("tau_enrichment",
                       "Optional EG P0 transfer-potential enrichment.");
  params.addCoupledVar("phase_velocity_component",
                       "Optional selected current phase-velocity component. "
                       "Use this interface or the AD "
                       "reference-relative-velocity interface.");
  params.addCoupledVar("solid_displacements",
                       "Solid displacement components whose time derivatives "
                       "supply the skeleton velocity for "
                       "the AD reference-relative-velocity interface.");
  params.addParam<MaterialPropertyName>(
      "reference_relative_velocity_name", "",
      "Optional AD solid-reference relative velocity c_xi. The kernel "
      "reconstructs the current "
      "phase velocity as v_s + F c_xi.");
  params.addParam<MaterialPropertyName>("solid_jacobian_name",
                                        "solid_reference_J", "J.");
  params.addParam<MaterialPropertyName>(
      "solid_inverse_deformation_gradient_name", "solid_reference_F_inv",
      "F^{-1}.");
  params.addParam<MaterialPropertyName>("solid_deformation_gradient_name",
                                        "solid_reference_F", "F.");
  return params;
}

ADPhaseMomentumConversionInsertionTerm::ADPhaseMomentumConversionInsertionTerm(
    const InputParameters &parameters)
    : ADKernelValue(parameters),
      _component(getParam<unsigned int>("component")),
      _rate(adCoupledValue("conversion_rate")),
      _rate_scale(getParam<Real>("rate_scale")),
      _tau_gradient(adCoupledGradient("tau")),
      _tau_enrichment_gradient(isCoupled("tau_enrichment")
                                   ? &adCoupledGradient("tau_enrichment")
                                   : nullptr),
      _phase_velocity_component(
          isCoupled("phase_velocity_component")
              ? &adCoupledValue("phase_velocity_component")
              : nullptr),
      _J(getADMaterialProperty<Real>("solid_jacobian_name")),
      _F_inv(getADMaterialProperty<RankTwoTensor>(
          "solid_inverse_deformation_gradient_name")),
      _F(getParam<MaterialPropertyName>("reference_relative_velocity_name")
                 .empty()
             ? nullptr
             : &getADMaterialProperty<RankTwoTensor>(
                   "solid_deformation_gradient_name")),
      _reference_relative_velocity(
          getParam<MaterialPropertyName>("reference_relative_velocity_name")
                  .empty()
              ? nullptr
              : &getADMaterialProperty<RealVectorValue>(
                    "reference_relative_velocity_name")) {
  if (_component >= _mesh.dimension())
    paramError("component", "component must be smaller than mesh dimension.");
  if (static_cast<bool>(_phase_velocity_component) ==
      static_cast<bool>(_reference_relative_velocity))
    paramError("phase_velocity_component",
               "Choose exactly one of phase_velocity_component or "
               "reference_relative_velocity_name.");
  if (_reference_relative_velocity &&
      (!isCoupled("solid_displacements") ||
       coupledComponents("solid_displacements") != _mesh.dimension()))
    paramError(
        "solid_displacements",
        "The reference-relative-velocity interface requires exactly dim solid "
        "displacement components.");
  if (_phase_velocity_component && isCoupled("solid_displacements"))
    paramError("solid_displacements", "Do not supply solid_displacements with "
                                      "an explicit phase_velocity_component.");

  if (_reference_relative_velocity)
    for (const auto i : make_range(_mesh.dimension()))
      _solid_displacement_dot.push_back(
          &adCoupledDot("solid_displacements", i));
}

ADReal ADPhaseMomentumConversionInsertionTerm::precomputeQpResidual() {
  ADRealVectorValue reference_tau_gradient = _tau_gradient[_qp];
  if (_tau_enrichment_gradient)
    reference_tau_gradient += (*_tau_enrichment_gradient)[_qp];
  const ADRealVectorValue current_tau_gradient =
      _F_inv[_qp].transpose() * reference_tau_gradient;

  ADReal current_phase_velocity_component = 0.0;
  if (_phase_velocity_component)
    current_phase_velocity_component = (*_phase_velocity_component)[_qp];
  else {
    current_phase_velocity_component =
        (*_solid_displacement_dot[_component])[_qp];
    for (const auto J : make_range(_mesh.dimension()))
      current_phase_velocity_component +=
          (*_F)[_qp](_component, J) * (*_reference_relative_velocity)[_qp](J);
  }

  return -_J[_qp] * _rate_scale * _rate[_qp] *
         (current_tau_gradient(_component) - current_phase_velocity_component);
}
