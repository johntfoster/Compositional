#include "ADPhaseHistoryKinematicsMaterial.h"
#include "PhaseRegistry.h"

#include "metaphysicl/raw_type.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADPhaseHistoryKinematicsMaterial);

InputParameters
ADPhaseHistoryKinematicsMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription("Computes registered mobile-phase history kinematics stored on the "
                             "solid-reference mesh. The solid map supplies F_s and J_s for "
                             "all pull-backs; the mobile phase F_a and J_a are phase-history "
                             "fields convected by c_a = W_a / (J_s rho_a).");
  params.addRequiredParam<std::string>("phase", "Registered non-reference phase name.");
  params.addRequiredParam<UserObjectName>("phase_registry", "Input-deck phase registry.");
  params.addRequiredCoupledVar("phase_deformation_gradient",
                               "Row-major active components of F_a on the solid reference mesh.");
  params.addRequiredCoupledVar("phase_jacobian", "Phase-history Jacobian J_a.");
  params.addRequiredCoupledVar("phase_velocity",
                               "Current phase velocity components v_a as functions on the solid mesh.");
  params.addCoupledVar("reference_relative_mass_flux",
                       0.0,
                       "Components of W_a = J_s F_s^{-1} w_a in solid-reference coordinates.");
  params.addRequiredCoupledVar(
      "phase_density",
      "Current bulk phase density rho_a = phi_a * rhobar_a per unit current mixture volume. "
      "Do not supply the intrinsic density rhobar_a by itself.");
  params.addCoupledVar("active_fraction",
                       1.0,
                       "Phase activity indicator, usually saturation or phase volume fraction.");
  params.addRangeCheckedParam<Real>(
      "active_tol", 1e-12, "active_tol>=0", "Tolerance below which c_a is set to zero.");
  params.addParam<MaterialPropertyName>(
      "solid_jacobian_name", "solid_reference_J", "Material property name for J_s.");
  params.addParam<MaterialPropertyName>("solid_inverse_deformation_gradient_name",
                                        "solid_reference_F_inv",
                                        "Material property name for F_s^{-1}.");
  return params;
}

ADPhaseHistoryKinematicsMaterial::ADPhaseHistoryKinematicsMaterial(
    const InputParameters & parameters)
  : Material(parameters),
    _phase_name(getParam<std::string>("phase")),
    _phase_registry(getUserObject<PhaseRegistry>("phase_registry")),
    _dim(_mesh.dimension()),
    _nF(coupledComponents("phase_deformation_gradient")),
    _J_history_var(adCoupledValue("phase_jacobian")),
    _phase_density(adCoupledValue("phase_density")),
    _active_fraction(adCoupledValue("active_fraction")),
    _active_tol(getParam<Real>("active_tol")),
    _solid_J(getADMaterialProperty<Real>("solid_jacobian_name")),
    _solid_F_inv(
        getADMaterialProperty<RankTwoTensor>("solid_inverse_deformation_gradient_name")),
    _phase_F(declareADProperty<RankTwoTensor>(_phase_name + "_phase_deformation_gradient")),
    _phase_J_history(declareADProperty<Real>(_phase_name + "_phase_jacobian_history")),
    _phase_det_F(declareADProperty<Real>(_phase_name + "_phase_deformation_gradient_determinant")),
    _phase_J_det_residual(
        declareADProperty<Real>(_phase_name + "_phase_jacobian_det_residual")),
    _phase_velocity_gradient_current(
        declareADProperty<RankTwoTensor>(_phase_name + "_phase_velocity_gradient_current")),
    _phase_reference_convective_velocity(
        declareADProperty<RealVectorValue>(_phase_name + "_phase_reference_convective_velocity"))
{
  if (!_phase_registry.hasPhase(_phase_name))
    paramError("phase", "Phase '", _phase_name, "' is not registered.");
  if (_phase_registry.isReferencePhase(_phase_name))
    paramError("phase", "Phase-history advection is only defined for non-reference phases.");
  if (_dim < 1 || _dim > 3)
    mooseError("ADPhaseHistoryKinematicsMaterial supports dimensions 1, 2, and 3.");
  if (_nF != _dim * _dim)
    paramError("phase_deformation_gradient",
               "Provide exactly dim*dim row-major active components of F_a.");
  if (coupledComponents("phase_velocity") != _dim)
    paramError("phase_velocity", "Provide exactly dim velocity components.");
  if (coupledComponents("reference_relative_mass_flux") != _dim)
    paramError("reference_relative_mass_flux", "Provide exactly dim W_a components.");

  _F_components.resize(_nF);
  for (const auto i : make_range(_nF))
    _F_components[i] = &adCoupledValue("phase_deformation_gradient", i);

  _phase_velocity_gradients.resize(_dim);
  for (const auto i : make_range(_dim))
    _phase_velocity_gradients[i] = &adCoupledGradient("phase_velocity", i);

  _reference_relative_mass_flux_components.resize(_dim);
  for (const auto i : make_range(_dim))
    _reference_relative_mass_flux_components[i] =
        &adCoupledValue("reference_relative_mass_flux", i);
}

void
ADPhaseHistoryKinematicsMaterial::computeQpProperties()
{
  _phase_F[_qp].zero();
  for (unsigned int i = 0; i < 3; ++i)
    _phase_F[_qp](i, i) = 1.0;

  for (const auto i : make_range(_dim))
    for (const auto j : make_range(_dim))
      _phase_F[_qp](i, j) = (*_F_components[i * _dim + j])[_qp];

  _phase_J_history[_qp] = _J_history_var[_qp];
  _phase_det_F[_qp] = _phase_F[_qp].det();
  _phase_J_det_residual[_qp] = _phase_J_history[_qp] - _phase_det_F[_qp];

  ADRankTwoTensor grad_X_v;
  grad_X_v.zero();
  for (const auto i : make_range(_dim))
    for (const auto j : make_range(_dim))
      grad_X_v(i, j) = (*_phase_velocity_gradients[i])[_qp](j);

  _phase_velocity_gradient_current[_qp].zero();
  _phase_reference_convective_velocity[_qp] = RealVectorValue();
  if (MetaPhysicL::raw_value(_active_fraction[_qp]) > _active_tol)
  {
    _phase_velocity_gradient_current[_qp] = grad_X_v * _solid_F_inv[_qp];
    const auto denominator = _solid_J[_qp] * _phase_density[_qp];
    if (MetaPhysicL::raw_value(denominator) <= _active_tol)
      mooseError("Cannot compute c_", _phase_name, " from W_a/(J_s rho_a) with nonpositive "
                 "J_s rho_a at quadrature point ",
                 _qp,
                 ".");

    for (const auto i : make_range(_dim))
      _phase_reference_convective_velocity[_qp](i) =
          (*_reference_relative_mass_flux_components[i])[_qp] / denominator;
  }
}
