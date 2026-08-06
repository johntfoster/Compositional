#include "ADSkeletonSpecificVolumeBiotMaterial.h"

#include "metaphysicl/raw_type.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADSkeletonSpecificVolumeBiotMaterial);

InputParameters
ADSkeletonSpecificVolumeBiotMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Reduced explicit model for B = 1 - (1 / v_s0) * partial(vbar_s) / partial(J_s) "
      "at fixed equivalent pressure, temperature, composition, and internal variables. "
      "Production nonlinear Biot closures should use ADConstrainedSkeletonBiotMaterial so "
      "vbar_s is derived from conservation and volume/EOS constraints. This explicit model "
      "can optionally reject states that violate vbar_s = J_s phi_s / sum(J_s rho_a^alpha).");
  params.addRequiredParam<MaterialPropertyName>(
      "intrinsic_specific_volume_name",
      "Intrinsic skeleton specific volume vbar_s = 1 / rhobar_s.");
  params.addParam<MaterialPropertyName>(
      "intrinsic_specific_volume_jacobian_derivative_name",
      "",
      "Optional material property for partial(vbar_s)/partial(J_s) at fixed equivalent "
      "pressure. If omitted, the name is derived from intrinsic_specific_volume_name and "
      "jacobian_symbol using DerivativeMaterialInterface naming.");
  params.addParam<std::string>(
      "jacobian_symbol",
      "solid_reference_J",
      "Independent constitutive symbol for J_s used by the derivative material.");
  params.addParam<std::string>(
      "fixed_pressure_symbol",
      "equivalent_pressure_total",
      "Independent constitutive symbol for p_E held fixed by the tangent. This parameter "
      "documents the closure and is used in implicit-closure validation messages.");
  params.addRequiredRangeCheckedParam<Real>(
      "reference_specific_volume",
      "reference_specific_volume > 0",
      "Intrinsic skeleton reference specific volume v_s0.");
  params.addParam<bool>(
      "implicit_closure",
      false,
      "Set true when vbar_s is obtained from an implicit constitutive closure. In that "
      "case intrinsic_specific_volume_jacobian_derivative_name must be supplied explicitly "
      "as the fixed-p_E tangent.");
  params.addParam<MaterialPropertyName>(
      "biot_coefficient_name", "solid_biot_coefficient", "Output AD Biot coefficient name.");
  params.addParam<MaterialPropertyName>(
      "intrinsic_skeleton_density_name",
      "solid_intrinsic_skeleton_density",
      "Output intrinsic skeleton density rhobar_s = 1 / vbar_s.");
  params.addParam<bool>(
      "check_mass_consistency",
      false,
      "When true, reject explicit vbar_s states that do not satisfy vbar_s = J_s phi_s / "
      "sum(J_s rho_a^alpha).");
  params.addParam<MaterialPropertyName>(
      "solid_jacobian_name",
      "solid_reference_J",
      "J_s property used by the optional explicit mass-consistency check.");
  params.addParam<MaterialPropertyName>(
      "aggregate_solid_volume_fraction_name",
      "",
      "Aggregate skeleton solid volume fraction phi_s for the optional explicit "
      "mass-consistency check.");
  params.addParam<std::vector<MaterialPropertyName>>(
      "skeleton_component_reference_accumulation_names",
      {},
      "Registered skeleton solid component referential accumulations J_s rho_a^alpha for the "
      "optional explicit mass-consistency check.");
  params.addRangeCheckedParam<Real>("mass_consistency_tolerance",
                                    1e-10,
                                    "mass_consistency_tolerance>=0",
                                    "Absolute rejection tolerance for vbar_s - J_s phi_s / "
                                    "sum(J_s rho_a^alpha).");
  params.addParam<MaterialPropertyName>(
      "mass_consistency_residual_name",
      "solid_specific_volume_mass_consistency_residual",
      "Output residual vbar_s - J_s phi_s / sum(J_s rho_a^alpha) for explicit reduced closures.");
  return params;
}

ADSkeletonSpecificVolumeBiotMaterial::ADSkeletonSpecificVolumeBiotMaterial(
    const InputParameters & parameters)
  : DerivativeMaterialInterface<Material>(parameters),
    _specific_volume_name(getParam<MaterialPropertyName>("intrinsic_specific_volume_name")),
    _specific_volume_jacobian_derivative_name(
        getParam<MaterialPropertyName>("intrinsic_specific_volume_jacobian_derivative_name")
                .empty()
            ? derivativePropertyNameFirst(_specific_volume_name,
                                          getParam<std::string>("jacobian_symbol"))
            : getParam<MaterialPropertyName>(
                  "intrinsic_specific_volume_jacobian_derivative_name")),
    _specific_volume(getADMaterialProperty<Real>(_specific_volume_name)),
    _specific_volume_jacobian_derivative(nullptr),
    _reference_specific_volume(getParam<Real>("reference_specific_volume")),
    _solid_J(nullptr),
    _aggregate_solid_volume_fraction(nullptr),
    _check_mass_consistency(getParam<bool>("check_mass_consistency")),
    _mass_consistency_tolerance(getParam<Real>("mass_consistency_tolerance")),
    _biot_coefficient(
        declareADProperty<Real>(getParam<MaterialPropertyName>("biot_coefficient_name"))),
    _intrinsic_skeleton_density(declareADProperty<Real>(
        getParam<MaterialPropertyName>("intrinsic_skeleton_density_name"))),
    _mass_consistency_residual(declareADProperty<Real>(
        getParam<MaterialPropertyName>("mass_consistency_residual_name")))
{
  if (getParam<bool>("implicit_closure") &&
      getParam<MaterialPropertyName>("intrinsic_specific_volume_jacobian_derivative_name").empty())
    paramError("intrinsic_specific_volume_jacobian_derivative_name",
               "Implicit skeleton specific-volume closures require an explicitly supplied "
               "fixed-",
               getParam<std::string>("fixed_pressure_symbol"),
               " tangent material property.");

  _specific_volume_jacobian_derivative =
      &getADMaterialProperty<Real>(_specific_volume_jacobian_derivative_name);

  if (_check_mass_consistency)
  {
    if (getParam<MaterialPropertyName>("aggregate_solid_volume_fraction_name").empty())
      paramError("aggregate_solid_volume_fraction_name",
                 "Supply phi_s when check_mass_consistency=true.");
    const auto accumulation_names =
        getParam<std::vector<MaterialPropertyName>>("skeleton_component_reference_accumulation_names");
    if (accumulation_names.empty())
      paramError("skeleton_component_reference_accumulation_names",
                 "Supply at least one J_s rho_a^alpha accumulation when "
                 "check_mass_consistency=true.");

    _solid_J = &getADMaterialProperty<Real>("solid_jacobian_name");
    _aggregate_solid_volume_fraction =
        &getADMaterialProperty<Real>("aggregate_solid_volume_fraction_name");
    _skeleton_component_reference_accumulations.reserve(accumulation_names.size());
    for (const auto & name : accumulation_names)
      _skeleton_component_reference_accumulations.push_back(&getADMaterialProperty<Real>(name));
  }
}

void
ADSkeletonSpecificVolumeBiotMaterial::computeQpProperties()
{
  if (MetaPhysicL::raw_value(_specific_volume[_qp]) <= 0.0)
    mooseError("ADSkeletonSpecificVolumeBiotMaterial requires positive intrinsic skeleton "
               "specific volume.");

  _intrinsic_skeleton_density[_qp] = 1.0 / _specific_volume[_qp];
  _biot_coefficient[_qp] =
      1.0 - (*_specific_volume_jacobian_derivative)[_qp] / _reference_specific_volume;

  _mass_consistency_residual[_qp] = 0.0;
  if (_check_mass_consistency)
  {
    ADReal reference_accumulation_sum = 0.0;
    for (const auto * accumulation : _skeleton_component_reference_accumulations)
      reference_accumulation_sum += (*accumulation)[_qp];
    if (MetaPhysicL::raw_value(reference_accumulation_sum) <= 0.0)
      mooseError("ADSkeletonSpecificVolumeBiotMaterial requires positive skeleton component "
                 "referential accumulation for the mass-consistency check.");

    _mass_consistency_residual[_qp] =
        _specific_volume[_qp] -
        (*_solid_J)[_qp] * (*_aggregate_solid_volume_fraction)[_qp] /
            reference_accumulation_sum;
    if (std::abs(MetaPhysicL::raw_value(_mass_consistency_residual[_qp])) >
        _mass_consistency_tolerance)
      mooseError("Explicit skeleton specific-volume closure violates vbar_s = J_s phi_s / "
                 "sum(J_s rho_a^alpha) by ",
                 MetaPhysicL::raw_value(_mass_consistency_residual[_qp]),
                 ", exceeding tolerance ",
                 _mass_consistency_tolerance,
                 ".");
  }
}
