#include "ADInterfacialSurfaceEnergyMaterial.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADInterfacialSurfaceEnergyMaterial);

InputParameters
ADInterfacialSurfaceEnergyMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Assembles gamma_f, the complete skeleton-following rate of phi gamma, and capillary-history "
      "dissipation from an arbitrary AD interfacial Helmholtz potential gamma(S,h,theta_F).");
  params.addRequiredParam<std::vector<std::string>>(
      "phase_names", "Fluid phase names defining the common phase ordering.");
  params.addRequiredParam<std::vector<MaterialPropertyName>>(
      "phase_volume_fraction_names", "Current phase volume fractions phi_f.");
  params.addRequiredParam<std::vector<MaterialPropertyName>>(
      "phase_volume_fraction_rate_names", "Skeleton-following rates dot(phi_f).");
  params.addRequiredParam<MaterialPropertyName>(
      "surface_energy_name", "Interfacial Helmholtz density gamma per current pore volume.");
  params.addRequiredParam<std::vector<MaterialPropertyName>>(
      "saturation_derivative_names", "Held-fixed partial derivatives d gamma / d S_f.");
  params.addParam<std::vector<MaterialPropertyName>>(
      "history_derivative_names", {}, "Held-fixed partial derivatives d gamma / d h_k.");
  params.addParam<std::vector<MaterialPropertyName>>(
      "history_rate_names", {}, "Skeleton-following capillary-history rates dot(h_k).");
  params.addParam<MaterialPropertyName>(
      "temperature_derivative_name", "", "Optional held-fixed derivative d gamma / d theta_F.");
  params.addParam<MaterialPropertyName>(
      "fluid_temperature_rate_name", "", "Rate dot(theta_F), paired with temperature derivative.");
  params.addParam<MaterialPropertyName>(
      "fluid_temperature_name",
      "",
      "Optional positive absolute fluid temperature used to report history entropy production.");
  params.addParam<std::string>(
      "property_prefix", "interfacial_surface", "Prefix for declared material properties.");
  return params;
}

ADInterfacialSurfaceEnergyMaterial::ADInterfacialSurfaceEnergyMaterial(
    const InputParameters & parameters)
  : Material(parameters),
    _phase_names(getParam<std::vector<std::string>>("phase_names")),
    _property_prefix(getParam<std::string>("property_prefix")),
    _surface_energy(getADMaterialProperty<Real>("surface_energy_name")),
    _fluid_temperature(getParam<MaterialPropertyName>("fluid_temperature_name").empty()
                           ? nullptr
                           : &getADMaterialProperty<Real>("fluid_temperature_name")),
    _temperature_derivative(
        getParam<MaterialPropertyName>("temperature_derivative_name").empty()
            ? nullptr
            : &getADMaterialProperty<Real>("temperature_derivative_name")),
    _temperature_rate(getParam<MaterialPropertyName>("fluid_temperature_rate_name").empty()
                          ? nullptr
                          : &getADMaterialProperty<Real>("fluid_temperature_rate_name")),
    _fluid_volume_fraction(declareADProperty<Real>(prefixedName("fluid_volume_fraction"))),
    _stored_interfacial_energy_density(
        declareADProperty<Real>(prefixedName("stored_energy_density"))),
    _stored_interfacial_energy_rate(
        declareADProperty<Real>(prefixedName("stored_energy_rate"))),
    _history_storage_rate(declareADProperty<Real>(prefixedName("history_storage_rate"))),
    _temperature_storage_rate(
        declareADProperty<Real>(prefixedName("temperature_storage_rate"))),
    _history_dissipation_rate(
        declareADProperty<Real>(prefixedName("history_dissipation_rate"))),
    _history_entropy_production_rate(
        declareADProperty<Real>(prefixedName("history_entropy_production_rate"))),
    _temperature_rate_coefficient(nullptr)
{
  const auto fraction_names =
      getParam<std::vector<MaterialPropertyName>>("phase_volume_fraction_names");
  const auto fraction_rate_names =
      getParam<std::vector<MaterialPropertyName>>("phase_volume_fraction_rate_names");
  const auto saturation_derivative_names =
      getParam<std::vector<MaterialPropertyName>>("saturation_derivative_names");
  const auto history_derivative_names =
      getParam<std::vector<MaterialPropertyName>>("history_derivative_names");
  const auto history_rate_names =
      getParam<std::vector<MaterialPropertyName>>("history_rate_names");

  if (_phase_names.empty())
    paramError("phase_names", "Supply at least one fluid phase.");
  if (_property_prefix.empty())
    paramError("property_prefix", "The material-property prefix must be nonempty.");
  if (fraction_names.size() != _phase_names.size())
    paramError("phase_volume_fraction_names", "Supply one volume fraction per phase.");
  if (fraction_rate_names.size() != _phase_names.size())
    paramError("phase_volume_fraction_rate_names", "Supply one volume-fraction rate per phase.");
  if (saturation_derivative_names.size() != _phase_names.size())
    paramError("saturation_derivative_names", "Supply one saturation derivative per phase.");
  if (history_derivative_names.size() != history_rate_names.size())
    paramError("history_rate_names", "Supply one history rate per history derivative.");
  if (static_cast<bool>(_temperature_derivative) != static_cast<bool>(_temperature_rate))
    paramError("fluid_temperature_rate_name",
               "Supply both the temperature derivative and temperature rate, or neither.");

  for (const auto f : make_range(_phase_names.size()))
  {
    if (_phase_names[f].empty())
      paramError("phase_names", "Phase names must be nonempty.");
    _phase_volume_fractions.push_back(&getADMaterialProperty<Real>(fraction_names[f]));
    _phase_volume_fraction_rates.push_back(
        &getADMaterialProperty<Real>(fraction_rate_names[f]));
    _saturation_derivatives.push_back(
        &getADMaterialProperty<Real>(saturation_derivative_names[f]));
    _saturations.push_back(
        &declareADProperty<Real>(prefixedName(_phase_names[f] + "_saturation")));
    _phase_interfacial_potentials.push_back(
        &declareADProperty<Real>(prefixedName(_phase_names[f] + "_interfacial_potential")));
    _phase_storage_rate_contributions.push_back(&declareADProperty<Real>(
        prefixedName(_phase_names[f] + "_volume_fraction_storage_rate")));
  }

  for (const auto k : make_range(history_derivative_names.size()))
  {
    _history_derivatives.push_back(
        &getADMaterialProperty<Real>(history_derivative_names[k]));
    _history_rates.push_back(&getADMaterialProperty<Real>(history_rate_names[k]));
    _history_rate_coefficients.push_back(&declareADProperty<Real>(
        prefixedName("history_rate_coefficient_" + std::to_string(k))));
  }
  if (_temperature_derivative)
    _temperature_rate_coefficient =
        &declareADProperty<Real>(prefixedName("temperature_rate_coefficient"));
}

MaterialPropertyName
ADInterfacialSurfaceEnergyMaterial::prefixedName(const std::string & suffix) const
{
  return MaterialPropertyName(_property_prefix + "_" + suffix);
}

void
ADInterfacialSurfaceEnergyMaterial::computeQpProperties()
{
  ADReal fluid_fraction = 0.0;
  for (const auto * fraction : _phase_volume_fractions)
    fluid_fraction += (*fraction)[_qp];
  if (MetaPhysicL::raw_value(fluid_fraction) <= 0.0)
    mooseError(name(), ": the total fluid volume fraction must be positive.");

  _fluid_volume_fraction[_qp] = fluid_fraction;
  _stored_interfacial_energy_density[_qp] = fluid_fraction * _surface_energy[_qp];

  ADReal saturation_weighted_derivative = 0.0;
  for (const auto f : make_range(_phase_names.size()))
  {
    (*_saturations[f])[_qp] = (*_phase_volume_fractions[f])[_qp] / fluid_fraction;
    saturation_weighted_derivative +=
        (*_saturations[f])[_qp] * (*_saturation_derivatives[f])[_qp];
  }

  ADReal total_rate = 0.0;
  for (const auto f : make_range(_phase_names.size()))
  {
    (*_phase_interfacial_potentials[f])[_qp] =
        _surface_energy[_qp] + (*_saturation_derivatives[f])[_qp] -
        saturation_weighted_derivative;
    (*_phase_storage_rate_contributions[f])[_qp] =
        (*_phase_interfacial_potentials[f])[_qp] *
        (*_phase_volume_fraction_rates[f])[_qp];
    total_rate += (*_phase_storage_rate_contributions[f])[_qp];
  }

  _history_storage_rate[_qp] = 0.0;
  for (const auto k : make_range(_history_derivatives.size()))
  {
    (*_history_rate_coefficients[k])[_qp] =
        fluid_fraction * (*_history_derivatives[k])[_qp];
    _history_storage_rate[_qp] +=
        (*_history_rate_coefficients[k])[_qp] * (*_history_rates[k])[_qp];
  }
  total_rate += _history_storage_rate[_qp];

  _temperature_storage_rate[_qp] = 0.0;
  if (_temperature_derivative)
  {
    (*_temperature_rate_coefficient)[_qp] =
        fluid_fraction * (*_temperature_derivative)[_qp];
    _temperature_storage_rate[_qp] =
        (*_temperature_rate_coefficient)[_qp] * (*_temperature_rate)[_qp];
    total_rate += _temperature_storage_rate[_qp];
  }
  _stored_interfacial_energy_rate[_qp] = total_rate;

  _history_dissipation_rate[_qp] = -_history_storage_rate[_qp];
  if (_fluid_temperature)
  {
    if (MetaPhysicL::raw_value((*_fluid_temperature)[_qp]) <= 0.0)
      mooseError(name(), ": the fluid temperature must be positive.");
    _history_entropy_production_rate[_qp] =
        _history_dissipation_rate[_qp] / (*_fluid_temperature)[_qp];
  }
  else
    _history_entropy_production_rate[_qp] = 0.0;
}
