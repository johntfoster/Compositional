#include "ADBlackOilPhaseTransformationThermodynamicsMaterial.h"

#include "metaphysicl/raw_type.h"

registerMooseObject("MulticomponentReactiveFlowApp",
                    ADBlackOilPhaseTransformationThermodynamicsMaterial);

InputParameters
ADBlackOilPhaseTransformationThermodynamicsMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Builds explicit neutral/electrochemical potentials and the dissolved-to-free-gas "
      "affinity from the black-oil PVTO undersaturation coordinate.");
  params.addRequiredParam<MaterialPropertyName>(
      "undersaturation_gap_name", "Property R_s,attainable-R_s from the black-oil PVT model.");
  params.addRequiredParam<MaterialPropertyName>("oil_component_mass_fraction_name",
                                                "Oil-component mass fraction in the oil phase.");
  params.addRequiredParam<MaterialPropertyName>(
      "dissolved_gas_mass_fraction_name", "Gas-component mass fraction in the oil phase.");
  params.addRequiredParam<MaterialPropertyName>("oil_intrinsic_density_name",
                                                "Current intrinsic oil-phase density.");
  params.addRequiredParam<MaterialPropertyName>("gas_intrinsic_density_name",
                                                "Current intrinsic free-gas density.");
  params.addRequiredParam<MaterialPropertyName>("oil_bulk_density_name",
                                                "Current bulk oil-phase density.");
  params.addRequiredParam<MaterialPropertyName>("gas_bulk_density_name",
                                                "Current bulk free-gas density.");
  params.addRequiredParam<MaterialPropertyName>("oil_pressure_name", "Current oil pressure.");
  params.addRequiredParam<MaterialPropertyName>("gas_pressure_name", "Current gas pressure.");
  params.addRequiredRangeCheckedParam<Real>(
      "solution_gas_oil_ratio_scale", "solution_gas_oil_ratio_scale>0", "Positive R_s scale.");
  params.addRequiredRangeCheckedParam<Real>(
      "chemical_stiffness",
      "chemical_stiffness>0",
      "Convex free-energy stiffness K in specific-energy units (J/kg when the component "
      "potentials use SI specific energy).");
  params.addRequiredRangeCheckedParam<Real>(
      "oil_surface_density", "oil_surface_density>0", "Stock-tank oil density.");
  params.addRequiredRangeCheckedParam<Real>(
      "gas_surface_density", "gas_surface_density>0", "Stock-tank gas density.");
  params.addParam<Real>("oil_reference_specific_helmholtz",
                        0.0,
                        "Oil-phase specific-Helmholtz datum added to the transformation penalty.");
  params.addParam<Real>(
      "synthetic_gas_specific_helmholtz_offset",
      0.0,
      "Constant offset in the synthetic isothermal SPE gas Helmholtz calibration.");
  params.addCoupledVar("electric_potential", "Optional electrostatic potential varphi.");
  params.addParam<Real>("dissolved_specific_charge", 0.0, "Dissolved-gas specific charge.");
  params.addParam<Real>("free_specific_charge", 0.0, "Free-gas specific charge.");
  params.addParam<std::string>(
      "property_prefix", "black_oil_phase_transform", "Output-property prefix.");
  return params;
}

ADBlackOilPhaseTransformationThermodynamicsMaterial::
    ADBlackOilPhaseTransformationThermodynamicsMaterial(const InputParameters & parameters)
  : Material(parameters),
    _undersaturation_gap(
        getADMaterialProperty<Real>(getParam<MaterialPropertyName>("undersaturation_gap_name"))),
    _oil_component_mass_fraction(getADMaterialProperty<Real>(
        getParam<MaterialPropertyName>("oil_component_mass_fraction_name"))),
    _dissolved_gas_mass_fraction(getADMaterialProperty<Real>(
        getParam<MaterialPropertyName>("dissolved_gas_mass_fraction_name"))),
    _oil_intrinsic_density(getADMaterialProperty<Real>(
        getParam<MaterialPropertyName>("oil_intrinsic_density_name"))),
    _gas_intrinsic_density(getADMaterialProperty<Real>(
        getParam<MaterialPropertyName>("gas_intrinsic_density_name"))),
    _oil_bulk_density(
        getADMaterialProperty<Real>(getParam<MaterialPropertyName>("oil_bulk_density_name"))),
    _gas_bulk_density(
        getADMaterialProperty<Real>(getParam<MaterialPropertyName>("gas_bulk_density_name"))),
    _oil_pressure(
        getADMaterialProperty<Real>(getParam<MaterialPropertyName>("oil_pressure_name"))),
    _gas_pressure(
        getADMaterialProperty<Real>(getParam<MaterialPropertyName>("gas_pressure_name"))),
    _ratio_scale(getParam<Real>("solution_gas_oil_ratio_scale")),
    _chemical_stiffness(getParam<Real>("chemical_stiffness")),
    _oil_surface_density(getParam<Real>("oil_surface_density")),
    _gas_surface_density(getParam<Real>("gas_surface_density")),
    _oil_reference_helmholtz(getParam<Real>("oil_reference_specific_helmholtz")),
    _gas_helmholtz_offset(getParam<Real>("synthetic_gas_specific_helmholtz_offset")),
    _dissolved_specific_charge(getParam<Real>("dissolved_specific_charge")),
    _free_specific_charge(getParam<Real>("free_specific_charge")),
    _electric_potential(isCoupled("electric_potential") ? &adCoupledValue("electric_potential")
                                                        : nullptr),
    _normalized_gap(declareADProperty<Real>(
        getParam<std::string>("property_prefix") + "_normalized_undersaturation")),
    _attainable_dissolved_gas_mass_fraction(declareADProperty<Real>(
        getParam<std::string>("property_prefix") + "_attainable_dissolved_gas_mass_fraction")),
    _dissolved_gas_mass_fraction_gap(declareADProperty<Real>(
        getParam<std::string>("property_prefix") + "_dissolved_gas_mass_fraction_gap")),
    _mass_fraction_rs_derivative(declareADProperty<Real>(
        getParam<std::string>("property_prefix") + "_dissolved_gas_mass_fraction_rs_derivative")),
    _free_energy(declareADProperty<Real>(
        getParam<std::string>("property_prefix") + "_specific_free_energy")),
    _oil_phase_specific_helmholtz(declareADProperty<Real>(
        getParam<std::string>("property_prefix") + "_oil_phase_specific_helmholtz")),
    _gas_phase_specific_helmholtz(declareADProperty<Real>(
        getParam<std::string>("property_prefix") + "_gas_phase_specific_helmholtz")),
    _oil_helmholtz_gas_mass_fraction_derivative(declareADProperty<Real>(
        getParam<std::string>("property_prefix") +
        "_oil_helmholtz_gas_mass_fraction_derivative")),
    _oil_component_specific_storage_work(declareADProperty<Real>(
        getParam<std::string>("property_prefix") + "_oil_component_specific_storage_work")),
    _dissolved_gas_specific_storage_work(declareADProperty<Real>(
        getParam<std::string>("property_prefix") + "_dissolved_gas_specific_storage_work")),
    _free_gas_specific_storage_work(declareADProperty<Real>(
        getParam<std::string>("property_prefix") + "_free_gas_specific_storage_work")),
    _oil_component_neutral_mu(declareADProperty<Real>(
        getParam<std::string>("property_prefix") + "_oil_component_neutral_mu")),
    _dissolved_neutral_mu(declareADProperty<Real>(
        getParam<std::string>("property_prefix") + "_dissolved_gas_neutral_mu")),
    _free_neutral_mu(declareADProperty<Real>(
        getParam<std::string>("property_prefix") + "_free_gas_neutral_mu")),
    _dissolved_electrochemical_mu(declareADProperty<Real>(
        getParam<std::string>("property_prefix") + "_dissolved_gas_electrochemical_mu")),
    _free_electrochemical_mu(declareADProperty<Real>(
        getParam<std::string>("property_prefix") + "_free_gas_electrochemical_mu")),
    _chemical_affinity(declareADProperty<Real>(
        getParam<std::string>("property_prefix") + "_dissolved_to_free_affinity")),
    _mass_fraction_normalization_residual(declareADProperty<Real>(
        getParam<std::string>("property_prefix") + "_mass_fraction_normalization_residual")),
    _oil_pressure_storage_residual(declareADProperty<Real>(
        getParam<std::string>("property_prefix") + "_oil_pressure_storage_residual")),
    _oil_composition_projection_residual(declareADProperty<Real>(
        getParam<std::string>("property_prefix") + "_oil_composition_projection_residual")),
    _oil_gas_euler_residual(declareADProperty<Real>(
        getParam<std::string>("property_prefix") + "_oil_gas_euler_residual")),
    _gas_pressure_storage_residual(declareADProperty<Real>(
        getParam<std::string>("property_prefix") + "_gas_pressure_storage_residual")),
    _gas_euler_residual(declareADProperty<Real>(
        getParam<std::string>("property_prefix") + "_gas_euler_residual"))
{
  if (getParam<std::string>("property_prefix").empty())
    paramError("property_prefix", "The output-property prefix must be nonempty.");
  if (!_electric_potential &&
      (_dissolved_specific_charge != 0.0 || _free_specific_charge != 0.0))
    paramError("electric_potential",
               "Couple electric_potential when either phase has nonzero specific charge.");
}

void
ADBlackOilPhaseTransformationThermodynamicsMaterial::computeQpProperties()
{
  const ADReal eta_o = _oil_component_mass_fraction[_qp];
  const ADReal eta_g = _dissolved_gas_mass_fraction[_qp];
  if (MetaPhysicL::raw_value(eta_o) <= 0.0 || MetaPhysicL::raw_value(eta_g) <= 0.0)
    mooseError(name(), ": the active oil phase requires positive oil and dissolved-gas mass "
                       "fractions for the Eq. (182) projection.");
  if (MetaPhysicL::raw_value(_oil_intrinsic_density[_qp]) <= 0.0 ||
      MetaPhysicL::raw_value(_gas_intrinsic_density[_qp]) <= 0.0 ||
      MetaPhysicL::raw_value(_oil_bulk_density[_qp]) <= 0.0)
    mooseError(name(), ": oil intrinsic, gas intrinsic, and active oil bulk densities must be "
                       "positive.");

  const ADReal current_rs = _oil_surface_density * eta_g / (_gas_surface_density * eta_o);
  const ADReal attainable_rs = current_rs + _undersaturation_gap[_qp];
  const ADReal attainable_surface_mass =
      _oil_surface_density + _gas_surface_density * attainable_rs;
  _normalized_gap[_qp] = _undersaturation_gap[_qp] / _ratio_scale;
  _attainable_dissolved_gas_mass_fraction[_qp] =
      _gas_surface_density * attainable_rs / attainable_surface_mass;
  _dissolved_gas_mass_fraction_gap[_qp] =
      _attainable_dissolved_gas_mass_fraction[_qp] - eta_g;
  const ADReal current_surface_mass =
      _oil_surface_density + _gas_surface_density * current_rs;
  _mass_fraction_rs_derivative[_qp] =
      _oil_surface_density * _gas_surface_density /
      (current_surface_mass * current_surface_mass);

  const ADReal psi_eta_g =
      -_chemical_stiffness * _dissolved_gas_mass_fraction_gap[_qp];
  _oil_helmholtz_gas_mass_fraction_derivative[_qp] = psi_eta_g;
  _free_energy[_qp] =
      0.5 * _chemical_stiffness * _dissolved_gas_mass_fraction_gap[_qp] *
      _dissolved_gas_mass_fraction_gap[_qp];
  _oil_phase_specific_helmholtz[_qp] =
      _oil_reference_helmholtz + _free_energy[_qp];

  const ADReal oil_pressure_work = _oil_pressure[_qp] / _oil_intrinsic_density[_qp];
  const ADReal gas_pressure_work = _gas_pressure[_qp] / _gas_intrinsic_density[_qp];
  _oil_component_specific_storage_work[_qp] = oil_pressure_work - eta_g * psi_eta_g;
  _dissolved_gas_specific_storage_work[_qp] = oil_pressure_work + eta_o * psi_eta_g;

  // SPE1 has no caloric EOS. This explicitly synthetic isothermal gas datum
  // aligns the pure-gas absolute potential with the oil pressure-work level
  // when the dissolved composition reaches its attainable target.
  _gas_phase_specific_helmholtz[_qp] =
      _oil_reference_helmholtz + _gas_helmholtz_offset + oil_pressure_work - gas_pressure_work;
  _free_gas_specific_storage_work[_qp] = gas_pressure_work;

  _oil_component_neutral_mu[_qp] =
      _oil_phase_specific_helmholtz[_qp] + _oil_component_specific_storage_work[_qp];
  _dissolved_neutral_mu[_qp] =
      _oil_phase_specific_helmholtz[_qp] + _dissolved_gas_specific_storage_work[_qp];
  _free_neutral_mu[_qp] =
      _gas_phase_specific_helmholtz[_qp] + _free_gas_specific_storage_work[_qp];

  const ADReal potential = _electric_potential ? (*_electric_potential)[_qp] : ADReal(0.0);
  _dissolved_electrochemical_mu[_qp] =
      _dissolved_neutral_mu[_qp] + _dissolved_specific_charge * potential;
  _free_electrochemical_mu[_qp] =
      _free_neutral_mu[_qp] + _free_specific_charge * potential;
  _chemical_affinity[_qp] =
      _dissolved_electrochemical_mu[_qp] - _free_electrochemical_mu[_qp];

  const ADReal oil_phase_fraction = _oil_bulk_density[_qp] / _oil_intrinsic_density[_qp];
  const ADReal gas_phase_fraction = _gas_bulk_density[_qp] / _gas_intrinsic_density[_qp];
  const ADReal oil_composition_coefficient = 0.0;
  const ADReal gas_composition_coefficient = _oil_bulk_density[_qp] * psi_eta_g;
  const ADReal composition_multiplier =
      -oil_phase_fraction * _oil_pressure[_qp] + eta_g * gas_composition_coefficient;
  const ADReal oil_pi_over_eta = oil_composition_coefficient - composition_multiplier;
  const ADReal gas_pi_over_eta = gas_composition_coefficient - composition_multiplier;
  const ADReal oil_pi = eta_o * oil_pi_over_eta;
  const ADReal dissolved_gas_pi = eta_g * gas_pi_over_eta;
  const ADReal free_gas_pi = gas_phase_fraction * _gas_pressure[_qp];

  _mass_fraction_normalization_residual[_qp] = eta_o + eta_g - 1.0;
  _oil_pressure_storage_residual[_qp] =
      oil_pi + dissolved_gas_pi - oil_phase_fraction * _oil_pressure[_qp];
  _oil_composition_projection_residual[_qp] =
      oil_composition_coefficient - gas_composition_coefficient - oil_pi_over_eta +
      gas_pi_over_eta;
  _oil_gas_euler_residual[_qp] =
      _dissolved_neutral_mu[_qp] - _oil_phase_specific_helmholtz[_qp] -
      gas_pi_over_eta / _oil_bulk_density[_qp];
  _gas_pressure_storage_residual[_qp] =
      free_gas_pi - gas_phase_fraction * _gas_pressure[_qp];
  _gas_euler_residual[_qp] =
      _free_neutral_mu[_qp] - _gas_phase_specific_helmholtz[_qp] - gas_pressure_work;
}
