#include "PhaseRegistry.h"

#include <algorithm>
#include <cctype>
#include <set>

registerMooseObject("MulticomponentReactiveFlowApp", PhaseRegistry);

InputParameters
PhaseRegistry::validParams()
{
  InputParameters params = GeneralUserObject::validParams();
  params.addClassDescription(
      "Registers an arbitrary input-deck-defined set of phase names and identifies the phase "
      "whose reference map is used by the finite-element mesh.");
  params.addRequiredParam<std::vector<std::string>>(
      "phases", "Unique phase names. Names must be valid identifiers.");
  params.addRequiredParam<std::string>(
      "reference_phase", "Registered phase defining the reference configuration.");
  params.addParam<std::vector<std::string>>(
      "momentum_models",
      {},
      "Per-phase model in the same order as phases: reference, full, or relative_flux. "
      "Defaults to reference for the reference phase and relative_flux otherwise.");
  return params;
}

PhaseRegistry::PhaseRegistry(const InputParameters & parameters)
  : GeneralUserObject(parameters),
    _phases(getParam<std::vector<std::string>>("phases")),
    _reference_phase(getParam<std::string>("reference_phase")),
    _momentum_models(getParam<std::vector<std::string>>("momentum_models"))
{
  if (_phases.empty())
    paramError("phases", "Register at least one phase.");

  std::set<std::string> unique;
  for (const auto & phase : _phases)
  {
    if (phase.empty() || (!std::isalpha(static_cast<unsigned char>(phase[0])) && phase[0] != '_'))
      paramError("phases", "Phase names must begin with a letter or underscore: '", phase, "'.");
    for (const auto character : phase)
      if (!std::isalnum(static_cast<unsigned char>(character)) && character != '_')
        paramError("phases", "Phase names must contain only letters, digits, or underscores: '", phase, "'.");
    if (!unique.insert(phase).second)
      paramError("phases", "Duplicate phase name '", phase, "'.");
  }

  if (!hasPhase(_reference_phase))
    paramError("reference_phase",
               "Reference phase '",
               _reference_phase,
               "' is not present in the registered phase list.");

  if (_momentum_models.empty())
  {
    _momentum_models.resize(_phases.size(), "relative_flux");
    _momentum_models[phaseIndex(_reference_phase)] = "reference";
  }
  if (_momentum_models.size() != _phases.size())
    paramError("momentum_models", "Supply exactly one momentum model for each registered phase.");
  for (const auto i : make_range(_phases.size()))
  {
    const auto & model = _momentum_models[i];
    if (model != "reference" && model != "full" && model != "relative_flux")
      paramError("momentum_models", "Unknown momentum model '", model, "'.");
    if ((_phases[i] == _reference_phase) != (model == "reference"))
      paramError("momentum_models",
                 "Exactly the selected reference phase must use momentum model 'reference'.");
  }
}

bool
PhaseRegistry::hasPhase(const std::string & phase) const
{
  return std::find(_phases.begin(), _phases.end(), phase) != _phases.end();
}

bool
PhaseRegistry::isReferencePhase(const std::string & phase) const
{
  return phase == _reference_phase;
}

unsigned int
PhaseRegistry::phaseIndex(const std::string & phase) const
{
  const auto iterator = std::find(_phases.begin(), _phases.end(), phase);
  if (iterator == _phases.end())
    mooseError("Phase '", phase, "' is not registered in PhaseRegistry '", name(), "'.");
  return std::distance(_phases.begin(), iterator);
}

const std::string &
PhaseRegistry::momentumModel(const std::string & phase) const
{
  return _momentum_models[phaseIndex(phase)];
}

bool
PhaseRegistry::usesFullMomentum(const std::string & phase) const
{
  return momentumModel(phase) == "full";
}

bool
PhaseRegistry::usesRelativeFlux(const std::string & phase) const
{
  return momentumModel(phase) == "relative_flux";
}
