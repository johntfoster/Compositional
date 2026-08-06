#include "ADPhaseTransformingPressureGradientDarcyReferenceFluxMaterial.h"

#include "PhaseRegistry.h"

#include "metaphysicl/raw_type.h"

registerMooseObject("MulticomponentReactiveFlowApp",
                    ADPhaseTransformingPressureGradientDarcyReferenceFluxMaterial);

InputParameters
ADPhaseTransformingPressureGradientDarcyReferenceFluxMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Evaluates the anisotropic phase-transforming solid-reference Darcy closure using a "
      "modularly assembled actual phase-pressure gradient, q_f(grad(tau)-v_s), optional "
      "acceleration, and optional electrical force.");
  params.addParam<std::string>("phase", "", "Registered relative-flux phase.");
  params.addParam<UserObjectName>("phase_registry", "", "Optional phase registry.");
  params.addParam<MaterialPropertyName>("jacobian_name", "solid_reference_J", "Property J.");
  params.addParam<MaterialPropertyName>("inverse_deformation_gradient_name",
                                        "solid_reference_F_inv",
                                        "Property F^{-1}.");
  params.addRequiredParam<MaterialPropertyName>("phase_pressure_gradient_name",
                                                 "Actual reference phase-pressure gradient.");
  params.addCoupledVar("intrinsic_density", 0.0, "Intrinsic phase density.");
  params.addParam<MooseEnum>("intrinsic_density_source",
                             MooseEnum("coupled material", "coupled"),
                             "Source for intrinsic density.");
  params.addParam<MaterialPropertyName>("intrinsic_density_name",
                                        "intrinsic_density_from_eos",
                                        "Intrinsic-density material property.");
  params.addRequiredParam<MaterialPropertyName>("bulk_density_name",
                                                 "Current bulk phase density rho_f.");
  params.addRequiredParam<MaterialPropertyName>("conversion_source_name",
                                                 "Net current phase conversion source q_f.");
  params.addParam<MaterialPropertyName>("phase_active_name", "",
                                        "Optional phase-active indicator.");
  params.addRequiredCoupledVar("tau", "Transfer-potential backbone.");
  params.addCoupledVar("tau_enrichment", "Optional P0 transfer-potential enrichment.");
  params.addRequiredCoupledVar("solid_displacements",
                               "Solid displacements whose time derivatives give v_s.");
  params.addParam<Real>("permeability", 0.0,
                        "Positive isotropic permeability; exclusive with permeability_name.");
  params.addParam<MaterialPropertyName>(
      "permeability_name", "",
      "Optional symmetric-positive-definite spatial permeability tensor property; exclusive "
      "with permeability.");
  params.addRangeCheckedParam<Real>("viscosity", 1.0, "viscosity>0", "Constant viscosity.");
  params.addParam<MaterialPropertyName>("viscosity_name", "", "Optional viscosity property.");
  params.addParam<MaterialPropertyName>("relative_permeability_name", "",
                                        "Optional relative permeability.");
  params.addParam<RealVectorValue>("gravity", RealVectorValue(), "Spatial gravity.");
  params.addParam<bool>("include_acceleration", false, "Include phase acceleration.");
  params.addCoupledVar("phase_acceleration", "Spatial phase-acceleration components.");
  params.addParam<bool>("include_electrical_force", false, "Include current electrical force.");
  params.addParam<MaterialPropertyName>("electrical_force_name", "",
                                        "Spatial electrical-force property.");
  params.addRangeCheckedParam<Real>("active_tolerance", 1e-12, "active_tolerance>=0",
                                     "Inactive-phase tolerance.");
  params.addRangeCheckedParam<Real>("minimum_denominator", 1e-30, "minimum_denominator>0",
                                     "Minimum eigenvalue of phi^2 mu I+q k_r K.");
  params.addParam<MaterialPropertyName>("darcy_mobility_ref_name", "darcy_mobility_ref",
                                        "Reference pressure-mobility tensor.");
  params.addParam<MaterialPropertyName>("combined_resistance_name",
                                        "conversion_corrected_darcy_resistance",
                                        "Mean diagonal resistance diagnostic.");
  params.addParam<MaterialPropertyName>("resistance_denominator_name",
                                        "conversion_corrected_darcy_denominator",
                                        "Mean diagonal denominator diagnostic.");
  params.addParam<MaterialPropertyName>("combined_resistance_tensor_name",
                                        "conversion_corrected_darcy_resistance_tensor",
                                        "Full anisotropic combined-resistance tensor.");
  params.addParam<MaterialPropertyName>("resistance_denominator_tensor_name",
                                        "conversion_corrected_darcy_denominator_tensor",
                                        "Full anisotropic denominator tensor.");
  params.addParam<MaterialPropertyName>("spatial_relative_mass_flux_name",
                                        "spatial_relative_mass_flux",
                                        "Current relative mass flux.");
  params.addParam<MaterialPropertyName>("reference_relative_mass_flux_name",
                                        "reference_relative_mass_flux",
                                        "Reference relative mass flux.");
  return params;
}

ADPhaseTransformingPressureGradientDarcyReferenceFluxMaterial::
    ADPhaseTransformingPressureGradientDarcyReferenceFluxMaterial(
        const InputParameters & parameters)
  : Material(parameters),
    _J(getADMaterialProperty<Real>("jacobian_name")),
    _F_inv(getADMaterialProperty<RankTwoTensor>("inverse_deformation_gradient_name")),
    _phase_pressure_gradient(
        getADMaterialProperty<RealVectorValue>("phase_pressure_gradient_name")),
    _grad_tau(adCoupledGradient("tau")),
    _grad_tau_enrichment(isCoupled("tau_enrichment")
                             ? &adCoupledGradient("tau_enrichment")
                             : nullptr),
    _intrinsic_density_source(getParam<MooseEnum>("intrinsic_density_source")),
    _intrinsic_density_var(nullptr),
    _intrinsic_density_mat(nullptr),
    _bulk_density(getADMaterialProperty<Real>("bulk_density_name")),
    _conversion_source(getADMaterialProperty<Real>("conversion_source_name")),
    _phase_active(getParam<MaterialPropertyName>("phase_active_name").empty()
                      ? nullptr
                      : &getADMaterialProperty<Real>("phase_active_name")),
    _relative_permeability(getParam<MaterialPropertyName>("relative_permeability_name").empty()
                               ? nullptr
                               : &getADMaterialProperty<Real>("relative_permeability_name")),
    _viscosity_property(getParam<MaterialPropertyName>("viscosity_name").empty()
                            ? nullptr
                            : &getADMaterialProperty<Real>("viscosity_name")),
    _electrical_force(getParam<MaterialPropertyName>("electrical_force_name").empty()
                          ? nullptr
                          : &getADMaterialProperty<RealVectorValue>("electrical_force_name")),
    _permeability_property(getParam<MaterialPropertyName>("permeability_name").empty()
                               ? nullptr
                               : &getADMaterialProperty<RankTwoTensor>("permeability_name")),
    _phase_name(getParam<std::string>("phase")),
    _phase_registry(getParam<UserObjectName>("phase_registry").empty()
                        ? nullptr
                        : &getUserObject<PhaseRegistry>("phase_registry")),
    _permeability(getParam<Real>("permeability")),
    _viscosity(getParam<Real>("viscosity")),
    _gravity(getParam<RealVectorValue>("gravity")),
    _include_acceleration(getParam<bool>("include_acceleration")),
    _include_electrical_force(getParam<bool>("include_electrical_force")),
    _minimum_denominator(getParam<Real>("minimum_denominator")),
    _active_tolerance(getParam<Real>("active_tolerance")),
    _darcy_mobility_ref(declareADProperty<RankTwoTensor>(
        getParam<MaterialPropertyName>("darcy_mobility_ref_name"))),
    _combined_resistance(declareADProperty<Real>(
        getParam<MaterialPropertyName>("combined_resistance_name"))),
    _resistance_denominator(declareADProperty<Real>(
        getParam<MaterialPropertyName>("resistance_denominator_name"))),
    _combined_resistance_tensor(declareADProperty<RankTwoTensor>(
        getParam<MaterialPropertyName>("combined_resistance_tensor_name"))),
    _resistance_denominator_tensor(declareADProperty<RankTwoTensor>(
        getParam<MaterialPropertyName>("resistance_denominator_tensor_name"))),
    _spatial_relative_mass_flux(declareADProperty<RealVectorValue>(
        getParam<MaterialPropertyName>("spatial_relative_mass_flux_name"))),
    _reference_relative_mass_flux(declareADProperty<RealVectorValue>(
        getParam<MaterialPropertyName>("reference_relative_mass_flux_name")))
{
  if ((_phase_registry == nullptr) != _phase_name.empty())
    paramError("phase_registry", "Supply phase and phase_registry together.");
  if (_phase_registry &&
      (!_phase_registry->hasPhase(_phase_name) || !_phase_registry->usesRelativeFlux(_phase_name)))
    paramError("phase", "Phase must be registered with momentum model relative_flux.");

  if (_permeability_property && _permeability > 0.0)
    paramError("permeability_name", "Supply either permeability or permeability_name, not both.");
  if (!_permeability_property && _permeability <= 0.0)
    paramError("permeability", "Supply a positive permeability or permeability_name.");

  if (_intrinsic_density_source == "coupled")
  {
    if (!isCoupled("intrinsic_density"))
      paramError("intrinsic_density", "Couple intrinsic density when its source is coupled.");
    _intrinsic_density_var = &adCoupledValue("intrinsic_density");
  }
  else
    _intrinsic_density_mat = &getADMaterialProperty<Real>("intrinsic_density_name");

  if (coupledComponents("solid_displacements") != _mesh.dimension())
    paramError("solid_displacements", "Supply exactly dim solid displacement components.");
  for (const auto i : make_range(_mesh.dimension()))
    _solid_displacement_dot.push_back(&adCoupledDot("solid_displacements", i));
  if (_include_acceleration != isCoupled("phase_acceleration"))
    paramError("phase_acceleration", "Couple phase acceleration exactly when enabled.");
  if (_include_acceleration)
  {
    if (coupledComponents("phase_acceleration") != _mesh.dimension())
      paramError("phase_acceleration", "Supply exactly dim acceleration components.");
    for (const auto i : make_range(_mesh.dimension()))
      _phase_acceleration.push_back(&adCoupledValue("phase_acceleration", i));
  }
  if (_include_electrical_force != (_electrical_force != nullptr))
    paramError("electrical_force_name", "Supply the electrical force exactly when enabled.");
}

void
ADPhaseTransformingPressureGradientDarcyReferenceFluxMaterial::computeQpProperties()
{
  const ADReal intrinsic_density = _intrinsic_density_source == "coupled"
                                       ? (*_intrinsic_density_var)[_qp]
                                       : (*_intrinsic_density_mat)[_qp];
  const ADReal rho = _bulk_density[_qp];
  const ADReal q = _conversion_source[_qp];
  const ADReal kr = _relative_permeability ? (*_relative_permeability)[_qp] : 1.0;
  const ADReal mu = _viscosity_property ? (*_viscosity_property)[_qp] : _viscosity;
  const bool inactive =
      (_phase_active && MetaPhysicL::raw_value((*_phase_active)[_qp]) <= _active_tolerance) ||
      MetaPhysicL::raw_value(rho) <= _active_tolerance ||
      MetaPhysicL::raw_value(kr) <= _active_tolerance;
  if (inactive)
  {
    _darcy_mobility_ref[_qp].zero();
    _combined_resistance[_qp] = 0.0;
    _resistance_denominator[_qp] = 0.0;
    _combined_resistance_tensor[_qp].zero();
    _resistance_denominator_tensor[_qp].zero();
    _spatial_relative_mass_flux[_qp] = ADRealVectorValue();
    _reference_relative_mass_flux[_qp] = ADRealVectorValue();
    return;
  }
  if (MetaPhysicL::raw_value(intrinsic_density) <= 0.0 ||
      MetaPhysicL::raw_value(mu) <= 0.0)
    mooseError(name(), ": active transforming phase requires positive density and viscosity.");

  ADRankTwoTensor permeability_tensor;
  if (_permeability_property)
    permeability_tensor = (*_permeability_property)[_qp];
  else
  {
    permeability_tensor.setToIdentity();
    permeability_tensor *= _permeability;
  }

  const RankTwoTensor raw_permeability = MetaPhysicL::raw_value(permeability_tensor);
  if (!raw_permeability.isSymmetric())
    mooseError(name(), ": permeability tensor must be symmetric.");
  std::vector<Real> permeability_eigenvalues;
  raw_permeability.symmetricEigenvalues(permeability_eigenvalues);
  for (const auto eigenvalue : permeability_eigenvalues)
    if (eigenvalue <= 0.0)
      mooseError(name(), ": permeability tensor must be positive definite.");

  const ADReal phi = rho / intrinsic_density;
  const ADRankTwoTensor identity(ADRankTwoTensor::initIdentity);
  const ADRankTwoTensor denominator_tensor =
      phi * phi * mu * identity + q * kr * permeability_tensor;
  const RankTwoTensor raw_denominator = MetaPhysicL::raw_value(denominator_tensor);
  std::vector<Real> denominator_eigenvalues;
  raw_denominator.symmetricEigenvalues(denominator_eigenvalues);
  for (const auto eigenvalue : denominator_eigenvalues)
    if (eigenvalue <= _minimum_denominator)
      mooseError(name(),
                 ": conversion-corrected anisotropic Darcy denominator lost its positive "
                 "margin.");

  const ADRankTwoTensor denominator_inverse = denominator_tensor.inverse();
  const ADRankTwoTensor spatial_mass_mobility =
      rho * kr * permeability_tensor * denominator_inverse;
  const ADRankTwoTensor spatial_pressure_mobility = phi * spatial_mass_mobility;
  const ADRankTwoTensor resistance_tensor =
      phi * phi * mu / kr * permeability_tensor.inverse() + q * identity;

  _combined_resistance_tensor[_qp] = resistance_tensor;
  _resistance_denominator_tensor[_qp] = denominator_tensor;
  _combined_resistance[_qp] = resistance_tensor.trace() / LIBMESH_DIM;
  _resistance_denominator[_qp] = denominator_tensor.trace() / LIBMESH_DIM;
  _darcy_mobility_ref[_qp] = _J[_qp] * _F_inv[_qp] * spatial_pressure_mobility *
                             _F_inv[_qp].transpose();

  ADRealVectorValue acceleration;
  for (const auto i : index_range(_phase_acceleration))
    acceleration(i) = (*_phase_acceleration[i])[_qp];
  ADRealVectorValue force =
      rho * (_gravity - acceleration) -
      phi * (_F_inv[_qp].transpose() * _phase_pressure_gradient[_qp]);
  if (_electrical_force)
    force += (*_electrical_force)[_qp];

  ADRealVectorValue grad_tau_ref = _grad_tau[_qp];
  if (_grad_tau_enrichment)
    grad_tau_ref += (*_grad_tau_enrichment)[_qp];
  ADRealVectorValue solid_velocity;
  for (const auto i : index_range(_solid_displacement_dot))
    solid_velocity(i) = (*_solid_displacement_dot[i])[_qp];
  force += q * (_F_inv[_qp].transpose() * grad_tau_ref - solid_velocity);

  _spatial_relative_mass_flux[_qp] = spatial_mass_mobility * force;
  _reference_relative_mass_flux[_qp] =
      _J[_qp] * (_F_inv[_qp] * _spatial_relative_mass_flux[_qp]);
}
