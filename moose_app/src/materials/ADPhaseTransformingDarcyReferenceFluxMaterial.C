#include "ADPhaseTransformingDarcyReferenceFluxMaterial.h"
#include "PhaseRegistry.h"

#include "metaphysicl/raw_type.h"

registerMooseObject("MulticomponentReactiveFlowApp",
                    ADPhaseTransformingDarcyReferenceFluxMaterial);

InputParameters
ADPhaseTransformingDarcyReferenceFluxMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Production phase-transforming generalized Darcy closure. It is parameter-compatible with "
      "ADStandardDarcyReferenceFluxMaterial and adds the manuscript conversion resistance and "
      "q_f(grad(tau)-v_s) insertion force, with a zero-flux inactive-phase limit.");
  params.addParam<std::string>("phase", "", "Registered relative-flux phase.");
  params.addParam<UserObjectName>("phase_registry", "", "Optional input-deck phase registry.");
  params.addParam<MaterialPropertyName>("jacobian_name", "solid_reference_J", "Property J.");
  params.addParam<MaterialPropertyName>("inverse_deformation_gradient_name",
                                        "solid_reference_F_inv",
                                        "Property F^{-1}.");
  params.addRequiredCoupledVar("pressure", "Phase pressure backbone.");
  params.addCoupledVar("pressure_enrichment", "Optional P0 EG pressure enrichment.");
  params.addParam<bool>("include_capillary_pressure", false, "Include a phase pressure offset.");
  params.addCoupledVar("capillary_pressure", "Phase pressure offset.");
  params.addCoupledVar("capillary_pressure_enrichment", "Optional P0 EG offset enrichment.");
  params.addParam<Real>("capillary_pressure_scale", 1.0, "Signed multiplier on the offset gradient.");

  params.addCoupledVar("intrinsic_density", 0.0, "Intrinsic phase density.");
  params.addParam<MooseEnum>("intrinsic_density_source",
                             MooseEnum("coupled material", "coupled"),
                             "Source for intrinsic density.");
  params.addParam<MaterialPropertyName>("intrinsic_density_name",
                                        "intrinsic_density_from_eos",
                                        "Intrinsic-density material property.");
  params.addRequiredParam<MaterialPropertyName>("bulk_density_name", "Current bulk phase density rho_f.");
  params.addRequiredParam<MaterialPropertyName>(
      "conversion_source_name", "Net current phase conversion source q_f.");
  params.addParam<MaterialPropertyName>("phase_active_name", "", "Optional phase-active indicator.");

  params.addRequiredCoupledVar("tau", "Transfer-work potential tau backbone.");
  params.addCoupledVar("tau_enrichment", "Optional P0 EG tau enrichment.");
  params.addRequiredCoupledVar("solid_displacements", "Solid displacement components; time derivatives give v_s.");
  params.addRequiredRangeCheckedParam<Real>("permeability", "permeability>0", "Intrinsic permeability.");
  params.addRangeCheckedParam<Real>("viscosity", 1.0, "viscosity>0", "Constant viscosity.");
  params.addParam<MaterialPropertyName>("viscosity_name", "", "Optional viscosity property.");
  params.addParam<MaterialPropertyName>("relative_permeability_name", "", "Optional relative permeability.");
  params.addParam<RealVectorValue>("gravity", RealVectorValue(), "Spatial gravity.");
  params.addParam<bool>("include_acceleration", false, "Include phase acceleration.");
  params.addCoupledVar("phase_acceleration", "Spatial phase acceleration components.");
  params.addParam<bool>("include_electrical_force", false, "Include current Maxwell/electrical force.");
  params.addParam<MaterialPropertyName>("electrical_force_name", "", "Spatial electrical force property.");
  params.addRangeCheckedParam<Real>("active_tolerance", 1e-12, "active_tolerance>=0", "Inactive-phase tolerance.");
  params.addRangeCheckedParam<Real>("minimum_denominator",
                                    1e-30,
                                    "minimum_denominator>0",
                                    "Minimum positive value of phi^2 mu+q k k_r.");

  params.addParam<MaterialPropertyName>("darcy_mobility_ref_name", "darcy_mobility_ref", "Reference pressure mobility.");
  params.addParam<MaterialPropertyName>("combined_resistance_name",
                                        "conversion_corrected_darcy_resistance",
                                        "Combined resistance output.");
  params.addParam<MaterialPropertyName>("resistance_denominator_name",
                                        "conversion_corrected_darcy_denominator",
                                        "Regular phase-limit denominator output.");
  params.addParam<MaterialPropertyName>("spatial_relative_mass_flux_name",
                                        "spatial_relative_mass_flux",
                                        "Current relative mass flux output.");
  params.addParam<MaterialPropertyName>("reference_relative_mass_flux_name",
                                        "reference_relative_mass_flux",
                                        "Reference relative mass flux output.");
  return params;
}

ADPhaseTransformingDarcyReferenceFluxMaterial::ADPhaseTransformingDarcyReferenceFluxMaterial(
    const InputParameters & parameters)
  : Material(parameters),
    _J(getADMaterialProperty<Real>("jacobian_name")),
    _F_inv(getADMaterialProperty<RankTwoTensor>("inverse_deformation_gradient_name")),
    _grad_pressure(adCoupledGradient("pressure")),
    _grad_pressure_enrichment(isCoupled("pressure_enrichment") ? &adCoupledGradient("pressure_enrichment") : nullptr),
    _grad_capillary_pressure(nullptr),
    _grad_capillary_pressure_enrichment(nullptr),
    _grad_tau(adCoupledGradient("tau")),
    _grad_tau_enrichment(isCoupled("tau_enrichment") ? &adCoupledGradient("tau_enrichment") : nullptr),
    _intrinsic_density_source(getParam<MooseEnum>("intrinsic_density_source")),
    _intrinsic_density_var(nullptr),
    _intrinsic_density_mat(nullptr),
    _bulk_density(getADMaterialProperty<Real>("bulk_density_name")),
    _conversion_source(getADMaterialProperty<Real>("conversion_source_name")),
    _phase_active(getParam<MaterialPropertyName>("phase_active_name").empty() ? nullptr : &getADMaterialProperty<Real>("phase_active_name")),
    _relative_permeability(getParam<MaterialPropertyName>("relative_permeability_name").empty() ? nullptr : &getADMaterialProperty<Real>("relative_permeability_name")),
    _viscosity_property(getParam<MaterialPropertyName>("viscosity_name").empty() ? nullptr : &getADMaterialProperty<Real>("viscosity_name")),
    _electrical_force(getParam<MaterialPropertyName>("electrical_force_name").empty() ? nullptr : &getADMaterialProperty<RealVectorValue>("electrical_force_name")),
    _phase_name(getParam<std::string>("phase")),
    _phase_registry(getParam<UserObjectName>("phase_registry").empty() ? nullptr : &getUserObject<PhaseRegistry>("phase_registry")),
    _permeability(getParam<Real>("permeability")),
    _viscosity(getParam<Real>("viscosity")),
    _gravity(getParam<RealVectorValue>("gravity")),
    _include_capillary_pressure(getParam<bool>("include_capillary_pressure")),
    _include_acceleration(getParam<bool>("include_acceleration")),
    _include_electrical_force(getParam<bool>("include_electrical_force")),
    _minimum_denominator(getParam<Real>("minimum_denominator")),
    _active_tolerance(getParam<Real>("active_tolerance")),
    _darcy_mobility_ref(declareADProperty<RankTwoTensor>(getParam<MaterialPropertyName>("darcy_mobility_ref_name"))),
    _combined_resistance(declareADProperty<Real>(getParam<MaterialPropertyName>("combined_resistance_name"))),
    _resistance_denominator(declareADProperty<Real>(getParam<MaterialPropertyName>("resistance_denominator_name"))),
    _spatial_relative_mass_flux(declareADProperty<RealVectorValue>(getParam<MaterialPropertyName>("spatial_relative_mass_flux_name"))),
    _reference_relative_mass_flux(declareADProperty<RealVectorValue>(getParam<MaterialPropertyName>("reference_relative_mass_flux_name")))
{
  if ((_phase_registry == nullptr) != _phase_name.empty())
    paramError("phase_registry", "Supply phase and phase_registry together.");
  if (_phase_registry && (!_phase_registry->hasPhase(_phase_name) || !_phase_registry->usesRelativeFlux(_phase_name)))
    paramError("phase", "Phase must be registered with momentum model 'relative_flux'.");
  if (_intrinsic_density_source == "coupled")
  {
    if (!isCoupled("intrinsic_density"))
      paramError("intrinsic_density", "Couple intrinsic density when its source is coupled.");
    _intrinsic_density_var = &adCoupledValue("intrinsic_density");
  }
  else
    _intrinsic_density_mat = &getADMaterialProperty<Real>("intrinsic_density_name");

  if (_include_capillary_pressure != isCoupled("capillary_pressure"))
    paramError("capillary_pressure", "Couple the pressure offset exactly when enabled.");
  if (_include_capillary_pressure)
  {
    _grad_capillary_pressure = &adCoupledGradient("capillary_pressure");
    if (isCoupled("capillary_pressure_enrichment"))
      _grad_capillary_pressure_enrichment = &adCoupledGradient("capillary_pressure_enrichment");
  }
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
ADPhaseTransformingDarcyReferenceFluxMaterial::computeQpProperties()
{
  const ADReal intrinsic_density = _intrinsic_density_source == "coupled" ? (*_intrinsic_density_var)[_qp] : (*_intrinsic_density_mat)[_qp];
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
    _spatial_relative_mass_flux[_qp] = ADRealVectorValue();
    _reference_relative_mass_flux[_qp] = ADRealVectorValue();
    return;
  }
  if (MetaPhysicL::raw_value(intrinsic_density) <= 0.0 || MetaPhysicL::raw_value(mu) <= 0.0)
    mooseError(name(), ": active transforming phase requires positive density and viscosity.");

  const ADReal phi = rho / intrinsic_density;
  const ADReal denominator = phi * phi * mu + q * _permeability * kr;
  if (MetaPhysicL::raw_value(denominator) <= _minimum_denominator)
    mooseError(name(), ": conversion-corrected Darcy resistance lost its positive margin.");
  const ADReal resistance = denominator / (_permeability * kr);
  const ADReal pressure_mobility = rho * phi * _permeability * kr / denominator;
  _combined_resistance[_qp] = resistance;
  _resistance_denominator[_qp] = denominator;
  _darcy_mobility_ref[_qp] = pressure_mobility * _J[_qp] * _F_inv[_qp] * _F_inv[_qp].transpose();

  ADRealVectorValue grad_pressure_ref = _grad_pressure[_qp];
  if (_grad_pressure_enrichment)
    grad_pressure_ref += (*_grad_pressure_enrichment)[_qp];
  if (_grad_capillary_pressure)
  {
    ADRealVectorValue offset = (*_grad_capillary_pressure)[_qp];
    if (_grad_capillary_pressure_enrichment)
      offset += (*_grad_capillary_pressure_enrichment)[_qp];
    grad_pressure_ref += getParam<Real>("capillary_pressure_scale") * offset;
  }
  ADRealVectorValue acceleration;
  for (const auto i : index_range(_phase_acceleration))
    acceleration(i) = (*_phase_acceleration[i])[_qp];
  ADRealVectorValue force = rho * (_gravity - acceleration) - phi * (_F_inv[_qp].transpose() * grad_pressure_ref);
  if (_electrical_force)
    force += (*_electrical_force)[_qp];
  ADRealVectorValue grad_tau_ref = _grad_tau[_qp];
  if (_grad_tau_enrichment)
    grad_tau_ref += (*_grad_tau_enrichment)[_qp];
  ADRealVectorValue solid_velocity;
  for (const auto i : index_range(_solid_displacement_dot))
    solid_velocity(i) = (*_solid_displacement_dot[i])[_qp];
  force += q * (_F_inv[_qp].transpose() * grad_tau_ref - solid_velocity);

  _spatial_relative_mass_flux[_qp] = rho * _permeability * kr * force / denominator;
  _reference_relative_mass_flux[_qp] = _J[_qp] * (_F_inv[_qp] * _spatial_relative_mass_flux[_qp]);
}

