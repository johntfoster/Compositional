#include "ADIdealMixtureFluidEOSMaterial.h"

#include "metaphysicl/raw_type.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADIdealMixtureFluidEOSMaterial);

InputParameters
ADIdealMixtureFluidEOSMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Computes a neutral, single-fluid, ideal-mixture EOS reduction. The closure uses "
      "pressure and temperature as primitive variables, computes intrinsic density from a "
      "slightly compressible pressure law, and evaluates neutral component potentials "
      "from a Helmholtz density derivative at fixed phase volume fraction, temperature, "
      "other component densities, and kinematic/internal fields.");
  params.addParam<MaterialPropertyName>(
      "jacobian_name", "solid_reference_J", "Material property name for J.");
  params.addRequiredCoupledVar("pressure", "Primitive phase pressure backbone or unenriched field.");
  params.addCoupledVar("pressure_enrichment",
                       "Optional P0 pressure enrichment. When supplied, EOS state uses "
                       "pressure + pressure_enr.");
  params.addRequiredCoupledVar("temperature", "Primitive phase temperature.");
  params.addRequiredCoupledVar("porosity", "Fluid phase volume fraction phi_f.");
  params.addRequiredCoupledVar("component_mass_fractions",
                               "Component mass fractions eta_f^alpha.");
  params.addRequiredRangeCheckedParam<Real>(
      "reference_density", "reference_density>0", "Intrinsic density at reference pressure.");
  params.addParam<Real>("reference_pressure", 0.0, "Reference pressure.");
  params.addRequiredRangeCheckedParam<Real>(
      "compressibility", "compressibility>0", "Constant fluid compressibility.");
  params.addParam<Real>("mixture_constant",
                        0.0,
                        "Common ideal-mixture coefficient multiplying theta sum eta ln eta.");
  params.addParam<bool>(
      "enforce_mass_fraction_sum",
      true,
      "Whether to reject quadrature states whose supplied component mass fractions do not sum to one.");
  params.addRangeCheckedParam<Real>("mass_fraction_sum_tol",
                                    1e-10,
                                    "mass_fraction_sum_tol>=0",
                                    "Tolerance used when enforce_mass_fraction_sum is true.");
  params.addRequiredParam<std::vector<Real>>(
      "component_reference_potentials",
      "Reference neutral component potentials for each component.");
  params.addParam<MaterialPropertyName>("intrinsic_density_name",
                                        "intrinsic_density_from_eos",
                                        "Material property name for rhobar_f.");
  params.addParam<MaterialPropertyName>("specific_helmholtz_free_energy_name",
                                        "specific_helmholtz_free_energy",
                                        "Material property name for psi_f.");
  params.addParam<MaterialPropertyName>("current_phase_mass_density_name",
                                        "current_phase_mass_density",
                                        "Material property name for phi_f rhobar_f.");
  params.addParam<MaterialPropertyName>(
      "mass_fraction_sum_name",
      "mass_fraction_sum",
      "Material property name for sum_alpha eta_f^alpha.");
  params.addParam<MaterialPropertyName>(
      "pressure_from_helmholtz_density_derivative_name",
      "pressure_from_helmholtz_density_derivative",
      "Material property name for rhobar_f^2 d psi_vol / d rhobar_f.");
  params.addParam<MaterialPropertyName>("pressure_identity_residual_name",
                                        "pressure_identity_residual",
                                        "Material property name for rhobar_f^2 d psi_vol / d rhobar_f - p_f.");
  params.addParam<std::vector<MaterialPropertyName>>(
      "reference_component_storage_names",
      {},
      "Material property names for J phi_f rhobar_f eta_f^alpha. Defaults to "
      "reference_component_storage_0, reference_component_storage_1, ...");
  params.addParam<std::vector<MaterialPropertyName>>(
      "neutral_component_potential_names",
      {},
      "Material property names for hat_mu_f^alpha. Defaults to "
      "neutral_component_potential_0, neutral_component_potential_1, ...");
  return params;
}

ADIdealMixtureFluidEOSMaterial::ADIdealMixtureFluidEOSMaterial(
    const InputParameters & parameters)
  : Material(parameters),
    _n_components(coupledComponents("component_mass_fractions")),
    _J(getADMaterialProperty<Real>("jacobian_name")),
    _pressure(adCoupledValue("pressure")),
    _pressure_enrichment(isCoupled("pressure_enrichment") ? &adCoupledValue("pressure_enrichment")
                                                          : nullptr),
    _temperature(adCoupledValue("temperature")),
    _porosity(adCoupledValue("porosity")),
    _reference_density(getParam<Real>("reference_density")),
    _reference_pressure(getParam<Real>("reference_pressure")),
    _compressibility(getParam<Real>("compressibility")),
    _mixture_constant(getParam<Real>("mixture_constant")),
    _enforce_mass_fraction_sum(getParam<bool>("enforce_mass_fraction_sum")),
    _mass_fraction_sum_tol(getParam<Real>("mass_fraction_sum_tol")),
    _component_reference_potentials(getParam<std::vector<Real>>("component_reference_potentials")),
    _intrinsic_density(
        declareADProperty<Real>(getParam<MaterialPropertyName>("intrinsic_density_name"))),
    _specific_helmholtz_free_energy(
        declareADProperty<Real>(getParam<MaterialPropertyName>("specific_helmholtz_free_energy_name"))),
    _current_phase_mass_density(
        declareADProperty<Real>(getParam<MaterialPropertyName>("current_phase_mass_density_name"))),
    _mass_fraction_sum(
        declareADProperty<Real>(getParam<MaterialPropertyName>("mass_fraction_sum_name"))),
    _pressure_from_helmholtz_density_derivative(declareADProperty<Real>(
        getParam<MaterialPropertyName>("pressure_from_helmholtz_density_derivative_name"))),
    _pressure_identity_residual(
        declareADProperty<Real>(getParam<MaterialPropertyName>("pressure_identity_residual_name")))
{
  if (_component_reference_potentials.size() != _n_components)
    paramError("component_reference_potentials",
               "The number of reference potentials must match component_mass_fractions.");

  const auto storage_names =
      getParam<std::vector<MaterialPropertyName>>("reference_component_storage_names");
  const auto potential_names =
      getParam<std::vector<MaterialPropertyName>>("neutral_component_potential_names");

  if (!storage_names.empty() && storage_names.size() != _n_components)
    paramError("reference_component_storage_names",
               "The number of storage material property names must match component_mass_fractions.");
  if (!potential_names.empty() && potential_names.size() != _n_components)
    paramError("neutral_component_potential_names",
               "The number of potential material property names must match component_mass_fractions.");

  for (unsigned int i = 0; i < _n_components; ++i)
  {
    _component_mass_fractions.push_back(&adCoupledValue("component_mass_fractions", i));

    const MaterialPropertyName storage_name = storage_names.empty()
                                                  ? MaterialPropertyName("reference_component_storage_" +
                                                                         std::to_string(i))
                                                  : storage_names[i];
    const MaterialPropertyName potential_name =
        potential_names.empty()
            ? MaterialPropertyName("neutral_component_potential_" + std::to_string(i))
            : potential_names[i];

    _reference_component_storages.push_back(&declareADProperty<Real>(storage_name));
    _neutral_component_potentials.push_back(&declareADProperty<Real>(potential_name));
  }
}

void
ADIdealMixtureFluidEOSMaterial::computeQpProperties()
{
  using std::exp;
  using std::log;

  const ADReal pressure = _pressure[_qp] + (_pressure_enrichment ? (*_pressure_enrichment)[_qp] : 0.0);
  const ADReal pressure_offset = pressure - _reference_pressure;
  const ADReal density_ratio = exp(_compressibility * pressure_offset);
  _intrinsic_density[_qp] = _reference_density * density_ratio;
  _current_phase_mass_density[_qp] = _porosity[_qp] * _intrinsic_density[_qp];
  _pressure_from_helmholtz_density_derivative[_qp] =
      _reference_pressure + log(density_ratio) / _compressibility;
  _pressure_identity_residual[_qp] =
      _pressure_from_helmholtz_density_derivative[_qp] - pressure;

  const ADReal volumetric_helmholtz =
      (_reference_pressure + 1.0 / _compressibility -
       (pressure + 1.0 / _compressibility) / density_ratio) /
      _reference_density;

  _mass_fraction_sum[_qp] = 0.0;
  for (unsigned int i = 0; i < _n_components; ++i)
    _mass_fraction_sum[_qp] += (*_component_mass_fractions[i])[_qp];

  if (_enforce_mass_fraction_sum &&
      std::abs(MetaPhysicL::raw_value(_mass_fraction_sum[_qp] - 1.0)) > _mass_fraction_sum_tol)
    mooseError("ADIdealMixtureFluidEOSMaterial requires component mass fractions to sum to one. "
               "Got ",
               MetaPhysicL::raw_value(_mass_fraction_sum[_qp]),
               " at quadrature point ",
               _qp,
               ".");

  ADReal mixing_helmholtz = 0.0;
  for (unsigned int i = 0; i < _n_components; ++i)
  {
    const ADReal eta = (*_component_mass_fractions[i])[_qp];
    mixing_helmholtz +=
        eta * (_component_reference_potentials[i] +
               _mixture_constant * _temperature[_qp] * log(eta));
  }

  _specific_helmholtz_free_energy[_qp] = volumetric_helmholtz + mixing_helmholtz;

  for (unsigned int i = 0; i < _n_components; ++i)
  {
    const ADReal eta = (*_component_mass_fractions[i])[_qp];
    (*_reference_component_storages[i])[_qp] =
        _J[_qp] * _current_phase_mass_density[_qp] * eta;
    (*_neutral_component_potentials[i])[_qp] =
        volumetric_helmholtz + pressure / _intrinsic_density[_qp] +
        _component_reference_potentials[i] +
        _mixture_constant * _temperature[_qp] * log(eta);
  }
}
