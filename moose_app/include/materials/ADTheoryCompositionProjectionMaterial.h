#pragma once

#include "DerivativeMaterialInterface.h"
#include "Material.h"

class PhaseRegistry;

/**
 * Implements the manuscript composition projections (current theory Eqs. 182--183).
 *
 * For each phase and component alpha, define the composition coefficient
 *   q_alpha = rho d(psi)/d(eta_alpha)
 *             + phi d(omega+)/d(eta_alpha)
 *             + sum_k c_{k,alpha},
 * where the optional c terms are the independently assembled solid stress-free-map
 * corrections in Eq. (183).  The material either recovers the storage multipliers
 * pi_alpha algebraically from the pressure sum or consumes them as coupled unknowns
 * and exposes the N-1 projection residuals plus the pressure-sum residual.
 */
class ADTheoryCompositionProjectionMaterial
  : public DerivativeMaterialInterface<Material>
{
public:
  static InputParameters validParams();

  ADTheoryCompositionProjectionMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;
  MaterialPropertyName outputName(const std::string & suffix) const;

  const PhaseRegistry & _phase_registry;
  const std::string _phase;
  const unsigned int _n_components;
  const bool _recover_storage_multipliers;
  const Real _minimum_active_bulk_density;
  const std::string _property_prefix;

  const ADVariableValue & _phase_fraction;
  const ADMaterialProperty<Real> & _intrinsic_density;
  const ADMaterialProperty<Real> & _phase_pressure;
  const MaterialPropertyName _specific_helmholtz_name;
  const ADMaterialProperty<Real> & _specific_helmholtz;

  std::vector<const ADVariableValue *> _mass_fractions;
  std::vector<VariableName> _mass_fraction_names;
  std::vector<const ADVariableValue *> _coupled_storage_multipliers;
  std::vector<const ADMaterialProperty<Real> *> _helmholtz_derivatives;
  std::vector<const ADMaterialProperty<Real> *> _electric_enthalpy_derivatives;
  std::vector<std::vector<const ADMaterialProperty<Real> *>> _correction_terms;

  ADMaterialProperty<Real> & _normalization_residual;
  ADMaterialProperty<Real> & _phase_pressure_storage_residual;
  ADMaterialProperty<Real> & _composition_multiplier;
  ADMaterialProperty<Real> & _bulk_phase_density;
  std::vector<ADMaterialProperty<Real> *> _composition_coefficients;
  std::vector<ADMaterialProperty<Real> *> _storage_multipliers;
  std::vector<ADMaterialProperty<Real> *> _storage_multipliers_over_mass_fraction;
  std::vector<ADMaterialProperty<Real> *> _specific_storage_works;
  std::vector<ADMaterialProperty<Real> *> _neutral_component_potentials;
  std::vector<ADMaterialProperty<Real> *> _projection_residuals;
};
