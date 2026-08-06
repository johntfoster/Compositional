#pragma once

#include "GeneralUserObject.h"

/** Input-deck registry for an arbitrary number of named material phases. */
class PhaseRegistry : public GeneralUserObject
{
public:
  static InputParameters validParams();

  PhaseRegistry(const InputParameters & parameters);

  void initialize() override {}
  void execute() override {}
  void finalize() override {}

  bool hasPhase(const std::string & phase) const;
  bool isReferencePhase(const std::string & phase) const;
  unsigned int phaseIndex(const std::string & phase) const;
  unsigned int numPhases() const { return _phases.size(); }
  const std::vector<std::string> & phases() const { return _phases; }
  const std::string & referencePhase() const { return _reference_phase; }
  const std::string & momentumModel(const std::string & phase) const;
  bool usesFullMomentum(const std::string & phase) const;
  bool usesRelativeFlux(const std::string & phase) const;

private:
  const std::vector<std::string> _phases;
  const std::string _reference_phase;
  std::vector<std::string> _momentum_models;
};
