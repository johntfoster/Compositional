#include "ADPhaseConversionSourceMaterial.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADPhaseConversionSourceMaterial);

InputParameters
ADPhaseConversionSourceMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Computes q_f=sum_m nu_f(m) dot(r)_m directly from mechanism-rate variables. This "
      "dependency-minimal property feeds conversion-corrected phase momentum without creating "
      "a cycle through tau material derivatives; coefficients must use the same ordering and "
      "units as the reaction network.");
  params.addRequiredCoupledVar("reaction_rates", "Mechanism rates dot(r)_m.");
  params.addRequiredParam<std::vector<Real>>(
      "phase_stoichiometric_mass_coefficients", "Phase mass coefficient nu_f(m) for each rate.");
  params.addRequiredParam<MaterialPropertyName>(
      "phase_current_conversion_source_name", "Output current phase source q_f.");
  return params;
}

ADPhaseConversionSourceMaterial::ADPhaseConversionSourceMaterial(
    const InputParameters & parameters)
  : Material(parameters),
    _phase_stoichiometric_mass_coefficients(
        getParam<std::vector<Real>>("phase_stoichiometric_mass_coefficients")),
    _phase_current_conversion_source(declareADProperty<Real>(
        getParam<MaterialPropertyName>("phase_current_conversion_source_name")))
{
  const auto n_rates = coupledComponents("reaction_rates");
  if (n_rates == 0 || _phase_stoichiometric_mass_coefficients.size() != n_rates)
    paramError("phase_stoichiometric_mass_coefficients",
               "Supply exactly one phase mass coefficient for each reaction rate.");
  for (const auto m : make_range(n_rates))
    _reaction_rates.push_back(&adCoupledValue("reaction_rates", m));
}

void
ADPhaseConversionSourceMaterial::computeQpProperties()
{
  _phase_current_conversion_source[_qp] = 0.0;
  for (const auto m : index_range(_reaction_rates))
    _phase_current_conversion_source[_qp] +=
        _phase_stoichiometric_mass_coefficients[m] * (*_reaction_rates[m])[_qp];
}
