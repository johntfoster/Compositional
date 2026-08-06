#include "ADBinarySolidSpatialMassMaterial.h"

#include "metaphysicl/raw_type.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADBinarySolidSpatialMassMaterial);

InputParameters
ADBinarySolidSpatialMassMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Computes the pulled-back single-component solid spatial-mass storage "
      "J_s phi_s rhobar_s and its complete AD material time rate.");
  params.addParam<MaterialPropertyName>(
      "solid_jacobian_name", "solid_reference_J", "Solid-reference Jacobian J_s.");
  params.addParam<MaterialPropertyName>("solid_jacobian_rate_name",
                                        "solid_reference_J_dot",
                                        "Material time rate of J_s.");
  params.addRequiredCoupledVar("solid_volume_fraction", "Solid phase volume fraction phi_s.");
  params.addRequiredCoupledVar("solid_intrinsic_density", "Intrinsic solid density rhobar_s.");
  params.addParam<MaterialPropertyName>("reference_component_accumulation_name",
                                        "solid_component_reference_accumulation",
                                        "Output name for J_s phi_s rhobar_s.");
  params.addParam<MaterialPropertyName>("reference_component_storage_rate_name",
                                        "solid_component_reference_storage_rate",
                                        "Output name for d(J_s phi_s rhobar_s)/dt.");
  return params;
}

ADBinarySolidSpatialMassMaterial::ADBinarySolidSpatialMassMaterial(
    const InputParameters & parameters)
  : Material(parameters),
    _J(getADMaterialProperty<Real>("solid_jacobian_name")),
    _J_dot(getADMaterialProperty<Real>("solid_jacobian_rate_name")),
    _solid_volume_fraction(adCoupledValue("solid_volume_fraction")),
    _solid_volume_fraction_dot(adCoupledDot("solid_volume_fraction")),
    _solid_intrinsic_density(adCoupledValue("solid_intrinsic_density")),
    _solid_intrinsic_density_dot(adCoupledDot("solid_intrinsic_density")),
    _reference_component_accumulation(declareADProperty<Real>(
        getParam<MaterialPropertyName>("reference_component_accumulation_name"))),
    _reference_component_storage_rate(declareADProperty<Real>(
        getParam<MaterialPropertyName>("reference_component_storage_rate_name")))
{
}

void
ADBinarySolidSpatialMassMaterial::computeQpProperties()
{
  if (MetaPhysicL::raw_value(_solid_volume_fraction[_qp]) <= 0.0)
    mooseError("ADBinarySolidSpatialMassMaterial requires positive solid volume fraction.");
  if (MetaPhysicL::raw_value(_solid_intrinsic_density[_qp]) <= 0.0)
    mooseError("ADBinarySolidSpatialMassMaterial requires positive intrinsic solid density.");

  _reference_component_accumulation[_qp] =
      _J[_qp] * _solid_volume_fraction[_qp] * _solid_intrinsic_density[_qp];
  _reference_component_storage_rate[_qp] =
      (_J_dot[_qp] * _solid_volume_fraction[_qp] +
       _J[_qp] * _solid_volume_fraction_dot[_qp]) *
          _solid_intrinsic_density[_qp] +
      _J[_qp] * _solid_volume_fraction[_qp] * _solid_intrinsic_density_dot[_qp];
}
