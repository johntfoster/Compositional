#pragma once

#include "Material.h"
#include "RankTwoTensor.h"

#include <utility>

/**
 * Tensor-valued Onsager closure on the N-1 independent component coordinates.
 *
 * The material applies the reduced mobility tensors to the manuscript's
 * temperature-weighted spatial forces and reconstructs the reference-component
 * flux so that the complete N-component relative flux sums to zero.
 */
class ADMulticomponentOnsagerFluxMaterial : public Material
{
public:
  static InputParameters validParams();

  ADMulticomponentOnsagerFluxMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;
  std::pair<Real, Real> auditMobility(const std::vector<RankTwoTensor> & mobility) const;

  const unsigned int _n_independent_components;
  const unsigned int _dim;
  const std::vector<Real> _constant_mobility_tensor_entries;
  std::vector<RankTwoTensor> _constant_mobility_tensors;
  const bool _tensor_property_mobility;
  const bool _tensor_component_property_mobility;
  const Real _symmetry_tolerance;
  const Real _positive_definite_tolerance;
  Real _constant_reciprocity_residual;
  Real _constant_minimum_cholesky_pivot;

  const ADVariableValue * _temperature_variable;
  const ADMaterialProperty<Real> * _temperature_property;
  std::vector<const ADMaterialProperty<RealVectorValue> *> _transport_forces;
  std::vector<const ADMaterialProperty<RankTwoTensor> *> _mobility_tensor_properties;
  std::vector<const ADMaterialProperty<Real> *> _mobility_tensor_component_properties;
  std::vector<ADMaterialProperty<RealVectorValue> *> _independent_component_fluxes;
  ADMaterialProperty<RealVectorValue> & _reference_component_flux;
  ADMaterialProperty<RealVectorValue> & _zero_sum_residual;
  ADMaterialProperty<Real> & _reciprocity_residual;
  ADMaterialProperty<Real> & _minimum_cholesky_pivot;
  ADMaterialProperty<Real> & _force_flux_power_density;
  ADMaterialProperty<Real> & _entropy_production;
};
