#include "ADStandardDarcyReferenceFluxMaterial.h"
#include "PhaseRegistry.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADStandardDarcyReferenceFluxMaterial);

InputParameters
ADStandardDarcyReferenceFluxMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription("Computes the standard neutral, conversion-free Darcy relative "
                             "mass flux pulled to the solid reference configuration.");
  params.addParam<std::string>("phase", "", "Registered phase using momentum model 'relative_flux'.");
  params.addParam<UserObjectName>("phase_registry", "", "Optional input-deck phase registry.");
  params.addParam<MaterialPropertyName>(
      "jacobian_name", "solid_reference_J", "Material property name for J.");
  params.addParam<MaterialPropertyName>("inverse_deformation_gradient_name",
                                        "solid_reference_F_inv",
                                        "Material property name for F^{-1}.");
  params.addRequiredCoupledVar("pressure", "Fluid pressure p_f backbone or unenriched field.");
  params.addCoupledVar(
      "pressure_enrichment",
      "Optional P0 pressure enrichment. When supplied, Darcy flux uses Grad(p + p_enr).");
  params.addParam<bool>(
      "include_capillary_pressure",
      false,
      "Whether to add the supplied phase capillary contribution gamma_f to the pressure driver.");
  params.addCoupledVar(
      "capillary_pressure",
      "Phase capillary contribution gamma_f, added so the force uses Grad(p_f + gamma_f). "
      "Required only when include_capillary_pressure is true.");
  params.addCoupledVar("capillary_pressure_enrichment",
                       "Optional P0 enrichment for the phase capillary-pressure driver.");
  params.addCoupledVar("intrinsic_density", 0.0, "Intrinsic phase density rhobar_f.");
  params.addParam<MooseEnum>(
      "intrinsic_density_source",
      MooseEnum("coupled material", "coupled"),
      "Source for rhobar_f. Use 'material' to consume intrinsic_density_name from an EOS material.");
  params.addParam<MaterialPropertyName>("intrinsic_density_name",
                                        "intrinsic_density_from_eos",
                                        "Material property name for rhobar_f when source is material.");
  params.addRequiredRangeCheckedParam<Real>(
      "permeability", "permeability>=0", "Scalar isotropic permeability.");
  params.addRangeCheckedParam<Real>(
      "viscosity", 1.0, "viscosity>0", "Constant fluid viscosity used when viscosity_name is empty.");
  params.addParam<MaterialPropertyName>(
      "viscosity_name",
      "",
      "Optional positive AD material property for pressure- or state-dependent phase viscosity.");
  params.addParam<MaterialPropertyName>(
      "relative_permeability_name",
      "",
      "Optional AD material property for the phase relative permeability. An empty name uses "
      "unit relative permeability.");
  params.addParam<RealVectorValue>("gravity", RealVectorValue(0, 0, 0), "Spatial gravity vector.");
  params.addParam<bool>(
      "include_acceleration",
      false,
      "Whether the supplied spatial phase acceleration enters the relative-flux driving force. "
      "False gives the negligible-inertia Darcy reduction.");
  params.addCoupledVar(
      "phase_acceleration",
      "Spatial phase-acceleration components a_f. Required only when include_acceleration is true.");
  params.addParam<MaterialPropertyName>("darcy_mobility_ref_name",
                                        "darcy_mobility_ref",
                                        "Material property name for rhobar_f J F^{-1} k/mu F^{-T}.");
  params.addParam<MaterialPropertyName>("reference_relative_mass_flux_name",
                                        "reference_relative_mass_flux",
                                        "Material property name for W_f.");
  return params;
}

ADStandardDarcyReferenceFluxMaterial::ADStandardDarcyReferenceFluxMaterial(
    const InputParameters & parameters)
  : Material(parameters),
    _J(getADMaterialProperty<Real>("jacobian_name")),
    _F_inv(getADMaterialProperty<RankTwoTensor>("inverse_deformation_gradient_name")),
    _grad_pressure(adCoupledGradient("pressure")),
    _grad_pressure_enrichment(isCoupled("pressure_enrichment")
                                  ? &adCoupledGradient("pressure_enrichment")
                                  : nullptr),
    _include_capillary_pressure(getParam<bool>("include_capillary_pressure")),
    _grad_capillary_pressure(nullptr),
    _grad_capillary_pressure_enrichment(nullptr),
    _intrinsic_density_source(getParam<MooseEnum>("intrinsic_density_source")),
    _intrinsic_density_var(nullptr),
    _intrinsic_density_mat(nullptr),
    _phase_name(getParam<std::string>("phase")),
    _phase_registry(getParam<UserObjectName>("phase_registry").empty()
                        ? nullptr
                        : &getUserObject<PhaseRegistry>("phase_registry")),
    _permeability(getParam<Real>("permeability")),
    _viscosity(getParam<Real>("viscosity")),
    _viscosity_property(getParam<MaterialPropertyName>("viscosity_name").empty()
                            ? nullptr
                            : &getADMaterialProperty<Real>("viscosity_name")),
    _relative_permeability(
        getParam<MaterialPropertyName>("relative_permeability_name").empty()
            ? nullptr
            : &getADMaterialProperty<Real>("relative_permeability_name")),
    _gravity(getParam<RealVectorValue>("gravity")),
    _include_acceleration(getParam<bool>("include_acceleration")),
    _darcy_mobility_ref(
        declareADProperty<RankTwoTensor>(getParam<MaterialPropertyName>("darcy_mobility_ref_name"))),
    _reference_relative_mass_flux(declareADProperty<RealVectorValue>(
        getParam<MaterialPropertyName>("reference_relative_mass_flux_name")))
{
  if ((_phase_registry == nullptr) != _phase_name.empty())
    paramError("phase_registry", "Supply phase and phase_registry together.");
  if (_phase_registry &&
      (!_phase_registry->hasPhase(_phase_name) || !_phase_registry->usesRelativeFlux(_phase_name)))
    paramError("phase", "Phase must be registered with momentum model 'relative_flux'.");
  if (_include_acceleration && !isCoupled("phase_acceleration"))
    paramError("phase_acceleration", "Supply phase acceleration when include_acceleration is true.");
  if (!_include_acceleration && isCoupled("phase_acceleration"))
    paramError("include_acceleration",
               "phase_acceleration was supplied but include_acceleration is false.");
  if (_include_acceleration && coupledComponents("phase_acceleration") != _mesh.dimension())
    paramError("phase_acceleration", "Provide exactly dim acceleration components.");
  if (_include_acceleration)
    for (const auto i : make_range(_mesh.dimension()))
      _phase_acceleration.push_back(&adCoupledValue("phase_acceleration", i));
  if (_include_capillary_pressure && !isCoupled("capillary_pressure"))
    paramError("capillary_pressure",
               "A capillary-pressure field is required when include_capillary_pressure=true.");
  if (!_include_capillary_pressure && isCoupled("capillary_pressure"))
    paramError("capillary_pressure",
               "Set include_capillary_pressure=true to couple a capillary-pressure field.");
  if (!_include_capillary_pressure && isCoupled("capillary_pressure_enrichment"))
    paramError("capillary_pressure_enrichment",
               "Set include_capillary_pressure=true to couple a capillary-pressure enrichment field.");
  if (_include_capillary_pressure)
  {
    _grad_capillary_pressure = &adCoupledGradient("capillary_pressure");
    if (isCoupled("capillary_pressure_enrichment"))
      _grad_capillary_pressure_enrichment = &adCoupledGradient("capillary_pressure_enrichment");
  }
  if (_intrinsic_density_source == "coupled")
  {
    if (!isCoupled("intrinsic_density"))
      paramError("intrinsic_density",
                 "A coupled intrinsic_density variable is required when intrinsic_density_source "
                 "is 'coupled'.");
    _intrinsic_density_var = &adCoupledValue("intrinsic_density");
  }
  else
    _intrinsic_density_mat =
        &getADMaterialProperty<Real>(getParam<MaterialPropertyName>("intrinsic_density_name"));
}

void
ADStandardDarcyReferenceFluxMaterial::computeQpProperties()
{
  const ADReal intrinsic_density = _intrinsic_density_source == "coupled"
                                       ? (*_intrinsic_density_var)[_qp]
                                       : (*_intrinsic_density_mat)[_qp];
  const ADReal relative_permeability =
      _relative_permeability ? (*_relative_permeability)[_qp] : 1.0;
  const ADReal viscosity = _viscosity_property ? (*_viscosity_property)[_qp] : _viscosity;
  if (MetaPhysicL::raw_value(relative_permeability) < 0.0)
    mooseError(name(), ": relative permeability must be nonnegative.");
  if (MetaPhysicL::raw_value(viscosity) <= 0.0)
    mooseError(name(), ": viscosity must be positive.");
  const ADReal mobility = intrinsic_density * relative_permeability * _permeability / viscosity;
  _darcy_mobility_ref[_qp] =
      mobility * _J[_qp] * _F_inv[_qp] * _F_inv[_qp].transpose();

  ADRealVectorValue effective_reference_pressure_gradient = _grad_pressure[_qp];
  if (_grad_pressure_enrichment)
    effective_reference_pressure_gradient += (*_grad_pressure_enrichment)[_qp];
  if (_include_capillary_pressure)
  {
    effective_reference_pressure_gradient += (*_grad_capillary_pressure)[_qp];
    if (_grad_capillary_pressure_enrichment)
      effective_reference_pressure_gradient += (*_grad_capillary_pressure_enrichment)[_qp];
  }
  const ADRealVectorValue reference_pressure_part =
      _darcy_mobility_ref[_qp] * effective_reference_pressure_gradient;
  ADRealVectorValue spatial_effective_body_acceleration = _gravity;
  if (_include_acceleration)
    for (const auto i : make_range(_mesh.dimension()))
      spatial_effective_body_acceleration(i) -= (*_phase_acceleration[i])[_qp];
  const ADRealVectorValue reference_body_part = mobility * _J[_qp] *
                                                (_F_inv[_qp] *
                                                 (intrinsic_density *
                                                  spatial_effective_body_acceleration));

  _reference_relative_mass_flux[_qp] = -reference_pressure_part + reference_body_part;
}
