#include "ADHelmholtzElectricEnthalpyEOSMaterial.h"
#include "PhaseRegistry.h"

registerMooseObject("MulticomponentReactiveFlowApp",
                    ADHelmholtzElectricEnthalpyEOSMaterial);

InputParameters
ADHelmholtzElectricEnthalpyEOSMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Builds the manuscript absolute neutral potentials and total phase pressure from the "
      "combined material Helmholtz density and phase electric enthalpy, while exposing material "
      "internal energy and every electrical state-rate coefficient separately.");
  params.addRequiredParam<std::string>("phase", "Registered phase name used to prefix outputs.");
  params.addRequiredParam<UserObjectName>("phase_registry", "Input-deck phase registry.");
  params.addRequiredCoupledVar(
      "partial_densities", "Constituent mass densities per unit current phase volume.");
  params.addRequiredCoupledVar("temperature", "Absolute phase/subsystem temperature.");
  params.addRequiredCoupledVar("phase_fraction", "Current phase volume fraction phi_xi.");
  params.addRequiredParam<MaterialPropertyName>(
      "helmholtz_density_name", "Material Helmholtz density A_xi per current phase volume.");
  params.addRequiredParam<MaterialPropertyName>(
      "electric_enthalpy_name", "Electric-enthalpy density omega_xi^+ per current phase volume.");
  params.addParam<std::vector<MaterialPropertyName>>(
      "neutral_chemical_potential_names",
      {},
      "Optional output names; defaults to <phase>_neutral_chemical_potential_<index>.");
  params.addParam<std::string>(
      "property_prefix", "", "Optional output prefix; defaults to the registered phase name.");
  return params;
}

ADHelmholtzElectricEnthalpyEOSMaterial::ADHelmholtzElectricEnthalpyEOSMaterial(
    const InputParameters & parameters)
  : DerivativeMaterialInterface<Material>(parameters),
    _phase_name(getParam<std::string>("phase")),
    _phase_registry(getUserObject<PhaseRegistry>("phase_registry")),
    _n_components(coupledComponents("partial_densities")),
    _helmholtz_density_name(getParam<MaterialPropertyName>("helmholtz_density_name")),
    _electric_enthalpy_name(getParam<MaterialPropertyName>("electric_enthalpy_name")),
    _helmholtz_density(getADMaterialProperty<Real>(_helmholtz_density_name)),
    _electric_enthalpy(getADMaterialProperty<Real>(_electric_enthalpy_name)),
    _temperature(adCoupledValue("temperature")),
    _temperature_name(coupledName("temperature")),
    _phase_fraction(adCoupledValue("phase_fraction")),
    _helmholtz_temperature_derivative(getADMaterialProperty<Real>(
        derivativePropertyNameFirst(_helmholtz_density_name, _temperature_name))),
    _electric_enthalpy_temperature_derivative(getADMaterialProperty<Real>(
        derivativePropertyNameFirst(_electric_enthalpy_name, _temperature_name))),
    _pressure(declareADProperty<Real>(
        (getParam<std::string>("property_prefix").empty() ? _phase_name
                                                          : getParam<std::string>("property_prefix")) +
        "_pressure")),
    _material_pressure(declareADProperty<Real>(
        (getParam<std::string>("property_prefix").empty() ? _phase_name
                                                          : getParam<std::string>("property_prefix")) +
        "_material_pressure")),
    _dielectric_pressure_correction(declareADProperty<Real>(
        (getParam<std::string>("property_prefix").empty() ? _phase_name
                                                          : getParam<std::string>("property_prefix")) +
        "_dielectric_pressure_correction")),
    _intrinsic_density(declareADProperty<Real>(
        (getParam<std::string>("property_prefix").empty() ? _phase_name
                                                          : getParam<std::string>("property_prefix")) +
        "_intrinsic_density")),
    _bulk_phase_density(declareADProperty<Real>(
        (getParam<std::string>("property_prefix").empty() ? _phase_name
                                                          : getParam<std::string>("property_prefix")) +
        "_bulk_phase_density")),
    _specific_helmholtz_free_energy(declareADProperty<Real>(
        (getParam<std::string>("property_prefix").empty() ? _phase_name
                                                          : getParam<std::string>("property_prefix")) +
        "_specific_helmholtz_free_energy")),
    _specific_internal_energy(declareADProperty<Real>(
        (getParam<std::string>("property_prefix").empty() ? _phase_name
                                                          : getParam<std::string>("property_prefix")) +
        "_specific_internal_energy")),
    _entropy_density(declareADProperty<Real>(
        (getParam<std::string>("property_prefix").empty() ? _phase_name
                                                          : getParam<std::string>("property_prefix")) +
        "_entropy_density")),
    _electric_phase_fraction_rate_coefficient(declareADProperty<Real>(
        (getParam<std::string>("property_prefix").empty() ? _phase_name
                                                          : getParam<std::string>("property_prefix")) +
        "_electric_phase_fraction_rate_coefficient")),
    _electric_temperature_rate_coefficient(declareADProperty<Real>(
        (getParam<std::string>("property_prefix").empty() ? _phase_name
                                                          : getParam<std::string>("property_prefix")) +
        "_electric_temperature_rate_coefficient"))
{
  if (!_phase_registry.hasPhase(_phase_name))
    paramError("phase", "Phase '", _phase_name, "' is not registered.");
  if (_n_components == 0)
    paramError("partial_densities", "Supply at least one constituent partial density.");

  const auto output_prefix = getParam<std::string>("property_prefix").empty()
                                 ? _phase_name
                                 : getParam<std::string>("property_prefix");
  const auto potential_names =
      getParam<std::vector<MaterialPropertyName>>("neutral_chemical_potential_names");
  if (!potential_names.empty() && potential_names.size() != _n_components)
    paramError("neutral_chemical_potential_names",
               "Supply one output name per constituent partial density.");

  for (const auto i : make_range(_n_components))
  {
    _partial_densities.push_back(&adCoupledValue("partial_densities", i));
    _partial_density_names.push_back(coupledName("partial_densities", i));
    _helmholtz_density_derivatives.push_back(&getADMaterialProperty<Real>(
        derivativePropertyNameFirst(_helmholtz_density_name, _partial_density_names.back())));
    _electric_enthalpy_density_derivatives.push_back(&getADMaterialProperty<Real>(
        derivativePropertyNameFirst(_electric_enthalpy_name, _partial_density_names.back())));
    _neutral_chemical_potentials.push_back(&declareADProperty<Real>(
        potential_names.empty()
            ? MaterialPropertyName(output_prefix + "_neutral_chemical_potential_" +
                                   std::to_string(i))
            : potential_names[i]));
    _electric_partial_density_rate_coefficients.push_back(&declareADProperty<Real>(
        output_prefix + "_electric_partial_density_rate_coefficient_" + std::to_string(i)));
  }
}

void
ADHelmholtzElectricEnthalpyEOSMaterial::computeQpProperties()
{
  _intrinsic_density[_qp] = 0.0;
  _material_pressure[_qp] = -_helmholtz_density[_qp];
  _dielectric_pressure_correction[_qp] = 0.0;
  for (const auto i : make_range(_n_components))
  {
    const ADReal material_mu = (*_helmholtz_density_derivatives[i])[_qp];
    const ADReal electric_mu = (*_electric_enthalpy_density_derivatives[i])[_qp];
    (*_neutral_chemical_potentials[i])[_qp] = material_mu + electric_mu;
    (*_electric_partial_density_rate_coefficients[i])[_qp] =
        _phase_fraction[_qp] * electric_mu;
    _intrinsic_density[_qp] += (*_partial_densities[i])[_qp];
    _material_pressure[_qp] += (*_partial_densities[i])[_qp] * material_mu;
    _dielectric_pressure_correction[_qp] +=
        (*_partial_densities[i])[_qp] * electric_mu;
  }

  if (MetaPhysicL::raw_value(_intrinsic_density[_qp]) <= 0.0)
    mooseError(name(), ": total intrinsic phase density must be positive.");

  _pressure[_qp] = _material_pressure[_qp] + _dielectric_pressure_correction[_qp];
  _bulk_phase_density[_qp] = _phase_fraction[_qp] * _intrinsic_density[_qp];
  _specific_helmholtz_free_energy[_qp] =
      _helmholtz_density[_qp] / _intrinsic_density[_qp];
  _entropy_density[_qp] = -_helmholtz_temperature_derivative[_qp];
  _specific_internal_energy[_qp] =
      (_helmholtz_density[_qp] -
       _temperature[_qp] * _helmholtz_temperature_derivative[_qp]) /
      _intrinsic_density[_qp];
  _electric_phase_fraction_rate_coefficient[_qp] = _electric_enthalpy[_qp];
  _electric_temperature_rate_coefficient[_qp] =
      _phase_fraction[_qp] * _electric_enthalpy_temperature_derivative[_qp];
}
