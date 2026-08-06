#include "ADReferenceFluidComponentMaterial.h"

#include "Function.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADReferenceFluidComponentMaterial);

InputParameters
ADReferenceFluidComponentMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params += FunctionInterface::validParams();
  params.addClassDescription("Builds the solid-reference relative mass flux W_f, component flux, "
                             "and J-weighted component source for a fluid component balance.");
  params.addParam<MaterialPropertyName>(
      "jacobian_name", "solid_reference_J", "Material property name for J.");
  params.addParam<MaterialPropertyName>("jacobian_inverse_deformation_gradient_name",
                                        "solid_reference_J_F_inv",
                                        "Material property name for J F^{-1}.");
  params.addParam<FunctionName>(
      "current_relative_mass_flux",
      "0",
      "Spatial relative phase mass flux w_f; its vector value is pulled back as J F^{-1} w_f.");
  params.addParam<FunctionName>("current_component_extra_flux",
                                "0",
                                "Spatial diffusive plus dispersive component flux.");
  params.addParam<FunctionName>(
      "component_mass_fraction", "1", "Component mass fraction eta_f^alpha.");
  params.addParam<FunctionName>("current_component_source",
                                "0",
                                "Current-volume component source sum_m nu dot r.");
  params.addParam<MaterialPropertyName>("reference_relative_mass_flux_name",
                                        "reference_relative_mass_flux",
                                        "Material property name for W_f.");
  params.addParam<MaterialPropertyName>("reference_component_flux_name",
                                        "reference_component_flux",
                                        "Material property name for the full component flux.");
  params.addParam<MaterialPropertyName>("reference_component_source_name",
                                        "reference_component_source",
                                        "Material property name for the J-weighted source.");
  return params;
}

ADReferenceFluidComponentMaterial::ADReferenceFluidComponentMaterial(
    const InputParameters & parameters)
  : Material(parameters),
    _J(getADMaterialProperty<Real>("jacobian_name")),
    _J_F_inv(getADMaterialProperty<RankTwoTensor>("jacobian_inverse_deformation_gradient_name")),
    _current_relative_mass_flux(getFunction("current_relative_mass_flux")),
    _current_component_extra_flux(getFunction("current_component_extra_flux")),
    _component_mass_fraction(getFunction("component_mass_fraction")),
    _current_component_source(getFunction("current_component_source")),
    _reference_relative_mass_flux(
        declareADProperty<RealVectorValue>(getParam<MaterialPropertyName>(
            "reference_relative_mass_flux_name"))),
    _reference_component_flux(
        declareADProperty<RealVectorValue>(getParam<MaterialPropertyName>("reference_component_flux_name"))),
    _reference_component_source(
        declareADProperty<Real>(getParam<MaterialPropertyName>("reference_component_source_name")))
{
}

void
ADReferenceFluidComponentMaterial::computeQpProperties()
{
  const auto w = _current_relative_mass_flux.vectorValue(_t, _q_point[_qp]);
  const auto component_extra_flux = _current_component_extra_flux.vectorValue(_t, _q_point[_qp]);
  const auto eta = _component_mass_fraction.value(_t, _q_point[_qp]);

  _reference_relative_mass_flux[_qp] = _J_F_inv[_qp] * w;
  _reference_component_flux[_qp] =
      eta * _reference_relative_mass_flux[_qp] + _J_F_inv[_qp] * component_extra_flux;
  _reference_component_source[_qp] = _J[_qp] * _current_component_source.value(_t, _q_point[_qp]);
}
