#include "ADHelmholtzEOSClosureMaterial.h"
#include "PhaseRegistry.h"

#include "metaphysicl/raw_type.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADHelmholtzEOSClosureMaterial);

InputParameters
ADHelmholtzEOSClosureMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Builds pressure, chemical potentials, entropy density, and phase densities from a "
      "user-supplied Helmholtz free-energy density differentiated by "
      "ADDerivativeParsedMaterial. Independent composition variables are current partial "
      "mass densities per unit current phase volume.");
  params.addRequiredParam<std::string>("phase", "Registered phase name used to prefix outputs.");
  params.addRequiredParam<UserObjectName>("phase_registry", "Input-deck phase registry.");
  params.addRequiredCoupledVar(
      "partial_densities",
      "Current constituent mass densities rho_a^alpha per unit current phase volume. "
      "These must also be the coupled variables of ADDerivativeParsedMaterial.");
  params.addRequiredCoupledVar(
      "temperature",
      "Temperature held fixed when differentiating the Helmholtz density with respect to "
      "the partial densities.");
  params.addRequiredCoupledVar("porosity", "Current phase volume fraction phi_a.");
  params.addRequiredParam<MaterialPropertyName>(
      "helmholtz_density_name",
      "Name of the user-supplied Helmholtz density A_a produced by "
      "ADDerivativeParsedMaterial with derivative_order at least two.");
  params.addParam<std::vector<MaterialPropertyName>>(
      "chemical_potential_names",
      {},
      "Optional output names for mu_a^alpha; defaults to "
      "<phase>_chemical_potential_<index>.");
  params.addParam<MaterialPropertyName>(
      "pressure_name", "", "Optional pressure output name; defaults to <phase>_pressure_from_eos.");
  params.addParam<MaterialPropertyName>(
      "intrinsic_density_name",
      "",
      "Optional intrinsic-density output name; defaults to <phase>_intrinsic_density.");
  params.addParam<MaterialPropertyName>(
      "bulk_phase_density_name",
      "",
      "Optional bulk-density output name; defaults to <phase>_bulk_phase_density.");
  params.addParam<MaterialPropertyName>(
      "specific_helmholtz_free_energy_name",
      "",
      "Optional specific Helmholtz-energy output name; defaults to "
      "<phase>_specific_helmholtz_free_energy.");
  params.addParam<MaterialPropertyName>(
      "entropy_density_name",
      "",
      "Optional entropy-density output name; defaults to <phase>_entropy_density.");
  return params;
}

ADHelmholtzEOSClosureMaterial::ADHelmholtzEOSClosureMaterial(
    const InputParameters & parameters)
  : DerivativeMaterialInterface<Material>(parameters),
    _phase_name(getParam<std::string>("phase")),
    _phase_registry(getUserObject<PhaseRegistry>("phase_registry")),
    _n_components(coupledComponents("partial_densities")),
    _helmholtz_density_name(getParam<MaterialPropertyName>("helmholtz_density_name")),
    _helmholtz_density(getADMaterialProperty<Real>(_helmholtz_density_name)),
    _temperature(adCoupledValue("temperature")),
    _temperature_name(coupledName("temperature")),
    _porosity(adCoupledValue("porosity")),
    _helmholtz_temperature_derivative(getADMaterialProperty<Real>(
        derivativePropertyNameFirst(_helmholtz_density_name, _temperature_name))),
    _pressure(declareADProperty<Real>(
        getParam<MaterialPropertyName>("pressure_name").empty()
            ? MaterialPropertyName(_phase_name + "_pressure_from_eos")
            : getParam<MaterialPropertyName>("pressure_name"))),
    _intrinsic_density(declareADProperty<Real>(
        getParam<MaterialPropertyName>("intrinsic_density_name").empty()
            ? MaterialPropertyName(_phase_name + "_intrinsic_density")
            : getParam<MaterialPropertyName>("intrinsic_density_name"))),
    _bulk_phase_density(declareADProperty<Real>(
        getParam<MaterialPropertyName>("bulk_phase_density_name").empty()
            ? MaterialPropertyName(_phase_name + "_bulk_phase_density")
            : getParam<MaterialPropertyName>("bulk_phase_density_name"))),
    _specific_helmholtz_free_energy(declareADProperty<Real>(
        getParam<MaterialPropertyName>("specific_helmholtz_free_energy_name").empty()
            ? MaterialPropertyName(_phase_name + "_specific_helmholtz_free_energy")
            : getParam<MaterialPropertyName>("specific_helmholtz_free_energy_name"))),
    _entropy_density(declareADProperty<Real>(
        getParam<MaterialPropertyName>("entropy_density_name").empty()
            ? MaterialPropertyName(_phase_name + "_entropy_density")
            : getParam<MaterialPropertyName>("entropy_density_name")))
{
  if (!_phase_registry.hasPhase(_phase_name))
    paramError("phase", "Phase '", _phase_name, "' is not registered.");
  if (_n_components == 0)
    paramError("partial_densities", "Supply at least one constituent partial density.");

  const auto potential_names =
      getParam<std::vector<MaterialPropertyName>>("chemical_potential_names");
  if (!potential_names.empty() && potential_names.size() != _n_components)
    paramError("chemical_potential_names",
               "The number of names must match the number of partial densities.");

  _partial_densities.reserve(_n_components);
  _partial_density_names.reserve(_n_components);
  _helmholtz_partial_density_derivatives.reserve(_n_components);
  _chemical_potentials.reserve(_n_components);
  for (const auto i : make_range(_n_components))
  {
    _partial_densities.push_back(&adCoupledValue("partial_densities", i));
    _partial_density_names.push_back(coupledName("partial_densities", i));
    _helmholtz_partial_density_derivatives.push_back(&getADMaterialProperty<Real>(
        derivativePropertyNameFirst(_helmholtz_density_name, _partial_density_names.back())));
    const MaterialPropertyName potential_name =
        potential_names.empty()
            ? MaterialPropertyName(_phase_name + "_chemical_potential_" + std::to_string(i))
            : potential_names[i];
    _chemical_potentials.push_back(&declareADProperty<Real>(potential_name));
  }
}

void
ADHelmholtzEOSClosureMaterial::computeQpProperties()
{
  _intrinsic_density[_qp] = 0.0;
  _pressure[_qp] = -_helmholtz_density[_qp];
  for (const auto i : make_range(_n_components))
  {
    const ADReal chemical_potential = (*_helmholtz_partial_density_derivatives[i])[_qp];
    (*_chemical_potentials[i])[_qp] = chemical_potential;
    _intrinsic_density[_qp] += (*_partial_densities[i])[_qp];
    _pressure[_qp] += (*_partial_densities[i])[_qp] * chemical_potential;
  }

  if (MetaPhysicL::raw_value(_intrinsic_density[_qp]) <= 0.0)
    mooseError("ADHelmholtzEOSClosureMaterial requires positive total intrinsic density for phase ",
               _phase_name,
               ".");

  _bulk_phase_density[_qp] = _porosity[_qp] * _intrinsic_density[_qp];
  _specific_helmholtz_free_energy[_qp] =
      _helmholtz_density[_qp] / _intrinsic_density[_qp];
  _entropy_density[_qp] = -_helmholtz_temperature_derivative[_qp];
}
