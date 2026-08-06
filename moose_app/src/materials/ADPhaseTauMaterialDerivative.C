#include "ADPhaseTauMaterialDerivative.h"
#include "PhaseRegistry.h"

#include "metaphysicl/raw_type.h"

registerMooseObject("MulticomponentReactiveFlowApp",
                    ADPhaseTauMaterialDerivative);

InputParameters ADPhaseTauMaterialDerivative::validParams() {
  InputParameters params = Material::validParams();
  params.addClassDescription("Computes D_xi tau/Dt and D_xi tau/Dt - "
                             "|v_xi|^2/2 on the solid reference mesh. "
                             "Mobile phases use the pull-back c_xi = W_xi/(J "
                             "rho_xi); skeleton-attached phases "
                             "use the solid-frame time derivative.");
  params.addRequiredParam<std::string>("phase", "Registered phase name.");
  params.addRequiredParam<UserObjectName>("phase_registry",
                                          "Input-deck phase registry.");
  MooseEnum phase_kind("solid_reference mobile", "mobile");
  params.addParam<MooseEnum>(
      "phase_kind", phase_kind,
      "Whether the phase follows the solid frame or a mobile phase.");
  params.addRequiredCoupledVar(
      "tau", "Transfer potential tau backbone or unenriched field.");
  params.addCoupledVar("tau_enrichment",
                       "Optional P0 tau enrichment. When supplied, derivatives "
                       "use tau + tau_enr.");
  params.addCoupledVar("phase_velocity",
                       "Current phase velocity components. Defaults to zero.");
  params.addCoupledVar("solid_displacements",
                       "Optional solid displacement components. For a mobile "
                       "phase without explicit "
                       "phase_velocity, the material reconstructs v_xi = "
                       "dot(u_s) + F W_xi/(J rho_xi).");
  params.addParam<MaterialPropertyName>("jacobian_name", "solid_reference_J",
                                        "Material property name for J.");
  params.addParam<MaterialPropertyName>("deformation_gradient_name",
                                        "solid_reference_F",
                                        "Material property name for F.");
  params.addParam<MaterialPropertyName>(
      "bulk_density_name", "",
      "Current bulk phase density rho_xi. Required for mobile phases.");
  params.addParam<MaterialPropertyName>(
      "reference_relative_mass_flux_name", "",
      "Reference relative mass flux W_xi. Required for mobile phases.");
  params.addParam<MaterialPropertyName>(
      "phase_active_name", "",
      "Optional active-phase indicator. When supplied, inactive phases report "
      "zero derivative "
      "and zero transfer offset.");
  params.addRangeCheckedParam<Real>(
      "active_tol", 1e-12, "active_tol>=0",
      "Tolerance below which the phase is inactive.");
  params.addParam<bool>("deactivate_on_nonpositive_mass", false,
                        "If true, a mobile phase with nonpositive J*rho in a "
                        "nonlinear trial state is treated as "
                        "inactive instead of raising an error. Converged-state "
                        "admissibility must still be checked "
                        "separately.");
  params.addParam<MaterialPropertyName>(
      "tau_material_derivative_name", "",
      "Material property name for D_xi tau/Dt. Defaults to "
      "'<phase>_tau_material_derivative'.");
  params.addParam<MaterialPropertyName>(
      "tau_convective_term_name", "",
      "Material property name for c_xi dot Grad tau. Defaults to "
      "'<phase>_tau_convective_term'.");
  params.addParam<MaterialPropertyName>(
      "tau_velocity_square_name", "",
      "Material property name for |v_xi|^2. Defaults to "
      "'<phase>_tau_velocity_square'.");
  params.addParam<MaterialPropertyName>(
      "tau_transfer_offset_name", "",
      "Material property name for D_xi tau/Dt - |v_xi|^2/2. Defaults to "
      "'<phase>_tau_transfer_offset'.");
  return params;
}

ADPhaseTauMaterialDerivative::ADPhaseTauMaterialDerivative(
    const InputParameters &parameters)
    : Material(parameters), _phase_name(getParam<std::string>("phase")),
      _phase_registry(getUserObject<PhaseRegistry>("phase_registry")),
      _phase_kind(getParam<MooseEnum>("phase_kind")), _dim(_mesh.dimension()),
      _tau_dot(adCoupledDot("tau")), _grad_tau(adCoupledGradient("tau")),
      _tau_enrichment_dot(isCoupled("tau_enrichment")
                              ? &adCoupledDot("tau_enrichment")
                              : nullptr),
      _grad_tau_enrichment(isCoupled("tau_enrichment")
                               ? &adCoupledGradient("tau_enrichment")
                               : nullptr),
      _J(getADMaterialProperty<Real>("jacobian_name")),
      _F(isCoupled("solid_displacements")
             ? &getADMaterialProperty<RankTwoTensor>(
                   "deformation_gradient_name")
             : nullptr),
      _bulk_density(getParam<MaterialPropertyName>("bulk_density_name").empty()
                        ? nullptr
                        : &getADMaterialProperty<Real>("bulk_density_name")),
      _reference_relative_mass_flux(
          getParam<MaterialPropertyName>("reference_relative_mass_flux_name")
                  .empty()
              ? nullptr
              : &getADMaterialProperty<RealVectorValue>(
                    "reference_relative_mass_flux_name")),
      _phase_active(getParam<MaterialPropertyName>("phase_active_name").empty()
                        ? nullptr
                        : &getADMaterialProperty<Real>("phase_active_name")),
      _active_tol(getParam<Real>("active_tol")),
      _deactivate_on_nonpositive_mass(
          getParam<bool>("deactivate_on_nonpositive_mass")),
      _tau_material_derivative(declareADProperty<Real>(
          getParam<MaterialPropertyName>("tau_material_derivative_name").empty()
              ? MaterialPropertyName(_phase_name + "_tau_material_derivative")
              : getParam<MaterialPropertyName>(
                    "tau_material_derivative_name"))),
      _tau_convective_term(declareADProperty<Real>(
          getParam<MaterialPropertyName>("tau_convective_term_name").empty()
              ? MaterialPropertyName(_phase_name + "_tau_convective_term")
              : getParam<MaterialPropertyName>("tau_convective_term_name"))),
      _tau_velocity_square(declareADProperty<Real>(
          getParam<MaterialPropertyName>("tau_velocity_square_name").empty()
              ? MaterialPropertyName(_phase_name + "_tau_velocity_square")
              : getParam<MaterialPropertyName>("tau_velocity_square_name"))),
      _tau_transfer_offset(declareADProperty<Real>(
          getParam<MaterialPropertyName>("tau_transfer_offset_name").empty()
              ? MaterialPropertyName(_phase_name + "_tau_transfer_offset")
              : getParam<MaterialPropertyName>("tau_transfer_offset_name"))) {
  if (!_phase_registry.hasPhase(_phase_name))
    paramError("phase", "Phase '", _phase_name, "' is not registered.");
  if (_phase_kind == "mobile" &&
      (!_bulk_density || !_reference_relative_mass_flux))
    paramError("bulk_density_name",
               "Mobile tau derivatives require bulk_density_name and "
               "reference_relative_mass_flux_name.");
  if (isCoupled("phase_velocity") &&
      coupledComponents("phase_velocity") != _dim)
    paramError("phase_velocity",
               "Provide exactly dim phase velocity components.");
  if (isCoupled("solid_displacements") &&
      coupledComponents("solid_displacements") != _dim)
    paramError("solid_displacements",
               "Provide exactly dim solid displacement components.");
  if (isCoupled("phase_velocity") && isCoupled("solid_displacements"))
    paramError("phase_velocity",
               "Choose phase_velocity or solid_displacements.");
  if (_phase_kind == "solid_reference" && isCoupled("solid_displacements"))
    paramError("solid_displacements", "The reconstructed mobile-phase velocity "
                                      "interface requires phase_kind=mobile.");

  _phase_velocity.reserve(_dim);
  if (isCoupled("phase_velocity"))
    for (const auto i : make_range(_dim))
      _phase_velocity.push_back(&adCoupledValue("phase_velocity", i));
  if (isCoupled("solid_displacements"))
    for (const auto i : make_range(_dim))
      _solid_displacement_dot.push_back(
          &adCoupledDot("solid_displacements", i));
}

void ADPhaseTauMaterialDerivative::computeQpProperties() {
  ADReal active = _phase_active && MetaPhysicL::raw_value(
                                       (*_phase_active)[_qp]) <= _active_tol
                      ? 0.0
                      : 1.0;

  ADReal convective_term = 0.0;
  ADRealVectorValue reference_convective_velocity;
  if (_phase_kind == "mobile" && MetaPhysicL::raw_value(active) > 0.0) {
    const ADReal denominator = _J[_qp] * (*_bulk_density)[_qp];
    if (MetaPhysicL::raw_value(denominator) <= _active_tol) {
      if (_deactivate_on_nonpositive_mass)
        active = 0.0;
      else
        mooseError("Cannot compute D_", _phase_name,
                   " tau/Dt with nonpositive J*rho at ", "quadrature point ",
                   _qp, ".");
    } else {
      for (const auto i : make_range(_dim))
        reference_convective_velocity(i) =
            (*_reference_relative_mass_flux)[_qp](i) / denominator;
      ADRealVectorValue total_tau_gradient = _grad_tau[_qp];
      if (_grad_tau_enrichment)
        total_tau_gradient += (*_grad_tau_enrichment)[_qp];
      convective_term = reference_convective_velocity * total_tau_gradient;
    }
  }

  ADReal velocity_square = 0.0;
  for (const auto i : make_range(_phase_velocity.size()))
    velocity_square += (*_phase_velocity[i])[_qp] * (*_phase_velocity[i])[_qp];
  if (!_solid_displacement_dot.empty()) {
    const ADRealVectorValue current_relative_velocity =
        (*_F)[_qp] * reference_convective_velocity;
    for (const auto i : make_range(_dim)) {
      const ADReal current_phase_velocity =
          (*_solid_displacement_dot[i])[_qp] + current_relative_velocity(i);
      velocity_square += current_phase_velocity * current_phase_velocity;
    }
  }

  const ADReal total_tau_dot =
      _tau_dot[_qp] + (_tau_enrichment_dot ? (*_tau_enrichment_dot)[_qp] : 0.0);
  const ADReal material_derivative = total_tau_dot + convective_term;
  _tau_material_derivative[_qp] = active * material_derivative;
  _tau_convective_term[_qp] = active * convective_term;
  _tau_velocity_square[_qp] = active * velocity_square;
  _tau_transfer_offset[_qp] =
      active * (material_derivative - 0.5 * velocity_square);
}
