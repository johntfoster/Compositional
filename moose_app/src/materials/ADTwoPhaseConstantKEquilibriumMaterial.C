#include "ADTwoPhaseConstantKEquilibriumMaterial.h"

#include "metaphysicl/raw_type.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADTwoPhaseConstantKEquilibriumMaterial);

InputParameters
ADTwoPhaseConstantKEquilibriumMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Computes a restricted active two-phase, two-component constant-K equilibrium split. "
      "The material assumes positive phase amounts and positive compositions, enforces the "
      "overall mass-fraction and volume constraints, and leaves phase appearance/disappearance "
      "to a later complementarity or flash closure.");
  params.addParam<MaterialPropertyName>(
      "jacobian_name", "solid_reference_J", "Material property name for J.");
  params.addRequiredCoupledVar("total_porosity", "Total fluid volume fraction phi.");
  params.addRequiredCoupledVar("phase0_density", "Intrinsic density of phase 0.");
  params.addRequiredCoupledVar("phase1_density", "Intrinsic density of phase 1.");
  params.addRequiredCoupledVar("overall_mass_fractions",
                               "Overall two-component mass fractions z^alpha.");
  params.addRequiredParam<std::vector<Real>>(
      "k_values", "Two equilibrium ratios K^alpha = eta_1^alpha / eta_0^alpha.");
  params.addRangeCheckedParam<Real>(
      "sum_tol", 1e-10, "sum_tol>=0", "Tolerance for composition and volume constraints.");
  params.addRangeCheckedParam<Real>("interior_tol",
                                    1e-10,
                                    "interior_tol>=0",
                                    "Tolerance separating the active two-phase state from phase disappearance.");
  params.addParam<MaterialPropertyName>("phase1_mass_fraction_name",
                                        "phase1_mass_fraction",
                                        "Material property name for beta.");
  params.addParam<MaterialPropertyName>("phase0_saturation_name",
                                        "phase0_saturation",
                                        "Material property name for S_0.");
  params.addParam<MaterialPropertyName>("phase1_saturation_name",
                                        "phase1_saturation",
                                        "Material property name for S_1.");
  params.addParam<MaterialPropertyName>("phase0_volume_fraction_name",
                                        "phase0_volume_fraction",
                                        "Material property name for phi_0.");
  params.addParam<MaterialPropertyName>("phase1_volume_fraction_name",
                                        "phase1_volume_fraction",
                                        "Material property name for phi_1.");
  params.addParam<MaterialPropertyName>("volume_constraint_residual_name",
                                        "volume_constraint_residual",
                                        "Material property name for phi_0 + phi_1 - phi.");
  return params;
}

ADTwoPhaseConstantKEquilibriumMaterial::ADTwoPhaseConstantKEquilibriumMaterial(
    const InputParameters & parameters)
  : Material(parameters),
    _J(getADMaterialProperty<Real>("jacobian_name")),
    _total_porosity(adCoupledValue("total_porosity")),
    _phase0_density(adCoupledValue("phase0_density")),
    _phase1_density(adCoupledValue("phase1_density")),
    _k_values(getParam<std::vector<Real>>("k_values")),
    _sum_tol(getParam<Real>("sum_tol")),
    _interior_tol(getParam<Real>("interior_tol")),
    _phase1_mass_fraction(
        declareADProperty<Real>(getParam<MaterialPropertyName>("phase1_mass_fraction_name"))),
    _phase0_saturation(
        declareADProperty<Real>(getParam<MaterialPropertyName>("phase0_saturation_name"))),
    _phase1_saturation(
        declareADProperty<Real>(getParam<MaterialPropertyName>("phase1_saturation_name"))),
    _phase0_volume_fraction(
        declareADProperty<Real>(getParam<MaterialPropertyName>("phase0_volume_fraction_name"))),
    _phase1_volume_fraction(
        declareADProperty<Real>(getParam<MaterialPropertyName>("phase1_volume_fraction_name"))),
    _volume_constraint_residual(
        declareADProperty<Real>(getParam<MaterialPropertyName>("volume_constraint_residual_name"))),
    _overall_mass_fraction_sum(declareADProperty<Real>("overall_mass_fraction_sum")),
    _phase0_mass_fraction_sum(declareADProperty<Real>("phase0_mass_fraction_sum")),
    _phase1_mass_fraction_sum(declareADProperty<Real>("phase1_mass_fraction_sum"))
{
  if (coupledComponents("overall_mass_fractions") != 2)
    paramError("overall_mass_fractions", "This restricted closure requires exactly two components.");
  if (_k_values.size() != 2)
    paramError("k_values", "This restricted closure requires exactly two K-values.");

  for (const auto k : _k_values)
    if (k <= 0.0)
      paramError("k_values", "All K-values must be positive.");

  for (unsigned int i = 0; i < 2; ++i)
  {
    _overall_mass_fractions.push_back(&adCoupledValue("overall_mass_fractions", i));
    _phase0_mass_fractions.push_back(
        &declareADProperty<Real>("phase0_component_mass_fraction_" + std::to_string(i)));
    _phase1_mass_fractions.push_back(
        &declareADProperty<Real>("phase1_component_mass_fraction_" + std::to_string(i)));
    _equilibrium_residuals.push_back(
        &declareADProperty<Real>("constant_k_equilibrium_residual_" + std::to_string(i)));
    _overall_composition_residuals.push_back(
        &declareADProperty<Real>("overall_composition_residual_" + std::to_string(i)));
    _total_reference_component_storages.push_back(
        &declareADProperty<Real>("total_reference_component_storage_" + std::to_string(i)));
  }
}

void
ADTwoPhaseConstantKEquilibriumMaterial::computeQpProperties()
{
  const ADReal z0 = (*_overall_mass_fractions[0])[_qp];
  const ADReal z1 = (*_overall_mass_fractions[1])[_qp];
  _overall_mass_fraction_sum[_qp] = z0 + z1;

  if (std::abs(MetaPhysicL::raw_value(_overall_mass_fraction_sum[_qp] - 1.0)) > _sum_tol)
    mooseError("ADTwoPhaseConstantKEquilibriumMaterial requires overall mass fractions to sum "
               "to one. Got ",
               MetaPhysicL::raw_value(_overall_mass_fraction_sum[_qp]),
               " at quadrature point ",
               _qp,
               ".");
  if (MetaPhysicL::raw_value(z0) <= _interior_tol ||
      MetaPhysicL::raw_value(z1) <= _interior_tol)
    mooseError("The restricted constant-K split requires positive overall component mass "
               "fractions.");

  const ADReal a0 = _k_values[0] - 1.0;
  const ADReal a1 = _k_values[1] - 1.0;
  const ADReal denominator = a0 * a1;

  if (std::abs(MetaPhysicL::raw_value(denominator)) <= _sum_tol)
    mooseError("The restricted two-component split requires nontrivial K-values on both "
               "components.");

  const ADReal beta_unbounded = -(z0 * a0 + z1 * a1) / denominator;
  const auto beta_unbounded_value = MetaPhysicL::raw_value(beta_unbounded);

  ADReal beta = beta_unbounded;
  ADReal x0 = z0 / (1.0 + beta * a0);
  ADReal x1 = z1 / (1.0 + beta * a1);
  ADReal y0 = _k_values[0] * x0;
  ADReal y1 = _k_values[1] * x1;

  if (beta_unbounded_value <= _interior_tol)
  {
    beta = 0.0;
    x0 = z0;
    x1 = z1;
    y0 = _k_values[0] * x0;
    y1 = _k_values[1] * x1;
  }
  else if (beta_unbounded_value >= 1.0 - _interior_tol)
  {
    beta = 1.0;
    y0 = z0;
    y1 = z1;
    x0 = y0 / _k_values[0];
    x1 = y1 / _k_values[1];
  }

  _phase1_mass_fraction[_qp] = beta;

  if (MetaPhysicL::raw_value(x0) <= _interior_tol ||
      MetaPhysicL::raw_value(x1) <= _interior_tol ||
      MetaPhysicL::raw_value(y0) <= _interior_tol ||
      MetaPhysicL::raw_value(y1) <= _interior_tol)
    mooseError("The restricted constant-K split requires positive phase compositions.");

  (*_phase0_mass_fractions[0])[_qp] = x0;
  (*_phase0_mass_fractions[1])[_qp] = x1;
  (*_phase1_mass_fractions[0])[_qp] = y0;
  (*_phase1_mass_fractions[1])[_qp] = y1;

  _phase0_mass_fraction_sum[_qp] = x0 + x1;
  _phase1_mass_fraction_sum[_qp] = y0 + y1;

  if (beta_unbounded_value <= _interior_tol)
  {
    _phase0_saturation[_qp] = 1.0;
    _phase1_saturation[_qp] = 0.0;
  }
  else if (beta_unbounded_value >= 1.0 - _interior_tol)
  {
    _phase0_saturation[_qp] = 0.0;
    _phase1_saturation[_qp] = 1.0;
  }
  else
  {
    const ADReal phase0_specific_volume = (1.0 - beta) / _phase0_density[_qp];
    const ADReal phase1_specific_volume = beta / _phase1_density[_qp];
    const ADReal total_specific_volume = phase0_specific_volume + phase1_specific_volume;

    _phase0_saturation[_qp] = phase0_specific_volume / total_specific_volume;
    _phase1_saturation[_qp] = phase1_specific_volume / total_specific_volume;
  }
  _phase0_volume_fraction[_qp] = _total_porosity[_qp] * _phase0_saturation[_qp];
  _phase1_volume_fraction[_qp] = _total_porosity[_qp] * _phase1_saturation[_qp];
  _volume_constraint_residual[_qp] =
      _phase0_volume_fraction[_qp] + _phase1_volume_fraction[_qp] - _total_porosity[_qp];

  for (unsigned int i = 0; i < 2; ++i)
  {
    const ADReal x = (*_phase0_mass_fractions[i])[_qp];
    const ADReal y = (*_phase1_mass_fractions[i])[_qp];
    const ADReal z = (*_overall_mass_fractions[i])[_qp];

    (*_equilibrium_residuals[i])[_qp] = y - _k_values[i] * x;
    (*_overall_composition_residuals[i])[_qp] = (1.0 - beta) * x + beta * y - z;
    (*_total_reference_component_storages[i])[_qp] =
        _J[_qp] * (_phase0_volume_fraction[_qp] * _phase0_density[_qp] * x +
                   _phase1_volume_fraction[_qp] * _phase1_density[_qp] * y);
  }
}
