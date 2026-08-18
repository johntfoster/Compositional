#pragma once

#include "Material.h"

#include <set>
#include <utility>

/**
 * Evaluates ECLIPSE-style PVTW, PVDG, and PVTO data for SPE black-oil benchmarks.
 */
class ADBlackOilBenchmarkPVTMaterial : public Material
{
public:
  static InputParameters validParams();

  ADBlackOilBenchmarkPVTMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;

  ADReal interpolate1D(const std::vector<Real> & coordinates,
                       const std::vector<Real> & values,
                       const ADReal & coordinate,
                       const std::string & table_name) const;
  ADReal interpolateOilBranchAtPressure(unsigned int branch,
                                        const std::vector<Real> & values,
                                        const ADReal & pressure) const;
  ADReal interpolateOilBranch(unsigned int branch, const std::vector<Real> & values) const;
  ADReal interpolateUndersaturatedOil(const std::vector<Real> & values) const;
  Real interpolate1DSlope(const std::vector<Real> & coordinates,
                          const std::vector<Real> & values,
                          const ADReal & coordinate,
                          const std::string & table_name) const;
  Real oilBranchPressureSlopeAtPressure(unsigned int branch,
                                        const std::vector<Real> & values,
                                        const ADReal & pressure) const;
  Real oilBranchPressureSlope(unsigned int branch, const std::vector<Real> & values) const;
  Real phaseActiveSmoothStep(Real saturation) const;
  std::pair<ADReal, ADReal> undersaturatedOilDerivatives(
      const std::vector<Real> & values) const;
  ADReal oilPressure() const;
  ADReal oilPressureDot() const;
  ADReal solutionGasOilRatio() const;
  ADReal solutionGasOilRatioDot() const;
  ADReal attainableSolutionGasOilRatio() const;
  ADReal attainableSolutionGasOilRatioDot() const;
  ADReal waterSaturation() const;
  ADReal waterSaturationDot() const;
  ADReal gasSaturation() const;
  ADReal gasSaturationDot() const;
  ADReal gasAppearanceComplementaritySaturation() const;
  ADReal reflectPositive(const ADReal & x) const;
  MaterialPropertyName prefixedName(const std::string & suffix) const;

  const ADMaterialProperty<Real> & _J;
  const ADMaterialProperty<Real> * _J_dot;
  const ADVariableValue * _oil_pressure;
  const ADMaterialProperty<Real> * _oil_pressure_property;
  const ADVariableValue * _oil_pressure_dot;
  const ADMaterialProperty<Real> * _oil_pressure_property_dot;
  const ADVariableValue & _solution_gas_oil_ratio_state;
  const ADVariableValue * _solution_gas_oil_ratio_state_dot;
  const Real _solution_gas_positive_regularization;
  // Band width delta of the soft-positive reflection a(x) applied to the
  // phase-appearance Fischer--Burmeister complementarity arguments before the
  // semismooth residual is evaluated: a(x) = x for x >= 0 and a(x) = -x +
  // (1 - k) * x * exp(x/delta) for x < 0, with slope k =
  // complementarity_positive_reflection_slope.  The reflection is an identity
  // on the admissible half-planes, so the admissible zero set Sg * gap = 0 is
  // unchanged, while negative Newton trials map to positive reflected
  // arguments and the exact FB residual stays well conditioned at the
  // phase-appearance point instead of losing its Sg derivative to the raw
  // sqrt floor.
  const Real _complementarity_positive_regularization;
  // Slope k of the soft-positive reflection at the origin (a'(0^-) = -k).
  const Real _complementary_positive_reflection_slope;
  // Strength lambda of the negative-saturation penalty term added to the
  // complementarity residual.  The soft-positive reflection of the gas
  // saturation argument alone makes the FB residual identically zero for every
  // Sg < 0 at a zero gap (a(Sg) - a(Sg) = 0), destroying the Sg >= 0 leg of
  // the complementarity.  The penalty p(x) = x - a(x) is zero for Sg >= 0,
  // strictly negative for Sg < 0, and has the nonzero derivative
  // lambda * (1 - a'(x)) ~ lambda * (1 + k) at the origin, so the P1 rate row
  // is strictly negative wherever Sg < 0 and keeps an exact coupling to the
  // gas block exactly at the phase-appearance point.
  const Real _complementarity_negative_saturation_penalty;
  const Moose::Functor<ADReal> & _solution_gas_oil_ratio_functor;
  const ADVariableValue * _porosity;
  const ADMaterialProperty<Real> * _porosity_property;
  const ADVariableValue * _porosity_dot;
  const ADMaterialProperty<Real> * _porosity_property_dot;
  const ADVariableValue * _water_saturation;
  const ADMaterialProperty<Real> * _water_saturation_property;
  const ADVariableValue * _water_saturation_dot;
  const ADMaterialProperty<Real> * _water_saturation_property_dot;
  const ADVariableValue * _gas_saturation;
  const ADMaterialProperty<Real> * _gas_saturation_property;
  const ADVariableValue * _gas_saturation_dot;
  const ADMaterialProperty<Real> * _gas_saturation_property_dot;
  // Optional phase-transfer rate variable r.  The direct equilibrium closure
  // consumes r on its inactive branch (no phase transformation, r -> 0), while
  // the active branch enforces the smooth DRSDT-capped stability gap to zero.
  // Null when the material runs without a phase-transfer rate unknown.
  const ADVariableValue * _gas_phase_transformation_rate;
  // Optional raw (unclamped) reconstructed gas saturation consumed only by the
  // phase-appearance complementarity residual.  The primary gas saturation may
  // be a bounded/simplex reconstruction whose clamp derivative vanishes when the
  // Newton trial goes slightly negative; the complementarity row then loses its
  // coupling to the gas block and the Jacobian becomes singular.  Supplying an
  // identity-transformed reconstruction here preserves an exact Sg derivative at
  // the phase-appearance point while storage/flux paths keep the clamped value.
  const ADMaterialProperty<Real> * _gas_appearance_complementarity_saturation;
  // Optional functor supplying the phase-appearance flag field (the gas
  // saturation backbone).  When set, the active-set branch selector is
  // evaluated at the previous fixed-point state
  // (Moose::previousFixedPointState()) so the active set is frozen inside the
  // inner Newton solve and refreshed only between Picard iterations of the
  // FixedPointSolve outer loop.  When null, the selector falls back to the
  // inline semismooth min-split at the current Newton iterate.
  const Moose::Functor<ADReal> * _active_set_flag_functor;
  // Optional elementwise enrichment of the flag field, summed with the
  // backbone at the previous fixed-point state to reconstruct the raw
  // (identity-transformed) total gas saturation used for the frozen flag.
  const Moose::Functor<ADReal> * _active_set_flag_enrichment_functor;
  // Optional oil-pressure functor evaluated at the previous fixed-point state
  // to reconstruct the saturated R_s and hence the true (uncapped) gap used by
  // the frozen active-set flag.  Without it the frozen flag could only see the
  // gas saturation, which is zero at the saturated initial state even where
  // the oil is oversaturated (R_s > R_s^sat), leaving those cells mislabelled
  // inactive on the first fixed-point iteration.
  const Moose::Functor<ADReal> * _active_set_flag_pressure_functor;
  // Optional subdomains on which the frozen active-set phase-appearance flag
  // is forced active from the first inner solve, regardless of the lagged
  // saturation or gap.  Use this for gas-injection well completion blocks: the
  // hard injected free-gas source immediately makes those cells active (free
  // gas present), and forcing the flag active lets the equilibrium closure
  // (A_(m) = 0 with r_(m) as the multiplier returned by the component balance)
  // absorb the injected gas instead of stalling the frozen inactive branch
  // (r = 0, no dissolution sink) at a nonzero gas-balance residual floor.
  const std::set<SubdomainID> _active_set_force_active_blocks;
  const bool _compute_storage_rates;
  const bool _use_pressure_dependent_rock_porosity;
  const Real _rock_reference_pressure;
  const Real _rock_compressibility;

  const Real _water_reference_pressure;
  const Real _water_reference_fvf;
  const Real _water_compressibility;
  const Real _water_reference_viscosity;
  const Real _water_viscosibility;

  const std::vector<Real> _gas_pressure_points;
  const std::vector<Real> _gas_fvf_values;
  const std::vector<Real> _gas_viscosity_values;
  std::vector<Real> _gas_inverse_fvf_values;
  std::vector<Real> _gas_inverse_fvf_viscosity_values;

  const std::vector<Real> _oil_rs_points;
  const std::vector<Real> _oil_bubble_pressure_points;
  const std::vector<unsigned int> _oil_branch_offsets;
  const std::vector<Real> _oil_pressure_points;
  const std::vector<Real> _oil_fvf_values;
  const std::vector<Real> _oil_viscosity_values;
  const std::vector<Real> _saturated_oil_fvf_values;
  const std::vector<Real> _saturated_oil_viscosity_values;
  std::vector<unsigned int> _interpolation_oil_branch_offsets;
  std::vector<Real> _interpolation_oil_pressure_points;
  std::vector<Real> _oil_inverse_fvf_values;
  std::vector<Real> _oil_inverse_fvf_viscosity_values;
  std::vector<Real> _saturated_oil_inverse_fvf_values;
  std::vector<Real> _saturated_oil_inverse_fvf_viscosity_values;

  const MooseEnum _out_of_range_policy;
  const Real _gas_active_tol;
  const Real _phase_active_band;
  const bool _equilibrate_solution_gas_with_free_gas;
  const bool _equilibrate_solution_gas_oil_ratio;
  const Real _solution_gas_oil_ratio_scale;
  const Real _maximum_solution_gas_oil_ratio;
  const Real _solution_gas_transition_width;
  const bool _enforce_nonincreasing_solution_gas;
  const bool _reject_oversaturated_state;
  const Real _water_surface_density;
  const Real _oil_surface_density;
  const Real _gas_surface_density;
  const std::string _property_prefix;

  ADMaterialProperty<Real> & _water_fvf;
  ADMaterialProperty<Real> & _oil_fvf;
  ADMaterialProperty<Real> & _gas_fvf;
  ADMaterialProperty<Real> & _water_viscosity;
  ADMaterialProperty<Real> & _oil_viscosity;
  ADMaterialProperty<Real> & _gas_viscosity;
  ADMaterialProperty<Real> & _solution_gas_oil_ratio;
  ADMaterialProperty<Real> & _saturated_solution_gas_oil_ratio;
  ADMaterialProperty<Real> & _undersaturation_gap;
  ADMaterialProperty<Real> & _gas_appearance_complementarity_residual;
  ADMaterialProperty<Real> & _solution_gas_constraint_residual;
  ADMaterialProperty<Real> & _gas_appearance_equilibrium_residual;
  ADMaterialProperty<Real> & _oil_saturation;
  ADMaterialProperty<Real> & _water_intrinsic_density;
  ADMaterialProperty<Real> & _oil_intrinsic_density;
  ADMaterialProperty<Real> & _gas_intrinsic_density;
  ADMaterialProperty<Real> & _water_component_mass_fraction_in_water;
  ADMaterialProperty<Real> & _oil_component_mass_fraction_in_oil;
  ADMaterialProperty<Real> & _gas_component_mass_fraction_in_oil;
  ADMaterialProperty<Real> & _gas_component_mass_fraction_in_gas;
  ADMaterialProperty<Real> & _water_reference_component_storage;
  ADMaterialProperty<Real> & _oil_reference_component_storage;
  ADMaterialProperty<Real> & _gas_reference_component_storage;
  ADMaterialProperty<Real> & _dissolved_gas_reference_component_storage;
  ADMaterialProperty<Real> & _free_gas_reference_component_storage;
  ADMaterialProperty<Real> & _water_reference_phase_mass_coefficient;
  ADMaterialProperty<Real> & _free_gas_reference_phase_mass_coefficient;
  ADMaterialProperty<Real> & _water_reference_phase_mass_coefficient_rate;
  ADMaterialProperty<Real> & _free_gas_reference_phase_mass_coefficient_rate;
  ADMaterialProperty<Real> & _water_reference_component_storage_rate;
  ADMaterialProperty<Real> & _oil_reference_component_storage_rate;
  ADMaterialProperty<Real> & _gas_reference_component_storage_rate;
  ADMaterialProperty<Real> & _dissolved_gas_reference_component_storage_rate;
  ADMaterialProperty<Real> & _free_gas_reference_component_storage_rate;
  ADMaterialProperty<Real> & _water_bulk_phase_density;
  ADMaterialProperty<Real> & _oil_bulk_phase_density;
  ADMaterialProperty<Real> & _gas_bulk_phase_density;
  ADMaterialProperty<Real> & _oil_phase_availability;
  ADMaterialProperty<Real> & _gas_phase_availability;
  ADMaterialProperty<Real> & _oil_active;
  ADMaterialProperty<Real> & _gas_active;
  // Pointwise mismatch between the frozen (lagged) active-set flag and the flag
  // reconstructed from the current iterate.  Zero everywhere when the active set
  // is converged; used by a FixedPointSolve custom_pp convergence check.
  ADMaterialProperty<Real> & _gas_active_set_mismatch;
};
