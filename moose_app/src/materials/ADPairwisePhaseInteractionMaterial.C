#include "ADPairwisePhaseInteractionMaterial.h"

#include "metaphysicl/raw_type.h"

#include <algorithm>
#include <cmath>
#include <limits>
#include <set>

registerMooseObject("MulticomponentReactiveFlowApp", ADPairwisePhaseInteractionMaterial);

InputParameters
ADPairwisePhaseInteractionMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "General pair-graph implementation of manuscript phase-interaction force, power, "
      "energy-conservation, and admissibility equations using SPD drag tensors.");
  params.addParam<std::vector<MaterialPropertyName>>(
      "phase_velocity_names", {}, "One spatial AD velocity property per phase.");
  params.addCoupledVar(
      "phase_velocity_components",
      "Optional phase-major active spatial velocity components, n_phases*dimension entries.");
  params.addRequiredParam<std::vector<MaterialPropertyName>>(
      "phase_temperature_names", "One positive absolute-temperature property per phase.");
  params.addRequiredParam<std::vector<unsigned int>>(
      "pair_first", "First phase index for every retained unordered interaction pair.");
  params.addRequiredParam<std::vector<unsigned int>>(
      "pair_second", "Second phase index for every retained unordered interaction pair.");
  params.addParam<std::vector<MaterialPropertyName>>(
      "pair_resistance_tensor_names", {}, "One symmetric positive-definite drag tensor per pair.");
  params.addParam<std::vector<MaterialPropertyName>>(
      "pair_resistance_component_names",
      {},
      "Optional pair-major row-major active tensor components, n_pairs*dimension^2 AD scalar "
      "properties. Choose this or pair_resistance_tensor_names.");
  params.addParam<bool>(
      "resistance_tensors_are_constant",
      false,
      "Cache symmetry/SPD validation after the first evaluation. Set true only when every "
      "resistance property is invariant in space, time, and nonlinear state.");
  params.addParam<std::vector<Real>>(
      "heating_fraction_to_first",
      {},
      "Optional fraction [0,1] of each pair's drag heating allocated to its first phase; "
      "the default is equal partition.");
  params.addRequiredParam<std::vector<MaterialPropertyName>>(
      "phase_force_names", "One output momentum-supply vector name per phase.");
  params.addRequiredParam<std::vector<MaterialPropertyName>>(
      "phase_mechanical_energy_supply_names",
      "One output mechanical internal-energy supply name per phase.");
  params.addParam<MaterialPropertyName>("momentum_cancellation_name",
                                        "pairwise_interaction_momentum_cancellation",
                                        "Sum of all phase interaction forces.");
  params.addParam<MaterialPropertyName>("energy_cancellation_name",
                                        "pairwise_interaction_energy_cancellation",
                                        "Sum of internal-energy supplies plus force powers.");
  params.addParam<MaterialPropertyName>("total_drag_dissipation_name",
                                        "pairwise_interaction_total_drag_dissipation",
                                        "Sum of pair relative-velocity drag powers.");
  params.addParam<MaterialPropertyName>("entropy_production_name",
                                        "pairwise_interaction_entropy_production",
                                        "Temperature-weighted mechanical heating.");
  params.addParam<MaterialPropertyName>("minimum_resistance_eigenvalue_name",
                                        "pairwise_interaction_minimum_resistance_eigenvalue",
                                        "Minimum drag-tensor eigenvalue over retained pairs.");
  return params;
}

ADPairwisePhaseInteractionMaterial::ADPairwisePhaseInteractionMaterial(
    const InputParameters & parameters)
  : Material(parameters),
    _dim(_mesh.dimension()),
    _n_phases(getParam<std::vector<MaterialPropertyName>>("phase_force_names").size()),
    _pair_first(getParam<std::vector<unsigned int>>("pair_first")),
    _pair_second(getParam<std::vector<unsigned int>>("pair_second")),
    _heating_fraction_to_first(getParam<std::vector<Real>>("heating_fraction_to_first")),
    _resistance_tensors_are_constant(getParam<bool>("resistance_tensors_are_constant")),
    _momentum_cancellation(declareADProperty<RealVectorValue>(
        getParam<MaterialPropertyName>("momentum_cancellation_name"))),
    _energy_cancellation(
        declareADProperty<Real>(getParam<MaterialPropertyName>("energy_cancellation_name"))),
    _total_drag_dissipation(
        declareADProperty<Real>(getParam<MaterialPropertyName>("total_drag_dissipation_name"))),
    _entropy_production(
        declareADProperty<Real>(getParam<MaterialPropertyName>("entropy_production_name"))),
    _minimum_resistance_eigenvalue(declareADProperty<Real>(
        getParam<MaterialPropertyName>("minimum_resistance_eigenvalue_name")))
{
  const auto velocity_names =
      getParam<std::vector<MaterialPropertyName>>("phase_velocity_names");
  const auto temperature_names =
      getParam<std::vector<MaterialPropertyName>>("phase_temperature_names");
  const auto resistance_names =
      getParam<std::vector<MaterialPropertyName>>("pair_resistance_tensor_names");
  const auto resistance_component_names =
      getParam<std::vector<MaterialPropertyName>>("pair_resistance_component_names");
  const auto force_names = getParam<std::vector<MaterialPropertyName>>("phase_force_names");
  const auto energy_names =
      getParam<std::vector<MaterialPropertyName>>("phase_mechanical_energy_supply_names");
  const auto n_pairs = _pair_first.size();

  if (_n_phases < 2)
    paramError("phase_force_names", "Supply at least two phases.");
  if (temperature_names.size() != _n_phases || energy_names.size() != _n_phases)
    paramError("phase_force_names",
               "Velocity, temperature, force-output, and energy-output lists must have one entry "
               "per phase.");
  const bool property_velocity_mode = !velocity_names.empty();
  const bool component_velocity_mode = isCoupled("phase_velocity_components");
  if (property_velocity_mode == component_velocity_mode)
    paramError("phase_velocity_names",
               "Choose exactly one of phase_velocity_names and phase_velocity_components.");
  if (property_velocity_mode && velocity_names.size() != _n_phases)
    paramError("phase_velocity_names", "Supply one velocity property per phase.");
  if (component_velocity_mode &&
      coupledComponents("phase_velocity_components") != _n_phases * _dim)
    paramError("phase_velocity_components",
               "Supply n_phases*mesh_dimension phase-major velocity components.");

  const bool tensor_resistance_mode = !resistance_names.empty();
  const bool component_resistance_mode = !resistance_component_names.empty();
  if (tensor_resistance_mode == component_resistance_mode)
    paramError("pair_resistance_tensor_names",
               "Choose exactly one tensor-property or scalar-component resistance mode.");
  if (_pair_second.size() != n_pairs || n_pairs == 0)
    paramError("pair_resistance_tensor_names",
               "Supply equally sized nonempty first-index and second-index lists.");
  if (tensor_resistance_mode && resistance_names.size() != n_pairs)
    paramError("pair_resistance_tensor_names", "Supply one resistance tensor per pair.");
  if (component_resistance_mode && resistance_component_names.size() != n_pairs * _dim * _dim)
    paramError("pair_resistance_component_names",
               "Supply n_pairs*mesh_dimension^2 pair-major row-major components.");
  if (_heating_fraction_to_first.empty())
    _heating_fraction_to_first.assign(n_pairs, 0.5);
  if (_heating_fraction_to_first.size() != n_pairs)
    paramError("heating_fraction_to_first", "Supply exactly one allocation fraction per pair.");

  std::set<std::pair<unsigned int, unsigned int>> unique_pairs;
  for (const auto p : make_range(n_pairs))
  {
    const auto i = _pair_first[p];
    const auto j = _pair_second[p];
    if (i >= _n_phases || j >= _n_phases || i == j)
      paramError("pair_first", "Each pair must contain two distinct valid phase indices.");
    if (!unique_pairs.emplace(std::min(i, j), std::max(i, j)).second)
      paramError("pair_first", "Each unordered phase pair may be supplied only once.");
    if (_heating_fraction_to_first[p] < 0.0 || _heating_fraction_to_first[p] > 1.0)
      paramError("heating_fraction_to_first", "Every heating fraction must lie in [0,1].");
    if (tensor_resistance_mode)
      _pair_resistances.push_back(&getADMaterialProperty<RankTwoTensor>(resistance_names[p]));
  }
  for (const auto & component_name : resistance_component_names)
    _pair_resistance_components.push_back(&getADMaterialProperty<Real>(component_name));
  _resistance_validated.assign(n_pairs, false);
  _cached_minimum_eigenvalues.assign(n_pairs, 0.0);
  for (const auto phase : make_range(_n_phases))
  {
    if (property_velocity_mode)
      _phase_velocities.push_back(
          &getADMaterialProperty<RealVectorValue>(velocity_names[phase]));
    _phase_temperatures.push_back(&getADMaterialProperty<Real>(temperature_names[phase]));
    _phase_forces.push_back(&declareADProperty<RealVectorValue>(force_names[phase]));
    _phase_energy_supplies.push_back(&declareADProperty<Real>(energy_names[phase]));
  }
  if (component_velocity_mode)
    for (const auto component : make_range(_n_phases * _dim))
      _phase_velocity_components.push_back(
          &adCoupledValue("phase_velocity_components", component));
}

ADRankTwoTensor
ADPairwisePhaseInteractionMaterial::pairResistance(const unsigned int pair) const
{
  if (!_pair_resistances.empty())
    return (*_pair_resistances[pair])[_qp];

  ADRankTwoTensor resistance;
  for (const auto i : make_range(_dim))
    for (const auto j : make_range(_dim))
      resistance(i, j) =
          (*_pair_resistance_components[pair * _dim * _dim + i * _dim + j])[_qp];
  return resistance;
}

Real
ADPairwisePhaseInteractionMaterial::validateResistanceAndMinimumEigenvalue(
    const RankTwoTensor & resistance) const
{
  constexpr Real symmetry_tolerance = 1e-12;
  Real scale = 0.0;
  for (const auto i : make_range(_dim))
    for (const auto j : make_range(_dim))
      scale = std::max(scale, std::abs(resistance(i, j)));
  if (scale == 0.0)
    scale = 1.0;
  for (const auto i : make_range(_dim))
    for (const auto j : make_range(i))
      if (std::abs(resistance(i, j) - resistance(j, i)) > symmetry_tolerance * scale)
        mooseError(name(), ": pair resistance tensor must be symmetric on the active space.");

  Real cholesky[3][3] = {};
  for (const auto i : make_range(_dim))
    for (const auto j : make_range(i + 1))
    {
      Real value = resistance(i, j);
      for (const auto k : make_range(j))
        value -= cholesky[i][k] * cholesky[j][k];
      if (i == j)
      {
        if (value <= 0.0)
          mooseError(name(), ": pair resistance tensor must be positive definite.");
        cholesky[i][j] = std::sqrt(value);
      }
      else
        cholesky[i][j] = value / cholesky[j][j];
    }

  if (_dim == 1)
    return resistance(0, 0);
  if (_dim == 2)
  {
    const Real difference = resistance(0, 0) - resistance(1, 1);
    return 0.5 * (resistance(0, 0) + resistance(1, 1) -
                  std::sqrt(difference * difference +
                            4.0 * resistance(0, 1) * resistance(0, 1)));
  }
  std::vector<Real> eigenvalues;
  resistance.symmetricEigenvalues(eigenvalues);
  return *std::min_element(eigenvalues.begin(), eigenvalues.end());
}

void
ADPairwisePhaseInteractionMaterial::computeQpProperties()
{
  _momentum_cancellation[_qp] = ADRealVectorValue();
  _energy_cancellation[_qp] = 0.0;
  _total_drag_dissipation[_qp] = 0.0;
  _entropy_production[_qp] = 0.0;
  Real minimum_eigenvalue = std::numeric_limits<Real>::max();
  for (const auto phase : make_range(_n_phases))
  {
    (*_phase_forces[phase])[_qp] = ADRealVectorValue();
    (*_phase_energy_supplies[phase])[_qp] = 0.0;
    if (MetaPhysicL::raw_value((*_phase_temperatures[phase])[_qp]) <= 0.0)
      mooseError(name(), ": every phase temperature must remain positive.");
  }

  for (const auto p : index_range(_pair_first))
  {
    const auto i = _pair_first[p];
    const auto j = _pair_second[p];
    const ADRankTwoTensor resistance = pairResistance(p);
    const RankTwoTensor raw_resistance = MetaPhysicL::raw_value(resistance);
    Real pair_minimum_eigenvalue;
    if (_resistance_tensors_are_constant && _resistance_validated[p])
      pair_minimum_eigenvalue = _cached_minimum_eigenvalues[p];
    else
    {
      pair_minimum_eigenvalue = validateResistanceAndMinimumEigenvalue(raw_resistance);
      if (_resistance_tensors_are_constant)
      {
        _cached_minimum_eigenvalues[p] = pair_minimum_eigenvalue;
        _resistance_validated[p] = true;
      }
    }
    minimum_eigenvalue = std::min(minimum_eigenvalue, pair_minimum_eigenvalue);

    ADRealVectorValue velocity_i;
    ADRealVectorValue velocity_j;
    if (!_phase_velocities.empty())
    {
      velocity_i = (*_phase_velocities[i])[_qp];
      velocity_j = (*_phase_velocities[j])[_qp];
    }
    else
      for (const auto component : make_range(_dim))
      {
        velocity_i(component) = (*_phase_velocity_components[i * _dim + component])[_qp];
        velocity_j(component) = (*_phase_velocity_components[j * _dim + component])[_qp];
      }
    const ADRealVectorValue relative_velocity = velocity_i - velocity_j;
    const ADRealVectorValue resistance_velocity = resistance * relative_velocity;
    const ADReal pair_dissipation = relative_velocity * resistance_velocity;
    (*_phase_forces[i])[_qp] -= resistance_velocity;
    (*_phase_forces[j])[_qp] += resistance_velocity;
    (*_phase_energy_supplies[i])[_qp] +=
        _heating_fraction_to_first[p] * pair_dissipation;
    (*_phase_energy_supplies[j])[_qp] +=
        (1.0 - _heating_fraction_to_first[p]) * pair_dissipation;
    _total_drag_dissipation[_qp] += pair_dissipation;
  }

  _minimum_resistance_eigenvalue[_qp] = minimum_eigenvalue;
  for (const auto phase : make_range(_n_phases))
  {
    ADRealVectorValue phase_velocity;
    if (!_phase_velocities.empty())
      phase_velocity = (*_phase_velocities[phase])[_qp];
    else
      for (const auto component : make_range(_dim))
        phase_velocity(component) =
            (*_phase_velocity_components[phase * _dim + component])[_qp];
    _momentum_cancellation[_qp] += (*_phase_forces[phase])[_qp];
    _energy_cancellation[_qp] += (*_phase_energy_supplies[phase])[_qp] +
                                    (*_phase_forces[phase])[_qp] * phase_velocity;
    _entropy_production[_qp] +=
        (*_phase_energy_supplies[phase])[_qp] / (*_phase_temperatures[phase])[_qp];
  }
}
