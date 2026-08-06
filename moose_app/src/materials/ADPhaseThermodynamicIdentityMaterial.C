#include "ADPhaseThermodynamicIdentityMaterial.h"

#include "metaphysicl/raw_type.h"

#include <cmath>

registerMooseObject("MulticomponentReactiveFlowApp", ADPhaseThermodynamicIdentityMaterial);

InputParameters
ADPhaseThermodynamicIdentityMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Evaluates the manuscript absolute fluid saturation/pressure identities and the "
      "solid-phase Legendre/equivalent-pressure identities as selectable AD material "
      "properties and residuals.");

  params.addParam<bool>("include_fluid_identities", true, "Evaluate the fluid identity family.");
  params.addParam<bool>(
      "include_fluid_gradients",
      false,
      "Evaluate full product-rule gradients of the weighted saturation force and reconstructed "
      "actual phase pressures. Requires include_fluid_identities=true.");
  params.addParam<bool>(
      "include_solid_legendre", false, "Evaluate the solid phase Legendre identity family.");
  params.addParam<bool>("check_admissible_saturations",
                        true,
                        "Reject a negative fluid saturation before evaluating the identities.");
  params.addParam<bool>("enforce_identity_residuals",
                        false,
                        "Reject identity residuals larger than their dimensionally matched "
                        "tolerances. Leave false "
                        "when the residual properties are used in nonlinear equations.");
  params.addRangeCheckedParam<Real>(
      "dimensionless_identity_tolerance",
      1e-10,
      "dimensionless_identity_tolerance>=0",
      "Tolerance for dimensionless saturation-sum residuals.");
  params.addRangeCheckedParam<Real>(
      "pressure_identity_tolerance",
      1e-6,
      "pressure_identity_tolerance>=0",
      "Tolerance, in the deck pressure unit, for pressure, potential, saturation-force, and "
      "Euler-Lagrange identity residuals.");
  params.addRangeCheckedParam<Real>(
      "rate_identity_tolerance",
      1e-12,
      "rate_identity_tolerance>=0",
      "Tolerance, in inverse deck time units, for the saturation-rate-sum residual.");
  params.addRangeCheckedParam<Real>(
      "entropy_production_tolerance",
      1e-12,
      "entropy_production_tolerance>=0",
      "Allowed negative roundoff, in the deck entropy-production unit, for the saturation "
      "entropy-production diagnostic.");

  params.addParam<std::vector<MaterialPropertyName>>(
      "fluid_saturation_names", {}, "Fluid saturation properties S_f.");
  params.addParam<std::vector<MaterialPropertyName>>(
      "fluid_pressure_names", {}, "Fluid mechanical-pressure properties p_f.");
  params.addParam<std::vector<MaterialPropertyName>>(
      "fluid_primitive_potential_names", {}, "Fluid primitive interfacial potentials gamma_f.");
  params.addParam<std::vector<MaterialPropertyName>>(
      "fluid_electric_enthalpy_names", {}, "Fluid electric-enthalpy densities omega_f^+.");
  params.addParam<std::vector<MaterialPropertyName>>(
      "fluid_saturation_force_names", {}, "Generalized saturation-force properties L_f^sat.");
  params.addParam<std::vector<MaterialPropertyName>>(
      "fluid_saturation_rate_names", {}, "Skeleton-following saturation-rate properties dot(S_f).");
  params.addParam<std::vector<MaterialPropertyName>>(
      "fluid_saturation_gradient_names", {}, "Reference gradients Grad_X(S_f).");
  params.addParam<std::vector<MaterialPropertyName>>(
      "fluid_primitive_potential_gradient_names", {}, "Reference gradients Grad_X(gamma_f).");
  params.addParam<std::vector<MaterialPropertyName>>(
      "fluid_electric_enthalpy_gradient_names", {}, "Reference gradients Grad_X(omega_f^+).");
  params.addParam<std::vector<MaterialPropertyName>>(
      "fluid_saturation_force_gradient_names", {}, "Reference gradients Grad_X(L_f^sat).");
  params.addParam<MaterialPropertyName>(
      "equivalent_pressure_gradient_name", "", "Reference gradient Grad_X(p_E).");
  params.addParam<unsigned int>(
      "reference_fluid_index", 0, "Fluid index whose absolute saturation force fixes the gauge.");
  params.addParam<MaterialPropertyName>(
      "reference_saturation_force_name", "", "Deck-selected saturation-force gauge value.");
  params.addParam<std::vector<MaterialPropertyName>>(
      "predicted_force_difference_names",
      {},
      "Onsager predictions for L_f^sat-L_ref^sat in ascending nonreference-fluid order.");
  params.addParam<MaterialPropertyName>(
      "fluid_fraction_name", "", "Total fluid volume fraction phi for dissipation.");
  params.addParam<MaterialPropertyName>(
      "fluid_temperature_name", "", "Positive absolute fluid temperature for entropy production.");
  params.addParam<MaterialPropertyName>(
      "volume_constraint_multiplier_name", "", "Volume-constraint multiplier lambda.");
  params.addParam<MaterialPropertyName>(
      "interfacial_helmholtz_name", "", "Interfacial Helmholtz density gamma.");
  params.addParam<MaterialPropertyName>(
      "equivalent_pressure_name", "", "Supplied equivalent pore pressure p_E.");
  params.addParam<std::vector<MaterialPropertyName>>(
      "fluid_volume_fraction_el_residual_names",
      {},
      "One output name per fluid phase for the absolute volume-fraction Euler-Lagrange residual.");
  params.addParam<std::vector<MaterialPropertyName>>(
      "exposed_saturation_force_names", {}, "One output alias for each absolute L_f^sat.");
  params.addParam<std::vector<MaterialPropertyName>>(
      "force_difference_names",
      {},
      "Outputs L_f^sat-L_ref^sat in ascending nonreference-fluid order.");
  params.addParam<std::vector<MaterialPropertyName>>(
      "force_rate_residual_names",
      {},
      "Outputs (L_f^sat-L_ref^sat)-predicted Onsager force difference.");
  params.addParam<std::vector<MaterialPropertyName>>(
      "reconstructed_fluid_pressure_names",
      {},
      "Outputs p_E+gamma_f+omega_f^++L_f^sat-sum_g S_g L_g^sat.");
  params.addParam<std::vector<MaterialPropertyName>>(
      "fluid_pressure_residual_names", {}, "Outputs supplied p_f minus reconstructed p_f.");
  params.addParam<std::vector<MaterialPropertyName>>(
      "reconstructed_fluid_pressure_gradient_names",
      {},
      "Output full product-rule reference gradients of the reconstructed actual pressures.");
  params.addParam<std::vector<MaterialPropertyName>>(
      "phase_momentum_pressure_potential_gradient_names",
      {},
      "Output Grad_X(p_f-omega_f^+)=Grad_X(p_E+gamma_f+L_f^sat-sum_g S_g "
      "L_g^sat). The isotropic electric-enthalpy gradient cancels from this momentum "
      "potential; electrical momentum is carried by the separate anisotropic Maxwell term.");
  params.addParam<MaterialPropertyName>(
      "saturation_sum_name", "fluid_saturation_sum", "Output sum_f S_f.");
  params.addParam<MaterialPropertyName>("saturation_sum_residual_name",
                                        "fluid_saturation_sum_residual",
                                        "Output sum_f S_f-1.");
  params.addParam<MaterialPropertyName>("saturation_weighted_primitive_potential_name",
                                        "saturation_weighted_primitive_potential",
                                        "Output sum_f S_f gamma_f.");
  params.addParam<MaterialPropertyName>("primitive_potential_sum_residual_name",
                                        "primitive_potential_sum_residual",
                                        "Output sum_f S_f gamma_f-gamma.");
  params.addParam<MaterialPropertyName>("saturation_weighted_saturation_force_name",
                                        "saturation_weighted_saturation_force",
                                        "Output sum_f S_f L_f^sat.");
  params.addParam<MaterialPropertyName>("computed_equivalent_pressure_name",
                                        "computed_equivalent_pressure",
                                        "Output sum_f S_f(p_f-omega_f^+)-gamma.");
  params.addParam<MaterialPropertyName>("equivalent_pressure_residual_name",
                                        "equivalent_pressure_identity_residual",
                                        "Output supplied p_E minus its saturation-weighted value.");
  params.addParam<MaterialPropertyName>("multiplier_equivalent_pressure_residual_name",
                                        "multiplier_equivalent_pressure_residual",
                                        "Output lambda+p_E.");
  params.addParam<MaterialPropertyName>("reference_force_gauge_residual_name",
                                        "reference_saturation_force_gauge_residual",
                                        "Output L_ref^sat minus the selected gauge value.");
  params.addParam<MaterialPropertyName>("saturation_rate_sum_residual_name",
                                        "fluid_saturation_rate_sum_residual",
                                        "Output sum_f dot(S_f).");
  params.addParam<MaterialPropertyName>("saturation_force_rate_power_name",
                                        "saturation_force_rate_power",
                                        "Output phi sum_f L_f^sat dot(S_f).");
  params.addParam<MaterialPropertyName>("saturation_entropy_production_name",
                                        "saturation_entropy_production",
                                        "Output phi sum_f L_f^sat dot(S_f)/theta_F.");
  params.addParam<MaterialPropertyName>(
      "saturation_weighted_saturation_force_gradient_name",
      "saturation_weighted_saturation_force_gradient",
      "Output Grad_X(sum_f S_f L_f^sat) with the complete product rule.");

  params.addParam<MaterialPropertyName>(
      "solid_specific_helmholtz_name", "", "Solid specific Helmholtz energy psi_s.");
  params.addParam<MaterialPropertyName>(
      "solid_electric_enthalpy_name", "", "Solid electric-enthalpy density omega_s^+.");
  params.addParam<MaterialPropertyName>(
      "solid_intrinsic_specific_volume_name", "", "Solid intrinsic specific volume vbar_s.");
  params.addParam<MaterialPropertyName>(
      "solid_phase_pressure_name", "", "Solid mechanical phase pressure p_s.");
  params.addParam<MaterialPropertyName>(
      "solid_equivalent_pressure_name", "", "Supplied solid equivalent pressure p_E.");
  params.addParam<MaterialPropertyName>("phase_legendre_transform_name",
                                        "solid_phase_legendre_transform",
                                        "Output psi_s+omega_s^+ vbar_s+p_E vbar_s.");
  params.addParam<MaterialPropertyName>("phase_legendre_pressure_derivative_name",
                                        "solid_phase_legendre_pressure_derivative",
                                        "Output vbar_s, the natural p_E derivative.");
  params.addParam<MaterialPropertyName>("phase_equivalent_pressure_output_name",
                                        "solid_phase_equivalent_pressure",
                                        "Output p_s-omega_s^+.");
  params.addParam<MaterialPropertyName>("phase_equivalent_pressure_residual_name",
                                        "solid_phase_equivalent_pressure_residual",
                                        "Output supplied p_E-(p_s-omega_s^+).");
  return params;
}

ADPhaseThermodynamicIdentityMaterial::ADPhaseThermodynamicIdentityMaterial(
    const InputParameters & parameters)
  : Material(parameters),
    _include_fluid_identities(getParam<bool>("include_fluid_identities")),
    _include_fluid_gradients(getParam<bool>("include_fluid_gradients")),
    _include_solid_legendre(getParam<bool>("include_solid_legendre")),
    _check_admissible_saturations(getParam<bool>("check_admissible_saturations")),
    _enforce_identity_residuals(getParam<bool>("enforce_identity_residuals")),
    _dimensionless_identity_tolerance(getParam<Real>("dimensionless_identity_tolerance")),
    _pressure_identity_tolerance(getParam<Real>("pressure_identity_tolerance")),
    _rate_identity_tolerance(getParam<Real>("rate_identity_tolerance")),
    _entropy_production_tolerance(getParam<Real>("entropy_production_tolerance")),
    _volume_constraint_multiplier(nullptr),
    _interfacial_helmholtz(nullptr),
    _equivalent_pressure(nullptr),
    _reference_saturation_force(nullptr),
    _fluid_fraction(nullptr),
    _fluid_temperature(nullptr),
    _equivalent_pressure_gradient(nullptr),
    _reference_fluid_index(getParam<unsigned int>("reference_fluid_index")),
    _saturation_sum(declareADProperty<Real>(getParam<MaterialPropertyName>("saturation_sum_name"))),
    _saturation_sum_residual(
        declareADProperty<Real>(getParam<MaterialPropertyName>("saturation_sum_residual_name"))),
    _saturation_weighted_primitive_potential(declareADProperty<Real>(
        getParam<MaterialPropertyName>("saturation_weighted_primitive_potential_name"))),
    _primitive_potential_sum_residual(declareADProperty<Real>(
        getParam<MaterialPropertyName>("primitive_potential_sum_residual_name"))),
    _saturation_weighted_saturation_force(declareADProperty<Real>(
        getParam<MaterialPropertyName>("saturation_weighted_saturation_force_name"))),
    _computed_equivalent_pressure(declareADProperty<Real>(
        getParam<MaterialPropertyName>("computed_equivalent_pressure_name"))),
    _equivalent_pressure_residual(declareADProperty<Real>(
        getParam<MaterialPropertyName>("equivalent_pressure_residual_name"))),
    _multiplier_equivalent_pressure_residual(declareADProperty<Real>(
        getParam<MaterialPropertyName>("multiplier_equivalent_pressure_residual_name"))),
    _reference_force_gauge_residual(declareADProperty<Real>(
        getParam<MaterialPropertyName>("reference_force_gauge_residual_name"))),
    _saturation_rate_sum_residual(declareADProperty<Real>(
        getParam<MaterialPropertyName>("saturation_rate_sum_residual_name"))),
    _saturation_force_rate_power(declareADProperty<Real>(
        getParam<MaterialPropertyName>("saturation_force_rate_power_name"))),
    _saturation_entropy_production(declareADProperty<Real>(
        getParam<MaterialPropertyName>("saturation_entropy_production_name"))),
    _saturation_weighted_saturation_force_gradient(declareADProperty<RealVectorValue>(
        getParam<MaterialPropertyName>(
            "saturation_weighted_saturation_force_gradient_name"))),
    _solid_specific_helmholtz(nullptr),
    _solid_electric_enthalpy(nullptr),
    _solid_intrinsic_specific_volume(nullptr),
    _solid_phase_pressure(nullptr),
    _solid_equivalent_pressure(nullptr),
    _phase_legendre_transform(declareADProperty<Real>(
        getParam<MaterialPropertyName>("phase_legendre_transform_name"))),
    _phase_legendre_pressure_derivative(declareADProperty<Real>(
        getParam<MaterialPropertyName>("phase_legendre_pressure_derivative_name"))),
    _phase_equivalent_pressure(declareADProperty<Real>(
        getParam<MaterialPropertyName>("phase_equivalent_pressure_output_name"))),
    _phase_equivalent_pressure_residual(declareADProperty<Real>(
        getParam<MaterialPropertyName>("phase_equivalent_pressure_residual_name")))
{
  if (!_include_fluid_identities && !_include_solid_legendre)
    paramError("include_fluid_identities", "Enable at least one identity family.");
  if (_include_fluid_gradients && !_include_fluid_identities)
    paramError("include_fluid_gradients", "Fluid gradients require fluid identities.");

  if (_include_fluid_identities)
  {
    const auto saturations = getParam<std::vector<MaterialPropertyName>>("fluid_saturation_names");
    const auto pressures = getParam<std::vector<MaterialPropertyName>>("fluid_pressure_names");
    const auto primitive =
        getParam<std::vector<MaterialPropertyName>>("fluid_primitive_potential_names");
    const auto electric =
        getParam<std::vector<MaterialPropertyName>>("fluid_electric_enthalpy_names");
    const auto forces =
        getParam<std::vector<MaterialPropertyName>>("fluid_saturation_force_names");
    const auto rates =
        getParam<std::vector<MaterialPropertyName>>("fluid_saturation_rate_names");
    const auto predicted_differences =
        getParam<std::vector<MaterialPropertyName>>("predicted_force_difference_names");
    const auto residual_names =
        getParam<std::vector<MaterialPropertyName>>("fluid_volume_fraction_el_residual_names");
    const auto exposed_force_names =
        getParam<std::vector<MaterialPropertyName>>("exposed_saturation_force_names");
    const auto force_difference_names =
        getParam<std::vector<MaterialPropertyName>>("force_difference_names");
    const auto force_rate_residual_names =
        getParam<std::vector<MaterialPropertyName>>("force_rate_residual_names");
    const auto reconstructed_pressure_names =
        getParam<std::vector<MaterialPropertyName>>("reconstructed_fluid_pressure_names");
    const auto pressure_residual_names =
        getParam<std::vector<MaterialPropertyName>>("fluid_pressure_residual_names");
    const auto saturation_gradient_names =
        getParam<std::vector<MaterialPropertyName>>("fluid_saturation_gradient_names");
    const auto primitive_gradient_names = getParam<std::vector<MaterialPropertyName>>(
        "fluid_primitive_potential_gradient_names");
    const auto electric_gradient_names = getParam<std::vector<MaterialPropertyName>>(
        "fluid_electric_enthalpy_gradient_names");
    const auto force_gradient_names = getParam<std::vector<MaterialPropertyName>>(
        "fluid_saturation_force_gradient_names");
    const auto reconstructed_pressure_gradient_names =
        getParam<std::vector<MaterialPropertyName>>(
            "reconstructed_fluid_pressure_gradient_names");
    const auto momentum_pressure_gradient_names =
        getParam<std::vector<MaterialPropertyName>>(
            "phase_momentum_pressure_potential_gradient_names");
    const auto n = saturations.size();
    if (n == 0)
      paramError("fluid_saturation_names", "Supply at least one fluid phase.");
    if (pressures.size() != n || primitive.size() != n || electric.size() != n ||
        forces.size() != n || rates.size() != n || residual_names.size() != n ||
        exposed_force_names.size() != n || reconstructed_pressure_names.size() != n ||
        pressure_residual_names.size() != n || predicted_differences.size() + 1 != n ||
        force_difference_names.size() + 1 != n || force_rate_residual_names.size() + 1 != n)
      paramError("fluid_saturation_names",
                 "Supply one value and output name for every fluid phase, and one force "
                 "difference and force-rate residual for every nonreference phase.");
    if (_reference_fluid_index >= n)
      paramError("reference_fluid_index", "The reference fluid index is outside the supplied list.");
    if (getParam<MaterialPropertyName>("volume_constraint_multiplier_name").empty() ||
        getParam<MaterialPropertyName>("interfacial_helmholtz_name").empty() ||
        getParam<MaterialPropertyName>("equivalent_pressure_name").empty() ||
        getParam<MaterialPropertyName>("reference_saturation_force_name").empty() ||
        getParam<MaterialPropertyName>("fluid_fraction_name").empty() ||
        getParam<MaterialPropertyName>("fluid_temperature_name").empty())
      paramError("equivalent_pressure_name",
                 "Fluid identities require lambda, gamma, and equivalent-pressure properties.");

    for (const auto i : make_range(n))
    {
      _fluid_saturations.push_back(&getADMaterialProperty<Real>(saturations[i]));
      _fluid_pressures.push_back(&getADMaterialProperty<Real>(pressures[i]));
      _fluid_primitive_potentials.push_back(&getADMaterialProperty<Real>(primitive[i]));
      _fluid_electric_enthalpies.push_back(&getADMaterialProperty<Real>(electric[i]));
      _fluid_saturation_forces.push_back(&getADMaterialProperty<Real>(forces[i]));
      _fluid_saturation_rates.push_back(&getADMaterialProperty<Real>(rates[i]));
      _fluid_volume_fraction_el_residuals.push_back(
          &declareADProperty<Real>(residual_names[i]));
      _exposed_saturation_forces.push_back(&declareADProperty<Real>(exposed_force_names[i]));
      _reconstructed_fluid_pressures.push_back(
          &declareADProperty<Real>(reconstructed_pressure_names[i]));
      _fluid_pressure_residuals.push_back(
          &declareADProperty<Real>(pressure_residual_names[i]));
    }
    if (_include_fluid_gradients)
    {
      if (saturation_gradient_names.size() != n || primitive_gradient_names.size() != n ||
          electric_gradient_names.size() != n || force_gradient_names.size() != n ||
          reconstructed_pressure_gradient_names.size() != n ||
          momentum_pressure_gradient_names.size() != n ||
          getParam<MaterialPropertyName>("equivalent_pressure_gradient_name").empty())
        paramError("include_fluid_gradients",
                   "Supply one saturation, primitive-potential, electric-enthalpy, "
                   "saturation-force, reconstructed-pressure, and momentum-pressure-potential "
                   "gradient name per phase, "
                   "together with the equivalent-pressure gradient.");
      for (const auto i : make_range(n))
      {
        _fluid_saturation_gradients.push_back(
            &getADMaterialProperty<RealVectorValue>(saturation_gradient_names[i]));
        _fluid_primitive_potential_gradients.push_back(
            &getADMaterialProperty<RealVectorValue>(primitive_gradient_names[i]));
        _fluid_electric_enthalpy_gradients.push_back(
            &getADMaterialProperty<RealVectorValue>(electric_gradient_names[i]));
        _fluid_saturation_force_gradients.push_back(
            &getADMaterialProperty<RealVectorValue>(force_gradient_names[i]));
        _reconstructed_fluid_pressure_gradients.push_back(
            &declareADProperty<RealVectorValue>(reconstructed_pressure_gradient_names[i]));
        _phase_momentum_pressure_potential_gradients.push_back(
            &declareADProperty<RealVectorValue>(momentum_pressure_gradient_names[i]));
      }
      _equivalent_pressure_gradient = &getADMaterialProperty<RealVectorValue>(
          getParam<MaterialPropertyName>("equivalent_pressure_gradient_name"));
    }
    for (const auto i : index_range(predicted_differences))
    {
      _predicted_force_differences.push_back(
          &getADMaterialProperty<Real>(predicted_differences[i]));
      _force_differences.push_back(&declareADProperty<Real>(force_difference_names[i]));
      _force_rate_residuals.push_back(&declareADProperty<Real>(force_rate_residual_names[i]));
    }
    _volume_constraint_multiplier = &getADMaterialProperty<Real>(
        getParam<MaterialPropertyName>("volume_constraint_multiplier_name"));
    _interfacial_helmholtz = &getADMaterialProperty<Real>(
        getParam<MaterialPropertyName>("interfacial_helmholtz_name"));
    _equivalent_pressure = &getADMaterialProperty<Real>(
        getParam<MaterialPropertyName>("equivalent_pressure_name"));
    _reference_saturation_force = &getADMaterialProperty<Real>(
        getParam<MaterialPropertyName>("reference_saturation_force_name"));
    _fluid_fraction = &getADMaterialProperty<Real>(
        getParam<MaterialPropertyName>("fluid_fraction_name"));
    _fluid_temperature = &getADMaterialProperty<Real>(
        getParam<MaterialPropertyName>("fluid_temperature_name"));
  }

  if (_include_solid_legendre)
  {
    const std::vector<std::string> required = {"solid_specific_helmholtz_name",
                                               "solid_electric_enthalpy_name",
                                               "solid_intrinsic_specific_volume_name",
                                               "solid_phase_pressure_name",
                                               "solid_equivalent_pressure_name"};
    for (const auto & name : required)
      if (getParam<MaterialPropertyName>(name).empty())
        paramError(name, "This property is required when include_solid_legendre=true.");
    _solid_specific_helmholtz = &getADMaterialProperty<Real>(
        getParam<MaterialPropertyName>("solid_specific_helmholtz_name"));
    _solid_electric_enthalpy = &getADMaterialProperty<Real>(
        getParam<MaterialPropertyName>("solid_electric_enthalpy_name"));
    _solid_intrinsic_specific_volume = &getADMaterialProperty<Real>(
        getParam<MaterialPropertyName>("solid_intrinsic_specific_volume_name"));
    _solid_phase_pressure = &getADMaterialProperty<Real>(
        getParam<MaterialPropertyName>("solid_phase_pressure_name"));
    _solid_equivalent_pressure = &getADMaterialProperty<Real>(
        getParam<MaterialPropertyName>("solid_equivalent_pressure_name"));
  }
}

void
ADPhaseThermodynamicIdentityMaterial::computeQpProperties()
{
  _saturation_sum[_qp] = 0.0;
  _saturation_sum_residual[_qp] = 0.0;
  _saturation_weighted_primitive_potential[_qp] = 0.0;
  _primitive_potential_sum_residual[_qp] = 0.0;
  _saturation_weighted_saturation_force[_qp] = 0.0;
  _computed_equivalent_pressure[_qp] = 0.0;
  _equivalent_pressure_residual[_qp] = 0.0;
  _multiplier_equivalent_pressure_residual[_qp] = 0.0;
  _reference_force_gauge_residual[_qp] = 0.0;
  _saturation_rate_sum_residual[_qp] = 0.0;
  _saturation_force_rate_power[_qp] = 0.0;
  _saturation_entropy_production[_qp] = 0.0;
  _saturation_weighted_saturation_force_gradient[_qp].zero();
  for (auto * residual : _fluid_volume_fraction_el_residuals)
    (*residual)[_qp] = 0.0;
  for (auto * residual : _force_rate_residuals)
    (*residual)[_qp] = 0.0;

  if (_include_fluid_identities)
  {
    for (const auto i : index_range(_fluid_saturations))
    {
      const ADReal saturation = (*_fluid_saturations[i])[_qp];
      if (_check_admissible_saturations && MetaPhysicL::raw_value(saturation) < 0.0)
        mooseError(name(), ": fluid saturations must be nonnegative.");
      _saturation_sum[_qp] += saturation;
      _saturation_weighted_primitive_potential[_qp] +=
          saturation * (*_fluid_primitive_potentials[i])[_qp];
      _saturation_weighted_saturation_force[_qp] +=
          saturation * (*_fluid_saturation_forces[i])[_qp];
      _computed_equivalent_pressure[_qp] +=
          saturation * ((*_fluid_pressures[i])[_qp] - (*_fluid_electric_enthalpies[i])[_qp]);
      (*_exposed_saturation_forces[i])[_qp] = (*_fluid_saturation_forces[i])[_qp];
      _saturation_rate_sum_residual[_qp] += (*_fluid_saturation_rates[i])[_qp];
      _saturation_force_rate_power[_qp] +=
          (*_fluid_saturation_forces[i])[_qp] * (*_fluid_saturation_rates[i])[_qp];
    }
    _saturation_sum_residual[_qp] = _saturation_sum[_qp] - 1.0;
    _primitive_potential_sum_residual[_qp] =
        _saturation_weighted_primitive_potential[_qp] - (*_interfacial_helmholtz)[_qp];
    _computed_equivalent_pressure[_qp] -= (*_interfacial_helmholtz)[_qp];
    _equivalent_pressure_residual[_qp] =
        (*_equivalent_pressure)[_qp] - _computed_equivalent_pressure[_qp];
    _multiplier_equivalent_pressure_residual[_qp] =
        (*_volume_constraint_multiplier)[_qp] + (*_equivalent_pressure)[_qp];
    _reference_force_gauge_residual[_qp] =
        (*_fluid_saturation_forces[_reference_fluid_index])[_qp] -
        (*_reference_saturation_force)[_qp];
    if (MetaPhysicL::raw_value((*_fluid_fraction)[_qp]) < 0.0)
      mooseError(name(), ": total fluid volume fraction must be nonnegative.");
    if (MetaPhysicL::raw_value((*_fluid_temperature)[_qp]) <= 0.0)
      mooseError(name(), ": fluid temperature must be positive.");
    _saturation_force_rate_power[_qp] *= (*_fluid_fraction)[_qp];
    _saturation_entropy_production[_qp] =
        _saturation_force_rate_power[_qp] / (*_fluid_temperature)[_qp];

    if (_include_fluid_gradients)
      for (const auto i : index_range(_fluid_saturations))
        _saturation_weighted_saturation_force_gradient[_qp] +=
            (*_fluid_saturation_gradients[i])[_qp] * (*_fluid_saturation_forces[i])[_qp] +
            (*_fluid_saturations[i])[_qp] * (*_fluid_saturation_force_gradients[i])[_qp];

    for (const auto i : index_range(_fluid_saturations))
    {
      (*_reconstructed_fluid_pressures[i])[_qp] =
          (*_equivalent_pressure)[_qp] + (*_fluid_primitive_potentials[i])[_qp] +
          (*_fluid_electric_enthalpies[i])[_qp] +
          (*_fluid_saturation_forces[i])[_qp] -
          _saturation_weighted_saturation_force[_qp];
      (*_fluid_pressure_residuals[i])[_qp] =
          (*_fluid_pressures[i])[_qp] - (*_reconstructed_fluid_pressures[i])[_qp];
      (*_fluid_volume_fraction_el_residuals[i])[_qp] =
          (*_volume_constraint_multiplier)[_qp] + (*_fluid_pressures[i])[_qp] -
          (*_fluid_primitive_potentials[i])[_qp] -
          (*_fluid_electric_enthalpies[i])[_qp] - (*_fluid_saturation_forces[i])[_qp] +
          _saturation_weighted_saturation_force[_qp];
      if (_include_fluid_gradients)
      {
        (*_reconstructed_fluid_pressure_gradients[i])[_qp] =
            (*_equivalent_pressure_gradient)[_qp] +
            (*_fluid_primitive_potential_gradients[i])[_qp] +
            (*_fluid_electric_enthalpy_gradients[i])[_qp] +
            (*_fluid_saturation_force_gradients[i])[_qp] -
            _saturation_weighted_saturation_force_gradient[_qp];
        (*_phase_momentum_pressure_potential_gradients[i])[_qp] =
            (*_equivalent_pressure_gradient)[_qp] +
            (*_fluid_primitive_potential_gradients[i])[_qp] +
            (*_fluid_saturation_force_gradients[i])[_qp] -
            _saturation_weighted_saturation_force_gradient[_qp];
      }
    }
    unsigned int nonreference = 0;
    for (const auto i : index_range(_fluid_saturations))
      if (i != _reference_fluid_index)
      {
        (*_force_differences[nonreference])[_qp] =
            (*_fluid_saturation_forces[i])[_qp] -
            (*_fluid_saturation_forces[_reference_fluid_index])[_qp];
        (*_force_rate_residuals[nonreference])[_qp] =
            (*_force_differences[nonreference])[_qp] -
            (*_predicted_force_differences[nonreference])[_qp];
        ++nonreference;
      }
  }

  _phase_legendre_transform[_qp] = 0.0;
  _phase_legendre_pressure_derivative[_qp] = 0.0;
  _phase_equivalent_pressure[_qp] = 0.0;
  _phase_equivalent_pressure_residual[_qp] = 0.0;
  if (_include_solid_legendre)
  {
    const ADReal specific_volume = (*_solid_intrinsic_specific_volume)[_qp];
    if (MetaPhysicL::raw_value(specific_volume) <= 0.0)
      mooseError(name(), ": solid intrinsic specific volume must be positive.");
    _phase_legendre_transform[_qp] =
        (*_solid_specific_helmholtz)[_qp] +
        (*_solid_electric_enthalpy)[_qp] * specific_volume +
        (*_solid_equivalent_pressure)[_qp] * specific_volume;
    _phase_legendre_pressure_derivative[_qp] = specific_volume;
    _phase_equivalent_pressure[_qp] =
        (*_solid_phase_pressure)[_qp] - (*_solid_electric_enthalpy)[_qp];
    _phase_equivalent_pressure_residual[_qp] =
        (*_solid_equivalent_pressure)[_qp] - _phase_equivalent_pressure[_qp];
  }

  if (_enforce_identity_residuals)
  {
    auto enforce = [this](const ADReal & residual,
                          const Real tolerance,
                          const std::string & identity,
                          const std::string & tolerance_name) {
      if (std::abs(MetaPhysicL::raw_value(residual)) > tolerance)
        mooseError(name(), ": ", identity, " residual exceeds ", tolerance_name, ".");
    };
    if (_include_fluid_identities)
    {
      enforce(_saturation_sum_residual[_qp],
              _dimensionless_identity_tolerance,
              "saturation sum",
              "dimensionless_identity_tolerance");
      enforce(_primitive_potential_sum_residual[_qp],
              _pressure_identity_tolerance,
              "primitive-potential sum",
              "pressure_identity_tolerance");
      enforce(_equivalent_pressure_residual[_qp],
              _pressure_identity_tolerance,
              "equivalent pressure",
              "pressure_identity_tolerance");
      enforce(_multiplier_equivalent_pressure_residual[_qp],
              _pressure_identity_tolerance,
              "multiplier/equivalent pressure",
              "pressure_identity_tolerance");
      enforce(_reference_force_gauge_residual[_qp],
              _pressure_identity_tolerance,
              "reference saturation-force gauge",
              "pressure_identity_tolerance");
      enforce(_saturation_rate_sum_residual[_qp],
              _rate_identity_tolerance,
              "saturation-rate sum",
              "rate_identity_tolerance");
      for (const auto * residual : _fluid_volume_fraction_el_residuals)
        enforce((*residual)[_qp],
                _pressure_identity_tolerance,
                "fluid volume-fraction Euler-Lagrange",
                "pressure_identity_tolerance");
      for (const auto * residual : _fluid_pressure_residuals)
        enforce((*residual)[_qp],
                _pressure_identity_tolerance,
                "fluid pressure reconstruction",
                "pressure_identity_tolerance");
      for (const auto * residual : _force_rate_residuals)
        enforce((*residual)[_qp],
                _pressure_identity_tolerance,
                "saturation force-rate",
                "pressure_identity_tolerance");
      if (MetaPhysicL::raw_value(_saturation_entropy_production[_qp]) <
          -_entropy_production_tolerance)
        mooseError(name(), ": saturation entropy production is negative.");
    }
    if (_include_solid_legendre)
      enforce(_phase_equivalent_pressure_residual[_qp],
              _pressure_identity_tolerance,
              "solid phase equivalent pressure",
              "pressure_identity_tolerance");
  }
}
