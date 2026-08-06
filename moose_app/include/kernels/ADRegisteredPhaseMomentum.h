#pragma once

#include "ADTimeKernel.h"
#include "RankTwoTensor.h"

class Function;
class PhaseRegistry;

/** One Cartesian component of a registered phase's full momentum balance on the solid mesh. */
class ADRegisteredPhaseMomentum : public ADTimeKernel
{
public:
  static InputParameters validParams();
  ADRegisteredPhaseMomentum(const InputParameters & parameters);

protected:
  ADReal computeQpResidual() override;

  const std::string _phase_name;
  const PhaseRegistry & _phase_registry;
  const unsigned int _component;
  const unsigned int _dim;
  std::vector<const ADVariableValue *> _phase_velocities;
  std::vector<const ADVariableValue *> _solid_velocities;
  std::vector<const ADVariableValue *> _additional_interaction_force;
  const ADVariableValue & _bulk_density;
  const ADVariableValue & _phase_fraction;
  const ADVariableGradient & _pressure_potential_gradient;
  const ADVariableGradient * _pressure_potential_enrichment_gradient;
  const bool _include_capillary_pressure;
  const ADVariableGradient * _capillary_pressure_gradient;
  const ADVariableGradient * _capillary_pressure_enrichment_gradient;
  const ADVariableValue & _net_conversion_rate;
  const Real _net_conversion_rate_scale;
  const ADVariableGradient & _transfer_potential_gradient;
  const ADVariableGradient * _transfer_potential_enrichment_gradient;
  const ADMaterialProperty<Real> & _solid_J;
  const ADMaterialProperty<RankTwoTensor> & _solid_F_inv;
  const ADMaterialProperty<RankTwoTensor> * _extra_cauchy_stress;
  const Real _viscosity;
  const Real _permeability;
  const RealVectorValue _gravity;
  const Function & _forcing;
};
