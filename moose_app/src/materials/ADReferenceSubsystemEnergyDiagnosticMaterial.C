#include "ADReferenceSubsystemEnergyDiagnosticMaterial.h"

registerMooseObject("MulticomponentReactiveFlowApp",
                    ADReferenceSubsystemEnergyDiagnosticMaterial);

InputParameters
ADReferenceSubsystemEnergyDiagnosticMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Independently composes the strong solid-reference subsystem energy residual "
      "J C dot(theta) + Div_X(Q) - J s - J w_ext + J sum L dot(c) from Eq. "
      "(MC_energy_balance).");
  params.addRequiredCoupledVar("temperature", "Subsystem temperature.");
  params.addRequiredParam<MaterialPropertyName>("storage_coefficient_name", "C.");
  params.addRequiredParam<MaterialPropertyName>("reference_flux_divergence_name", "Div_X(Q).");
  params.addParam<std::vector<MaterialPropertyName>>("current_source_names", {}, "Current-volume sources s.");
  params.addParam<std::vector<Real>>("source_scales", {}, "Signed source multipliers.");
  params.addParam<std::vector<MaterialPropertyName>>(
      "current_external_work_names", {}, "Current-volume external-work powers w_ext.");
  params.addParam<std::vector<Real>>(
      "external_work_scales", {}, "Signed external-work multipliers.");
  params.addParam<std::vector<MaterialPropertyName>>("generalized_transfer_work_names", {}, "L properties.");
  params.addParam<std::vector<MaterialPropertyName>>("current_component_source_names", {}, "Matching dot(c) properties.");
  params.addParam<MaterialPropertyName>("solid_jacobian_name", "solid_reference_J", "J.");
  params.addRequiredParam<std::string>("property_prefix", "Output prefix.");
  return params;
}

ADReferenceSubsystemEnergyDiagnosticMaterial::ADReferenceSubsystemEnergyDiagnosticMaterial(
    const InputParameters & p)
  : Material(p), _temperature_dot(adCoupledDot("temperature")),
    _J(getADMaterialProperty<Real>("solid_jacobian_name")),
    _storage_coefficient(getADMaterialProperty<Real>("storage_coefficient_name")),
    _flux_divergence(getADMaterialProperty<Real>("reference_flux_divergence_name")),
    _source_scales(getParam<std::vector<Real>>("source_scales")),
    _external_work_scales(getParam<std::vector<Real>>("external_work_scales")),
    _storage_rate(declareADProperty<Real>(getParam<std::string>("property_prefix") + "_storage_rate")),
    _flux_divergence_term(declareADProperty<Real>(getParam<std::string>("property_prefix") + "_flux_divergence")),
    _source_power(declareADProperty<Real>(getParam<std::string>("property_prefix") + "_source_power")),
    _external_work_power(declareADProperty<Real>(
        getParam<std::string>("property_prefix") + "_external_work_power")),
    _conversion_power(declareADProperty<Real>(getParam<std::string>("property_prefix") + "_conversion_power")),
    _local_residual(declareADProperty<Real>(getParam<std::string>("property_prefix") + "_local_residual"))
{
  const auto sources = getParam<std::vector<MaterialPropertyName>>("current_source_names");
  if (_source_scales.empty())
    _source_scales.assign(sources.size(), 1.0);
  if (_source_scales.size() != sources.size())
    paramError("source_scales", "Supply one scale per current source.");
  for (const auto & name : sources)
    _current_sources.push_back(&getADMaterialProperty<Real>(name));
  const auto external_works =
      getParam<std::vector<MaterialPropertyName>>("current_external_work_names");
  if (_external_work_scales.empty())
    _external_work_scales.assign(external_works.size(), 1.0);
  if (_external_work_scales.size() != external_works.size())
    paramError("external_work_scales", "Supply one scale per external-work property.");
  for (const auto & name : external_works)
    _current_external_works.push_back(&getADMaterialProperty<Real>(name));
  const auto works = getParam<std::vector<MaterialPropertyName>>("generalized_transfer_work_names");
  const auto rates = getParam<std::vector<MaterialPropertyName>>("current_component_source_names");
  if (works.size() != rates.size())
    paramError("generalized_transfer_work_names", "Supply one work per component source.");
  for (const auto & name : works)
    _transfer_works.push_back(&getADMaterialProperty<Real>(name));
  for (const auto & name : rates)
    _component_sources.push_back(&getADMaterialProperty<Real>(name));
}

void
ADReferenceSubsystemEnergyDiagnosticMaterial::computeQpProperties()
{
  _storage_rate[_qp] = _J[_qp] * _storage_coefficient[_qp] * _temperature_dot[_qp];
  _flux_divergence_term[_qp] = _flux_divergence[_qp];
  _source_power[_qp] = 0.0;
  for (const auto i : index_range(_current_sources))
    _source_power[_qp] += _J[_qp] * _source_scales[i] * (*_current_sources[i])[_qp];
  _external_work_power[_qp] = 0.0;
  for (const auto i : index_range(_current_external_works))
    _external_work_power[_qp] +=
        _J[_qp] * _external_work_scales[i] * (*_current_external_works[i])[_qp];
  _conversion_power[_qp] = 0.0;
  for (const auto i : index_range(_transfer_works))
    _conversion_power[_qp] += _J[_qp] * (*_transfer_works[i])[_qp] * (*_component_sources[i])[_qp];
  _local_residual[_qp] = _storage_rate[_qp] + _flux_divergence_term[_qp] -
                         _source_power[_qp] - _external_work_power[_qp] +
                         _conversion_power[_qp];
}
