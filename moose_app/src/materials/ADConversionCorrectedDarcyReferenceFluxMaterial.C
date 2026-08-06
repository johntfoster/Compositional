#include "ADConversionCorrectedDarcyReferenceFluxMaterial.h"

#include "metaphysicl/raw_type.h"

registerMooseObject("MulticomponentReactiveFlowApp",
                    ADConversionCorrectedDarcyReferenceFluxMaterial);

InputParameters
ADConversionCorrectedDarcyReferenceFluxMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Computes the conversion-corrected generalized Darcy relative mass flux for a "
      "phase-transforming fluid and pulls it to the solid reference configuration. Pressure, "
      "capillary/dynamic-lag, electrical, conversion-insertion, body, and inertia force families "
      "are independently selectable.");

  params.addParam<MaterialPropertyName>(
      "jacobian_name", "solid_reference_J", "Material property name for J.");
  params.addParam<MaterialPropertyName>("inverse_deformation_gradient_name",
                                        "solid_reference_F_inv",
                                        "Material property name for F^{-1}.");
  params.addRequiredParam<MaterialPropertyName>("phase_fraction_name", "Current phase fraction phi_f.");
  params.addRequiredParam<MaterialPropertyName>("bulk_density_name", "Current bulk phase density rho_f.");
  params.addRequiredParam<MaterialPropertyName>(
      "conversion_source_name", "Net current phase conversion source q_f=sum_alpha dot(c)_f^alpha.");

  params.addRequiredCoupledVar("pressure", "Phase pressure backbone or unenriched field.");
  params.addCoupledVar("pressure_enrichment", "Optional P0 EG pressure enrichment.");
  params.addParam<bool>("include_capillary_pressure",
                        false,
                        "Add a separately coupled capillary/electrical/dynamic pressure offset.");
  params.addCoupledVar("capillary_pressure", "Optional phase-pressure offset field.");
  params.addCoupledVar("capillary_pressure_enrichment", "Optional P0 EG offset enrichment.");
  params.addParam<Real>(
      "capillary_pressure_scale",
      1.0,
      "Multiplier on the offset gradient; use -1 for a supplied omega_f^+ dynamic lag.");

  params.addParam<bool>("include_conversion_insertion",
                        true,
                        "Include q_f(grad(tau)-v_s). Must be true for a transforming phase.");
  params.addCoupledVar("tau", "Transfer-work potential tau backbone.");
  params.addCoupledVar("tau_enrichment", "Optional P0 EG tau enrichment.");
  params.addCoupledVar("solid_velocity", "Spatial solid velocity components v_s.");

  params.addParam<bool>("include_electrical_force",
                        false,
                        "Include div(phi_f E tensor d_f) supplied as a spatial force property.");
  params.addParam<MaterialPropertyName>(
      "electrical_force_name", "", "Spatial electrical/Maxwell force per current volume.");
  params.addParam<bool>("include_acceleration", false, "Include supplied spatial phase acceleration.");
  params.addCoupledVar("phase_acceleration", "Spatial phase acceleration components a_f.");

  params.addRequiredRangeCheckedParam<Real>(
      "permeability", "permeability>0", "Scalar isotropic intrinsic permeability k.");
  params.addRangeCheckedParam<Real>(
      "viscosity", 1.0, "viscosity>0", "Constant viscosity when viscosity_name is empty.");
  params.addParam<MaterialPropertyName>(
      "viscosity_name", "", "Optional positive state-dependent viscosity property.");
  params.addParam<MaterialPropertyName>(
      "relative_permeability_name", "", "Optional nonnegative relative-permeability property.");
  params.addParam<RealVectorValue>("gravity", RealVectorValue(), "Spatial gravity vector g.");
  params.addRangeCheckedParam<Real>("minimum_resistance",
                                    1e-30,
                                    "minimum_resistance>0",
                                    "Minimum allowed magnitude of the combined resistance.");
  params.addParam<bool>("require_positive_resistance",
                        true,
                        "Require phi_f^2 mu/(k k_r)+q_f to be positive, rather than merely nonsingular.");

  params.addParam<MaterialPropertyName>("combined_resistance_name",
                                        "conversion_corrected_darcy_resistance",
                                        "Output combined isotropic resistance.");
  params.addParam<MaterialPropertyName>("resistance_margin_name",
                                        "conversion_corrected_darcy_resistance_margin",
                                        "Output positive-resistance margin.");
  params.addParam<MaterialPropertyName>("spatial_relative_mass_flux_name",
                                        "spatial_relative_mass_flux",
                                        "Output current relative mass flux w_f.");
  params.addParam<MaterialPropertyName>("reference_relative_mass_flux_name",
                                        "reference_relative_mass_flux",
                                        "Output pulled-back relative mass flux W_f.");
  return params;
}

ADConversionCorrectedDarcyReferenceFluxMaterial::
    ADConversionCorrectedDarcyReferenceFluxMaterial(const InputParameters & parameters)
  : Material(parameters),
    _J(getADMaterialProperty<Real>("jacobian_name")),
    _F_inv(getADMaterialProperty<RankTwoTensor>("inverse_deformation_gradient_name")),
    _phase_fraction(getADMaterialProperty<Real>("phase_fraction_name")),
    _bulk_density(getADMaterialProperty<Real>("bulk_density_name")),
    _conversion_source(getADMaterialProperty<Real>("conversion_source_name")),
    _relative_permeability(
        getParam<MaterialPropertyName>("relative_permeability_name").empty()
            ? nullptr
            : &getADMaterialProperty<Real>("relative_permeability_name")),
    _viscosity_property(getParam<MaterialPropertyName>("viscosity_name").empty()
                            ? nullptr
                            : &getADMaterialProperty<Real>("viscosity_name")),
    _electrical_force(getParam<MaterialPropertyName>("electrical_force_name").empty()
                          ? nullptr
                          : &getADMaterialProperty<RealVectorValue>("electrical_force_name")),
    _grad_pressure(adCoupledGradient("pressure")),
    _grad_pressure_enrichment(isCoupled("pressure_enrichment")
                                  ? &adCoupledGradient("pressure_enrichment")
                                  : nullptr),
    _grad_capillary_pressure(nullptr),
    _grad_capillary_pressure_enrichment(nullptr),
    _grad_tau(nullptr),
    _grad_tau_enrichment(nullptr),
    _permeability(getParam<Real>("permeability")),
    _viscosity(getParam<Real>("viscosity")),
    _gravity(getParam<RealVectorValue>("gravity")),
    _include_capillary_pressure(getParam<bool>("include_capillary_pressure")),
    _include_electrical_force(getParam<bool>("include_electrical_force")),
    _include_conversion_insertion(getParam<bool>("include_conversion_insertion")),
    _include_acceleration(getParam<bool>("include_acceleration")),
    _minimum_resistance(getParam<Real>("minimum_resistance")),
    _require_positive_resistance(getParam<bool>("require_positive_resistance")),
    _combined_resistance(declareADProperty<Real>(
        getParam<MaterialPropertyName>("combined_resistance_name"))),
    _resistance_margin(
        declareADProperty<Real>(getParam<MaterialPropertyName>("resistance_margin_name"))),
    _spatial_relative_mass_flux(declareADProperty<RealVectorValue>(
        getParam<MaterialPropertyName>("spatial_relative_mass_flux_name"))),
    _reference_relative_mass_flux(declareADProperty<RealVectorValue>(
        getParam<MaterialPropertyName>("reference_relative_mass_flux_name")))
{
  if (_include_capillary_pressure != isCoupled("capillary_pressure"))
    paramError("capillary_pressure",
               "Couple capillary_pressure exactly when include_capillary_pressure=true.");
  if (!_include_capillary_pressure && isCoupled("capillary_pressure_enrichment"))
    paramError("capillary_pressure_enrichment",
               "Enable and couple capillary_pressure before supplying its enrichment.");
  if (_include_capillary_pressure)
  {
    _grad_capillary_pressure = &adCoupledGradient("capillary_pressure");
    if (isCoupled("capillary_pressure_enrichment"))
      _grad_capillary_pressure_enrichment = &adCoupledGradient("capillary_pressure_enrichment");
  }

  if (_include_conversion_insertion)
  {
    if (!isCoupled("tau"))
      paramError("tau", "Couple tau when include_conversion_insertion=true.");
    if (!isCoupled("solid_velocity") || coupledComponents("solid_velocity") != _mesh.dimension())
      paramError("solid_velocity", "Supply exactly dim solid-velocity components.");
    _grad_tau = &adCoupledGradient("tau");
    if (isCoupled("tau_enrichment"))
      _grad_tau_enrichment = &adCoupledGradient("tau_enrichment");
    for (const auto i : make_range(_mesh.dimension()))
      _solid_velocity.push_back(&adCoupledValue("solid_velocity", i));
  }
  else if (isCoupled("tau") || isCoupled("tau_enrichment") || isCoupled("solid_velocity"))
    paramError("include_conversion_insertion",
               "tau/solid_velocity were supplied while conversion insertion is disabled.");

  if (_include_electrical_force != (_electrical_force != nullptr))
    paramError("electrical_force_name",
               "Supply electrical_force_name exactly when include_electrical_force=true.");
  if (_include_acceleration != isCoupled("phase_acceleration"))
    paramError("phase_acceleration",
               "Couple phase_acceleration exactly when include_acceleration=true.");
  if (_include_acceleration)
  {
    if (coupledComponents("phase_acceleration") != _mesh.dimension())
      paramError("phase_acceleration", "Supply exactly dim acceleration components.");
    for (const auto i : make_range(_mesh.dimension()))
      _phase_acceleration.push_back(&adCoupledValue("phase_acceleration", i));
  }
}

void
ADConversionCorrectedDarcyReferenceFluxMaterial::computeQpProperties()
{
  const ADReal phi = _phase_fraction[_qp];
  const ADReal rho = _bulk_density[_qp];
  const ADReal q = _conversion_source[_qp];
  const ADReal kr = _relative_permeability ? (*_relative_permeability)[_qp] : 1.0;
  const ADReal mu = _viscosity_property ? (*_viscosity_property)[_qp] : _viscosity;

  if (MetaPhysicL::raw_value(phi) < 0.0)
    mooseError(name(), ": phase fraction must be nonnegative.");
  if (MetaPhysicL::raw_value(rho) < 0.0)
    mooseError(name(), ": bulk density must be nonnegative.");
  if (MetaPhysicL::raw_value(kr) <= 0.0)
    mooseError(name(), ": relative permeability must be positive for algebraic flux elimination.");
  if (MetaPhysicL::raw_value(mu) <= 0.0)
    mooseError(name(), ": viscosity must be positive.");

  const ADReal drag_resistance = phi * phi * mu / (_permeability * kr);
  const ADReal resistance = drag_resistance + q;
  _combined_resistance[_qp] = resistance;
  _resistance_margin[_qp] = resistance;
  const Real raw_resistance = MetaPhysicL::raw_value(resistance);
  if (_require_positive_resistance && raw_resistance <= _minimum_resistance)
    mooseError(name(), ": conversion-corrected Darcy resistance is not positive with margin.");
  if (!_require_positive_resistance && std::abs(raw_resistance) <= _minimum_resistance)
    mooseError(name(), ": conversion-corrected Darcy resistance is singular within tolerance.");

  ADRealVectorValue grad_pressure_ref = _grad_pressure[_qp];
  if (_grad_pressure_enrichment)
    grad_pressure_ref += (*_grad_pressure_enrichment)[_qp];
  if (_grad_capillary_pressure)
  {
    ADRealVectorValue grad_offset_ref = (*_grad_capillary_pressure)[_qp];
    if (_grad_capillary_pressure_enrichment)
      grad_offset_ref += (*_grad_capillary_pressure_enrichment)[_qp];
    grad_pressure_ref += getParam<Real>("capillary_pressure_scale") * grad_offset_ref;
  }

  ADRealVectorValue acceleration;
  for (const auto i : index_range(_phase_acceleration))
    acceleration(i) = (*_phase_acceleration[i])[_qp];
  ADRealVectorValue force = rho * (_gravity - acceleration) -
                            phi * (_F_inv[_qp].transpose() * grad_pressure_ref);
  if (_electrical_force)
    force += (*_electrical_force)[_qp];
  if (_include_conversion_insertion)
  {
    ADRealVectorValue grad_tau_ref = (*_grad_tau)[_qp];
    if (_grad_tau_enrichment)
      grad_tau_ref += (*_grad_tau_enrichment)[_qp];
    ADRealVectorValue solid_velocity;
    for (const auto i : index_range(_solid_velocity))
      solid_velocity(i) = (*_solid_velocity[i])[_qp];
    force += q * (_F_inv[_qp].transpose() * grad_tau_ref - solid_velocity);
  }

  _spatial_relative_mass_flux[_qp] = rho * force / resistance;
  _reference_relative_mass_flux[_qp] =
      _J[_qp] * (_F_inv[_qp] * _spatial_relative_mass_flux[_qp]);
}
