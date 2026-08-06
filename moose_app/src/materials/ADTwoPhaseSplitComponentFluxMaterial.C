#include "ADTwoPhaseSplitComponentFluxMaterial.h"

#include "Function.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADTwoPhaseSplitComponentFluxMaterial);

InputParameters
ADTwoPhaseSplitComponentFluxMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params += FunctionInterface::validParams();
  params.addClassDescription("Assembles a selected component reference flux from two "
                             "phase-specific reference relative mass fluxes and the "
                             "phase compositions computed by a split material.");
  params.addRequiredParam<unsigned int>("component", "Component index to assemble.");
  params.addParam<MaterialPropertyName>(
      "jacobian_name", "solid_reference_J", "Material property name for J.");
  params.addParam<MaterialPropertyName>("phase0_reference_relative_mass_flux",
                                        "phase0_reference_relative_mass_flux",
                                        "Material property name for W_0.");
  params.addParam<MaterialPropertyName>("phase1_reference_relative_mass_flux",
                                        "phase1_reference_relative_mass_flux",
                                        "Material property name for W_1.");
  params.addParam<FunctionName>("current_component_source",
                                "0",
                                "Current-volume component source.");
  params.addParam<MaterialPropertyName>("reference_component_flux_name",
                                        "reference_component_flux",
                                        "Material property name for the assembled component flux.");
  params.addParam<MaterialPropertyName>("reference_component_source_name",
                                        "reference_component_source",
                                        "Material property name for the J-weighted source.");
  return params;
}

ADTwoPhaseSplitComponentFluxMaterial::ADTwoPhaseSplitComponentFluxMaterial(
    const InputParameters & parameters)
  : Material(parameters),
    _component(getParam<unsigned int>("component")),
    _phase0_reference_relative_mass_flux(
        getADMaterialProperty<RealVectorValue>("phase0_reference_relative_mass_flux")),
    _phase1_reference_relative_mass_flux(
        getADMaterialProperty<RealVectorValue>("phase1_reference_relative_mass_flux")),
    _phase0_component_mass_fraction(getADMaterialProperty<Real>(
        "phase0_component_mass_fraction_" + std::to_string(_component))),
    _phase1_component_mass_fraction(getADMaterialProperty<Real>(
        "phase1_component_mass_fraction_" + std::to_string(_component))),
    _J(getADMaterialProperty<Real>("jacobian_name")),
    _current_component_source(getFunction("current_component_source")),
    _reference_component_flux(
        declareADProperty<RealVectorValue>(getParam<MaterialPropertyName>("reference_component_flux_name"))),
    _reference_component_source(
        declareADProperty<Real>(getParam<MaterialPropertyName>("reference_component_source_name")))
{
}

void
ADTwoPhaseSplitComponentFluxMaterial::computeQpProperties()
{
  _reference_component_flux[_qp] =
      _phase0_component_mass_fraction[_qp] * _phase0_reference_relative_mass_flux[_qp] +
      _phase1_component_mass_fraction[_qp] * _phase1_reference_relative_mass_flux[_qp];
  _reference_component_source[_qp] = _J[_qp] * _current_component_source.value(_t, _q_point[_qp]);
}
