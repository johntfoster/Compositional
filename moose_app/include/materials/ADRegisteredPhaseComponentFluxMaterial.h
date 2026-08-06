#pragma once

#include "FunctionInterface.h"
#include "Material.h"
#include "RankTwoTensor.h"

class PhaseRegistry;

/** Assembles a component reference flux from any set of registered phase
 * fluxes. */
class ADRegisteredPhaseComponentFluxMaterial : public Material {
public:
  static InputParameters validParams();

  ADRegisteredPhaseComponentFluxMaterial(const InputParameters &parameters);

protected:
  void computeQpProperties() override;

  const PhaseRegistry &_phase_registry;
  const std::vector<std::string> _phases;
  const unsigned int _component;
  const bool _use_phase_active;

  const ADMaterialProperty<Real> &_J;
  const ADMaterialProperty<RankTwoTensor> &_J_F_inv;
  std::vector<const ADMaterialProperty<RealVectorValue> *>
      _phase_reference_relative_mass_fluxes;
  std::vector<const ADMaterialProperty<Real> *> _phase_component_mass_fractions;
  std::vector<const ADMaterialProperty<Real> *> _phase_active;

  const bool _use_current_component_extra_flux_function;
  const Function &_current_component_extra_flux;
  const ADMaterialProperty<RealVectorValue>
      *_current_component_extra_flux_material;
  const Function &_current_component_source;

  ADMaterialProperty<RealVectorValue> &_reference_component_flux;
  ADMaterialProperty<Real> &_reference_component_source;
};
