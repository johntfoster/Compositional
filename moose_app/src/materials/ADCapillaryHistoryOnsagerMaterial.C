#include "ADCapillaryHistoryOnsagerMaterial.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADCapillaryHistoryOnsagerMaterial);

InputParameters
ADCapillaryHistoryOnsagerMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Closes each skeleton-carried capillary-history coordinate by dot(h_k)=-M_k gamma_hk with "
      "M_k>=0 and reports -phi gamma_h dot(h)/theta_F.");
  params.addRequiredCoupledVar(
      "history_variables", "Continuous skeleton-carried capillary-history variables h_k.");
  params.addRequiredParam<std::vector<MaterialPropertyName>>(
      "history_derivative_names", "Interfacial Helmholtz derivatives d gamma / d h_k.");
  params.addRequiredParam<std::vector<Real>>(
      "history_mobilities", "Nonnegative diagonal Onsager mobilities M_k.");
  params.addRequiredParam<MaterialPropertyName>(
      "porosity_name", "Positive total fluid volume-fraction property phi.");
  params.addRequiredParam<MaterialPropertyName>(
      "fluid_temperature_name", "Positive absolute fluid-subsystem temperature.");
  params.addParam<std::string>(
      "property_prefix", "capillary_history", "Prefix for declared material properties.");
  return params;
}

ADCapillaryHistoryOnsagerMaterial::ADCapillaryHistoryOnsagerMaterial(
    const InputParameters & parameters)
  : Material(parameters),
    _mobilities(getParam<std::vector<Real>>("history_mobilities")),
    _porosity(getADMaterialProperty<Real>("porosity_name")),
    _fluid_temperature(getADMaterialProperty<Real>("fluid_temperature_name")),
    _property_prefix(getParam<std::string>("property_prefix")),
    _history_dissipation_rate(
        declareADProperty<Real>(prefixedName("dissipation_rate"))),
    _predicted_history_dissipation_rate(
        declareADProperty<Real>(prefixedName("predicted_dissipation_rate"))),
    _history_entropy_production_rate(
        declareADProperty<Real>(prefixedName("entropy_production_rate")))
{
  const auto derivative_names =
      getParam<std::vector<MaterialPropertyName>>("history_derivative_names");
  const auto history_count = coupledComponents("history_variables");
  if (history_count == 0)
    paramError("history_variables", "Supply at least one capillary-history variable.");
  if (derivative_names.size() != history_count)
    paramError("history_derivative_names", "Supply one derivative per history variable.");
  if (_mobilities.size() != history_count)
    paramError("history_mobilities", "Supply one mobility per history variable.");
  if (_property_prefix.empty())
    paramError("property_prefix", "The material-property prefix must be nonempty.");

  for (const auto k : make_range(history_count))
  {
    if (_mobilities[k] < 0.0)
      paramError("history_mobilities", "History mobilities must be nonnegative.");
    _history_rates.push_back(&adCoupledDot("history_variables", k));
    _history_derivatives.push_back(
        &getADMaterialProperty<Real>(derivative_names[k]));
    _predicted_history_rates.push_back(&declareADProperty<Real>(
        prefixedName("predicted_rate_" + std::to_string(k))));
    _history_rate_residuals.push_back(&declareADProperty<Real>(
        prefixedName("rate_residual_" + std::to_string(k))));
  }
}

MaterialPropertyName
ADCapillaryHistoryOnsagerMaterial::prefixedName(const std::string & suffix) const
{
  return MaterialPropertyName(_property_prefix + "_" + suffix);
}

void
ADCapillaryHistoryOnsagerMaterial::computeQpProperties()
{
  if (MetaPhysicL::raw_value(_porosity[_qp]) < 0.0)
    mooseError(name(), ": the total fluid volume fraction must be nonnegative.");
  if (MetaPhysicL::raw_value(_fluid_temperature[_qp]) <= 0.0)
    mooseError(name(), ": the fluid temperature must be positive.");

  _history_dissipation_rate[_qp] = 0.0;
  _predicted_history_dissipation_rate[_qp] = 0.0;
  for (const auto k : make_range(_history_rates.size()))
  {
    (*_predicted_history_rates[k])[_qp] =
        -_mobilities[k] * (*_history_derivatives[k])[_qp];
    (*_history_rate_residuals[k])[_qp] =
        (*_history_rates[k])[_qp] - (*_predicted_history_rates[k])[_qp];
    _history_dissipation_rate[_qp] -=
        _porosity[_qp] * (*_history_derivatives[k])[_qp] * (*_history_rates[k])[_qp];
    _predicted_history_dissipation_rate[_qp] +=
        _porosity[_qp] * _mobilities[k] * (*_history_derivatives[k])[_qp] *
        (*_history_derivatives[k])[_qp];
  }
  _history_entropy_production_rate[_qp] =
      _history_dissipation_rate[_qp] / _fluid_temperature[_qp];
}
