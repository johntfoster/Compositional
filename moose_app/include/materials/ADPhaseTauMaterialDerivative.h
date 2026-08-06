#pragma once

#include "Material.h"
#include "RankTwoTensor.h"

class PhaseRegistry;

/** Phase-following derivative of tau expressed on the solid reference mesh. */
class ADPhaseTauMaterialDerivative : public Material {
public:
  static InputParameters validParams();
  ADPhaseTauMaterialDerivative(const InputParameters &parameters);

protected:
  void computeQpProperties() override;

  const std::string _phase_name;
  const PhaseRegistry &_phase_registry;
  const MooseEnum _phase_kind;
  const unsigned int _dim;

  const ADVariableValue &_tau_dot;
  const ADVariableGradient &_grad_tau;
  const ADVariableValue *_tau_enrichment_dot;
  const ADVariableGradient *_grad_tau_enrichment;
  std::vector<const ADVariableValue *> _phase_velocity;
  std::vector<const ADVariableValue *> _solid_displacement_dot;

  const ADMaterialProperty<Real> &_J;
  const ADMaterialProperty<RankTwoTensor> *_F;
  const ADMaterialProperty<Real> *_bulk_density;
  const ADMaterialProperty<RealVectorValue> *_reference_relative_mass_flux;
  const ADMaterialProperty<Real> *_phase_active;
  const Real _active_tol;
  const bool _deactivate_on_nonpositive_mass;

  ADMaterialProperty<Real> &_tau_material_derivative;
  ADMaterialProperty<Real> &_tau_convective_term;
  ADMaterialProperty<Real> &_tau_velocity_square;
  ADMaterialProperty<Real> &_tau_transfer_offset;
};
