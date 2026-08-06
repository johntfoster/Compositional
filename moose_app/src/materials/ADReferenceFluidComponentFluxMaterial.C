#include "ADReferenceFluidComponentFluxMaterial.h"

#include "Function.h"

registerMooseObject("MulticomponentReactiveFlowApp",
                    ADReferenceFluidComponentFluxMaterial);

InputParameters ADReferenceFluidComponentFluxMaterial::validParams() {
  InputParameters params = Material::validParams();
  params += FunctionInterface::validParams();
  params.addClassDescription(
      "Assembles the component reference flux from a material-provided "
      "phase relative mass flux, extra component flux, and source.");
  params.addParam<MaterialPropertyName>("jacobian_name", "solid_reference_J",
                                        "Material property name for J.");
  params.addParam<MaterialPropertyName>(
      "jacobian_inverse_deformation_gradient_name", "solid_reference_J_F_inv",
      "Material property name for J F^{-1}.");
  params.addParam<MaterialPropertyName>("reference_relative_mass_flux",
                                        "reference_relative_mass_flux",
                                        "Material property name for W_f.");
  params.addParam<FunctionName>("component_mass_fraction", "1",
                                "Component mass fraction eta_f^alpha.");
  params.addParam<FunctionName>(
      "current_component_extra_flux", "0",
      "Spatial diffusive plus dispersive component flux.");
  params.addParam<MaterialPropertyName>(
      "current_component_extra_flux_material_name", "",
      "Optional spatial diffusive, dispersive, electrochemical, or thermal "
      "component flux "
      "material property added to current_component_extra_flux before "
      "pull-back.");
  params.addParam<FunctionName>(
      "current_component_source", "0",
      "Current-volume component source sum_m nu dot r.");
  params.addParam<MaterialPropertyName>(
      "reference_component_flux_name", "reference_component_flux",
      "Material property name for the full component flux.");
  params.addParam<MaterialPropertyName>(
      "reference_component_source_name", "reference_component_source",
      "Material property name for the J-weighted source.");
  return params;
}

ADReferenceFluidComponentFluxMaterial::ADReferenceFluidComponentFluxMaterial(
    const InputParameters &parameters)
    : Material(parameters), _J(getADMaterialProperty<Real>("jacobian_name")),
      _J_F_inv(getADMaterialProperty<RankTwoTensor>(
          "jacobian_inverse_deformation_gradient_name")),
      _reference_relative_mass_flux(getADMaterialProperty<RealVectorValue>(
          "reference_relative_mass_flux")),
      _component_mass_fraction(getFunction("component_mass_fraction")),
      _use_current_component_extra_flux_function(
          isParamSetByUser("current_component_extra_flux")),
      _current_component_extra_flux(
          getFunction("current_component_extra_flux")),
      _current_component_extra_flux_material(
          getParam<MaterialPropertyName>(
              "current_component_extra_flux_material_name")
                  .empty()
              ? nullptr
              : &getADMaterialProperty<RealVectorValue>(
                    getParam<MaterialPropertyName>(
                        "current_component_extra_flux_material_name"))),
      _current_component_source(getFunction("current_component_source")),
      _reference_component_flux(declareADProperty<RealVectorValue>(
          getParam<MaterialPropertyName>("reference_component_flux_name"))),
      _reference_component_source(declareADProperty<Real>(
          getParam<MaterialPropertyName>("reference_component_source_name"))) {}

void ADReferenceFluidComponentFluxMaterial::computeQpProperties() {
  const auto eta = _component_mass_fraction.value(_t, _q_point[_qp]);
  ADRealVectorValue component_extra_flux;
  if (_use_current_component_extra_flux_function)
    component_extra_flux =
        _current_component_extra_flux.vectorValue(_t, _q_point[_qp]);
  if (_current_component_extra_flux_material)
    component_extra_flux += (*_current_component_extra_flux_material)[_qp];

  _reference_component_flux[_qp] = eta * _reference_relative_mass_flux[_qp] +
                                   _J_F_inv[_qp] * component_extra_flux;
  _reference_component_source[_qp] =
      _J[_qp] * _current_component_source.value(_t, _q_point[_qp]);
}
