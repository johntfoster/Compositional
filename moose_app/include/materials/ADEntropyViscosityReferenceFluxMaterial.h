#pragma once

#include "Material.h"
#include "RankTwoTensor.h"

/**
 * Residual entropy-viscosity stabilization for a reconstructed CG/EG scalar.
 *
 * The material exposes the artificial reference flux and matching isotropic
 * mobility separately so that volume, interior-facet, and boundary terms can
 * be selected independently in an input deck.
 */
class ADEntropyViscosityReferenceFluxMaterial : public Material
{
public:
  static InputParameters validParams();

  ADEntropyViscosityReferenceFluxMaterial(const InputParameters & parameters);

protected:
  void computeQpProperties() override;

  const ADMaterialProperty<Real> & _scalar;
  const ADMaterialProperty<RealVectorValue> & _scalar_gradient;
  const ADMaterialProperty<Real> & _scalar_dot;
  const ADMaterialProperty<RealVectorValue> * _transport_velocity;
  const ADMaterialProperty<RealVectorValue> * _entropy_flux_derivative;
  const ADMaterialProperty<Real> * _source;
  std::vector<const ADMaterialProperty<Real> *> _sources;
  const ADMaterialProperty<Real> * _strong_residual;
  const ADMaterialProperty<Real> * _supplied_entropy_residual;
  const ADMaterialProperty<Real> * _mass_coefficient_property;
  const ADMaterialProperty<Real> * _entropy_storage_coefficient;
  const ADMaterialProperty<Real> * _entropy_storage_coefficient_rate;

  const Real _mass_coefficient;
  const Real _storage_coefficient;
  const Real _lambda_linear;
  const Real _lambda_entropy;
  const MooseEnum _entropy;
  const unsigned int _power;
  const Real _regularization;
  const Real _normalization_floor;
  const bool _differentiate_viscosity;
  const PostprocessorValue & _entropy_average;
  const PostprocessorValue & _entropy_deviation_norm;

  ADMaterialProperty<Real> & _entropy_value;
  ADMaterialProperty<Real> & _entropy_residual;
  ADMaterialProperty<Real> & _linear_viscosity;
  ADMaterialProperty<Real> & _residual_viscosity;
  ADMaterialProperty<Real> & _stabilization_viscosity;
  ADMaterialProperty<RealVectorValue> & _reference_flux;
  ADMaterialProperty<RankTwoTensor> & _mobility;
};
