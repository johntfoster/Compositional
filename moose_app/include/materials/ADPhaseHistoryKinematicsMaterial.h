#pragma once

#include "Material.h"
#include "RankTwoTensor.h"

class PhaseRegistry;

class ADPhaseHistoryKinematicsMaterial : public Material
{
public:
  static InputParameters validParams();

  ADPhaseHistoryKinematicsMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;

  const std::string _phase_name;
  const PhaseRegistry & _phase_registry;
  const unsigned int _dim;
  const unsigned int _nF;

  std::vector<const ADVariableValue *> _F_components;
  const ADVariableValue & _J_history_var;
  std::vector<const ADVariableGradient *> _phase_velocity_gradients;
  std::vector<const ADVariableValue *> _reference_relative_mass_flux_components;
  const ADVariableValue & _phase_density;
  const ADVariableValue & _active_fraction;
  const Real _active_tol;

  const ADMaterialProperty<Real> & _solid_J;
  const ADMaterialProperty<RankTwoTensor> & _solid_F_inv;

  ADMaterialProperty<RankTwoTensor> & _phase_F;
  ADMaterialProperty<Real> & _phase_J_history;
  ADMaterialProperty<Real> & _phase_det_F;
  ADMaterialProperty<Real> & _phase_J_det_residual;
  ADMaterialProperty<RankTwoTensor> & _phase_velocity_gradient_current;
  ADMaterialProperty<RealVectorValue> & _phase_reference_convective_velocity;
};
