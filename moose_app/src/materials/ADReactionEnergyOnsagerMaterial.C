#include "ADReactionEnergyOnsagerMaterial.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADReactionEnergyOnsagerMaterial);

InputParameters
ADReactionEnergyOnsagerMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Applies a symmetric positive-semidefinite two-by-two Onsager matrix to the manuscript "
      "temperature-weighted reaction force and the inverse-temperature reaction-energy force. "
      "The physical energy-transfer rate is positive into the fluid subsystem and must be "
      "inserted with the opposite sign in the solid subsystem energy balance.");
  params.addRequiredParam<MaterialPropertyName>(
      "reaction_force_name", "Temperature-weighted neutral reaction-force property.");
  params.addRequiredParam<MaterialPropertyName>(
      "fluid_temperature_name", "Positive absolute fluid-subsystem temperature property.");
  params.addRequiredParam<MaterialPropertyName>(
      "solid_temperature_name", "Positive absolute solid-subsystem temperature property.");
  params.addRequiredCoupledVar("reaction_rate", "Mechanism reaction-rate variable.");
  params.addRequiredCoupledVar(
      "reaction_energy_transfer_rate",
      "Physical reaction-associated energy-transfer rate, positive into the fluid subsystem.");
  params.addRequiredParam<Real>(
      "reaction_mobility", "Onsager coefficient L_00 conjugate to the reaction force.");
  params.addRequiredParam<Real>(
      "cross_mobility", "Reciprocal Onsager coefficient L_01 = L_10.");
  params.addRequiredParam<Real>(
      "energy_mobility", "Onsager coefficient L_11 conjugate to 1/T_fluid - 1/T_solid.");
  params.addParam<Real>(
      "positive_semidefinite_tolerance",
      1e-12,
      "Absolute tolerance used when checking the two-by-two principal minors.");
  params.addParam<std::string>(
      "property_prefix", "reaction_energy_onsager", "Prefix for declared material properties.");
  return params;
}

ADReactionEnergyOnsagerMaterial::ADReactionEnergyOnsagerMaterial(
    const InputParameters & parameters)
  : Material(parameters),
    _reaction_force(getADMaterialProperty<Real>("reaction_force_name")),
    _fluid_temperature(getADMaterialProperty<Real>("fluid_temperature_name")),
    _solid_temperature(getADMaterialProperty<Real>("solid_temperature_name")),
    _reaction_rate(adCoupledValue("reaction_rate")),
    _reaction_energy_transfer_rate(adCoupledValue("reaction_energy_transfer_rate")),
    _L_00(getParam<Real>("reaction_mobility")),
    _L_01(getParam<Real>("cross_mobility")),
    _L_11(getParam<Real>("energy_mobility")),
    _determinant(_L_00 * _L_11 - _L_01 * _L_01),
    _property_prefix(getParam<std::string>("property_prefix")),
    _energy_force(declareADProperty<Real>(prefixedName("energy_force"))),
    _predicted_reaction_rate(declareADProperty<Real>(prefixedName("predicted_reaction_rate"))),
    _predicted_reaction_energy_transfer_rate(
        declareADProperty<Real>(prefixedName("predicted_reaction_energy_transfer_rate"))),
    _actual_reaction_energy_transfer_rate(
        declareADProperty<Real>(prefixedName("reaction_energy_transfer_rate"))),
    _reaction_rate_residual(declareADProperty<Real>(prefixedName("reaction_rate_residual"))),
    _reaction_energy_transfer_rate_residual(
        declareADProperty<Real>(prefixedName("reaction_energy_transfer_rate_residual"))),
    _reaction_entropy_production(
        declareADProperty<Real>(prefixedName("reaction_entropy_production"))),
    _reaction_energy_entropy_production(
        declareADProperty<Real>(prefixedName("reaction_energy_entropy_production"))),
    _total_entropy_production(
        declareADProperty<Real>(prefixedName("total_entropy_production"))),
    _onsager_quadratic_dissipation(
        declareADProperty<Real>(prefixedName("onsager_quadratic_dissipation"))),
    _onsager_determinant(declareADProperty<Real>(prefixedName("onsager_determinant")))
{
  const Real tolerance = getParam<Real>("positive_semidefinite_tolerance");
  if (tolerance < 0.0)
    paramError("positive_semidefinite_tolerance", "The tolerance must be nonnegative.");
  if (_property_prefix.empty())
    paramError("property_prefix", "The material-property prefix must be nonempty.");
  if (_L_00 < -tolerance)
    paramError("reaction_mobility", "Positive semidefiniteness requires L_00 >= 0.");
  if (_L_11 < -tolerance)
    paramError("energy_mobility", "Positive semidefiniteness requires L_11 >= 0.");
  if (_determinant < -tolerance)
    paramError("cross_mobility",
               "Positive semidefiniteness requires L_00 L_11 - L_01^2 >= 0.");
}

MaterialPropertyName
ADReactionEnergyOnsagerMaterial::prefixedName(const std::string & suffix) const
{
  return MaterialPropertyName(_property_prefix + "_" + suffix);
}

void
ADReactionEnergyOnsagerMaterial::computeQpProperties()
{
  if (MetaPhysicL::raw_value(_fluid_temperature[_qp]) <= 0.0 ||
      MetaPhysicL::raw_value(_solid_temperature[_qp]) <= 0.0)
    mooseError(name(), ": subsystem temperatures must be positive.");

  _energy_force[_qp] = 1.0 / _fluid_temperature[_qp] - 1.0 / _solid_temperature[_qp];
  _predicted_reaction_rate[_qp] =
      _L_00 * _reaction_force[_qp] + _L_01 * _energy_force[_qp];
  _predicted_reaction_energy_transfer_rate[_qp] =
      _L_01 * _reaction_force[_qp] + _L_11 * _energy_force[_qp];

  _reaction_rate_residual[_qp] =
      _reaction_rate[_qp] - _predicted_reaction_rate[_qp];
  _reaction_energy_transfer_rate_residual[_qp] =
      _reaction_energy_transfer_rate[_qp] - _predicted_reaction_energy_transfer_rate[_qp];
  _actual_reaction_energy_transfer_rate[_qp] = _reaction_energy_transfer_rate[_qp];

  _reaction_entropy_production[_qp] = _reaction_force[_qp] * _reaction_rate[_qp];
  _reaction_energy_entropy_production[_qp] =
      _energy_force[_qp] * _reaction_energy_transfer_rate[_qp];
  _total_entropy_production[_qp] =
      _reaction_entropy_production[_qp] + _reaction_energy_entropy_production[_qp];
  _onsager_quadratic_dissipation[_qp] =
      _reaction_force[_qp] * _predicted_reaction_rate[_qp] +
      _energy_force[_qp] * _predicted_reaction_energy_transfer_rate[_qp];
  _onsager_determinant[_qp] = _determinant;
}

