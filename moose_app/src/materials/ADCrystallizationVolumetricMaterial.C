#include "ADCrystallizationVolumetricMaterial.h"

#include "metaphysicl/raw_type.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADCrystallizationVolumetricMaterial);

InputParameters
ADCrystallizationVolumetricMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Implements the manuscript scalar crystallization split ln J=ln a_s+ln Jbar_s, "
      "quadratic transformed volumetric energy, and double-/single-prime mean stresses.");
  params.addRequiredParam<MaterialPropertyName>("distension_name", "Positive scalar a_s.");
  params.addRequiredParam<MaterialPropertyName>("true_jacobian_name", "Positive true-solid Jbar_s.");
  params.addRequiredParam<MaterialPropertyName>("total_jacobian_name", "Positive total J.");
  params.addRequiredParam<MaterialPropertyName>("equivalent_pressure_name", "Equivalent pore pressure p_E.");
  params.addParam<MaterialPropertyName>("biot_coefficient_name", "", "Optional AD phase Biot coefficient B_s.");
  params.addRangeCheckedParam<Real>("biot_coefficient", 1.0, "biot_coefficient>=0 & biot_coefficient<=1", "Constant B_s used when no property is supplied.");
  params.addRequiredRangeCheckedParam<Real>("tangent_bulk_modulus", "tangent_bulk_modulus>0", "K_s^star.");
  params.addParam<std::string>("property_prefix", "crystallization_volumetric", "Output property prefix.");
  return params;
}

ADCrystallizationVolumetricMaterial::ADCrystallizationVolumetricMaterial(const InputParameters & parameters)
  : Material(parameters),
    _distension(getADMaterialProperty<Real>("distension_name")),
    _true_jacobian(getADMaterialProperty<Real>("true_jacobian_name")),
    _total_jacobian(getADMaterialProperty<Real>("total_jacobian_name")),
    _equivalent_pressure(getADMaterialProperty<Real>("equivalent_pressure_name")),
    _biot_coefficient(getParam<MaterialPropertyName>("biot_coefficient_name").empty() ? nullptr : &getADMaterialProperty<Real>("biot_coefficient_name")),
    _constant_biot_coefficient(getParam<Real>("biot_coefficient")),
    _bulk_modulus(getParam<Real>("tangent_bulk_modulus")),
    _property_prefix(getParam<std::string>("property_prefix")),
    _reconstructed_jacobian(declareADProperty<Real>(prefixedName("reconstructed_jacobian"))),
    _volumetric_split_residual(declareADProperty<Real>(prefixedName("volumetric_split_residual"))),
    _logarithmic_volume_strain(declareADProperty<Real>(prefixedName("logarithmic_volume_strain"))),
    _transformed_volumetric_energy(declareADProperty<Real>(prefixedName("transformed_volumetric_energy"))),
    _double_prime_mean_stress(declareADProperty<Real>(prefixedName("double_prime_mean_stress"))),
    _prime_mean_stress(declareADProperty<Real>(prefixedName("prime_mean_stress"))),
    _distension_conjugate(declareADProperty<Real>(prefixedName("distension_conjugate"))),
    _double_prime_stress(declareADProperty<RankTwoTensor>(prefixedName("double_prime_stress"))),
    _prime_stress(declareADProperty<RankTwoTensor>(prefixedName("prime_stress")))
{
  if (_property_prefix.empty())
    paramError("property_prefix", "The material-property prefix must be nonempty.");
}

MaterialPropertyName
ADCrystallizationVolumetricMaterial::prefixedName(const std::string & suffix) const
{
  return MaterialPropertyName(_property_prefix + "_" + suffix);
}

void
ADCrystallizationVolumetricMaterial::computeQpProperties()
{
  if (MetaPhysicL::raw_value(_distension[_qp]) <= 0.0 ||
      MetaPhysicL::raw_value(_true_jacobian[_qp]) <= 0.0 ||
      MetaPhysicL::raw_value(_total_jacobian[_qp]) <= 0.0)
    mooseError(name(), ": a_s, Jbar_s, and J must all be positive.");

  const ADReal B = _biot_coefficient ? (*_biot_coefficient)[_qp] : _constant_biot_coefficient;
  if (MetaPhysicL::raw_value(B) < 0.0 || MetaPhysicL::raw_value(B) > 1.0)
    mooseError(name(), ": phase Biot coefficient must lie in [0,1].");

  _reconstructed_jacobian[_qp] = _distension[_qp] * _true_jacobian[_qp];
  _volumetric_split_residual[_qp] = log(_total_jacobian[_qp]) - log(_distension[_qp]) - log(_true_jacobian[_qp]);
  _logarithmic_volume_strain[_qp] = log(_total_jacobian[_qp]);
  _transformed_volumetric_energy[_qp] = 0.5 * _bulk_modulus * _logarithmic_volume_strain[_qp] * _logarithmic_volume_strain[_qp];
  _double_prime_mean_stress[_qp] = _bulk_modulus * _logarithmic_volume_strain[_qp];
  _prime_mean_stress[_qp] = _double_prime_mean_stress[_qp] + (1.0 - B) * _equivalent_pressure[_qp];
  _distension_conjugate[_qp] = _prime_mean_stress[_qp];
  _double_prime_stress[_qp] = _double_prime_mean_stress[_qp] * RankTwoTensor::Identity();
  _prime_stress[_qp] = _prime_mean_stress[_qp] * RankTwoTensor::Identity();
}
