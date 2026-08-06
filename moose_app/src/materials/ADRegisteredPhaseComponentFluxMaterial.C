#include "ADRegisteredPhaseComponentFluxMaterial.h"
#include "PhaseRegistry.h"

#include "Function.h"

registerMooseObject("MulticomponentReactiveFlowApp",
                    ADRegisteredPhaseComponentFluxMaterial);

InputParameters ADRegisteredPhaseComponentFluxMaterial::validParams() {
  InputParameters params = Material::validParams();
  params += FunctionInterface::validParams();
  params.addClassDescription("Assembles a selected component reference flux "
                             "from an arbitrary set of registered "
                             "phase reference relative mass fluxes and phase "
                             "mass fractions. Optional phase-active "
                             "material properties remove inactive phases from "
                             "the flux and its AD graph branch.");
  params.addRequiredParam<UserObjectName>("phase_registry",
                                          "Input-deck phase registry.");
  params.addRequiredParam<std::vector<std::string>>(
      "phases", "Registered phases whose fluxes enter the component flux.");
  params.addRequiredParam<unsigned int>("component",
                                        "Component index to assemble.");
  params.addParam<MaterialPropertyName>("jacobian_name", "solid_reference_J",
                                        "Material property name for J.");
  params.addParam<MaterialPropertyName>(
      "jacobian_inverse_deformation_gradient_name", "solid_reference_J_F_inv",
      "Material property name for J F^{-1}.");
  params.addRequiredParam<std::vector<MaterialPropertyName>>(
      "phase_reference_relative_mass_flux_names",
      "Reference relative mass flux material properties in the same order as "
      "phases.");
  params.addRequiredParam<std::vector<MaterialPropertyName>>(
      "phase_component_mass_fraction_names",
      "Phase component mass-fraction material properties in the same order as "
      "phases.");
  params.addParam<std::vector<MaterialPropertyName>>(
      "phase_active_names", {},
      "Optional active-phase indicator material properties in the same order "
      "as phases.");
  params.addParam<FunctionName>(
      "current_component_extra_flux", "0",
      "Spatial diffusive plus dispersive component flux.");
  params.addParam<MaterialPropertyName>(
      "current_component_extra_flux_material_name", "",
      "Optional spatial diffusive, dispersive, electrochemical, or thermal "
      "component flux "
      "material property added to current_component_extra_flux before "
      "pull-back.");
  params.addParam<FunctionName>("current_component_source", "0",
                                "Current-volume component source.");
  params.addParam<MaterialPropertyName>(
      "reference_component_flux_name", "reference_component_flux",
      "Material property name for the assembled component flux.");
  params.addParam<MaterialPropertyName>(
      "reference_component_source_name", "reference_component_source",
      "Material property name for the J-weighted source.");
  return params;
}

ADRegisteredPhaseComponentFluxMaterial::ADRegisteredPhaseComponentFluxMaterial(
    const InputParameters &parameters)
    : Material(parameters),
      _phase_registry(getUserObject<PhaseRegistry>("phase_registry")),
      _phases(getParam<std::vector<std::string>>("phases")),
      _component(getParam<unsigned int>("component")),
      _use_phase_active(
          !getParam<std::vector<MaterialPropertyName>>("phase_active_names")
               .empty()),
      _J(getADMaterialProperty<Real>("jacobian_name")),
      _J_F_inv(getADMaterialProperty<RankTwoTensor>(
          "jacobian_inverse_deformation_gradient_name")),
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
          getParam<MaterialPropertyName>("reference_component_source_name"))) {
  if (_phases.empty())
    paramError("phases", "Supply at least one phase.");
  for (const auto &phase : _phases)
    if (!_phase_registry.hasPhase(phase))
      paramError("phases", "Phase '", phase, "' is not registered.");

  const auto flux_names = getParam<std::vector<MaterialPropertyName>>(
      "phase_reference_relative_mass_flux_names");
  const auto mass_fraction_names = getParam<std::vector<MaterialPropertyName>>(
      "phase_component_mass_fraction_names");
  const auto active_names =
      getParam<std::vector<MaterialPropertyName>>("phase_active_names");

  if (flux_names.size() != _phases.size())
    paramError(
        "phase_reference_relative_mass_flux_names",
        "Supply exactly one reference relative mass flux for each phase.");
  if (mass_fraction_names.size() != _phases.size())
    paramError("phase_component_mass_fraction_names",
               "Supply exactly one component mass fraction for each phase.");
  if (_use_phase_active && active_names.size() != _phases.size())
    paramError("phase_active_names",
               "Supply exactly one active indicator for each phase.");

  _phase_reference_relative_mass_fluxes.reserve(_phases.size());
  _phase_component_mass_fractions.reserve(_phases.size());
  _phase_active.reserve(_phases.size());
  for (const auto p : make_range(_phases.size())) {
    _phase_reference_relative_mass_fluxes.push_back(
        &getADMaterialProperty<RealVectorValue>(flux_names[p]));
    _phase_component_mass_fractions.push_back(
        &getADMaterialProperty<Real>(mass_fraction_names[p]));
    if (_use_phase_active)
      _phase_active.push_back(&getADMaterialProperty<Real>(active_names[p]));
  }
}

void ADRegisteredPhaseComponentFluxMaterial::computeQpProperties() {
  _reference_component_flux[_qp] = RealVectorValue(0, 0, 0);
  for (const auto p : make_range(_phases.size())) {
    const ADReal active = _use_phase_active ? (*_phase_active[p])[_qp] : 1.0;
    _reference_component_flux[_qp] +=
        active * (*_phase_component_mass_fractions[p])[_qp] *
        (*_phase_reference_relative_mass_fluxes[p])[_qp];
  }

  ADRealVectorValue component_extra_flux;
  if (_use_current_component_extra_flux_function)
    component_extra_flux =
        _current_component_extra_flux.vectorValue(_t, _q_point[_qp]);
  if (_current_component_extra_flux_material)
    component_extra_flux += (*_current_component_extra_flux_material)[_qp];
  _reference_component_flux[_qp] += _J_F_inv[_qp] * component_extra_flux;
  _reference_component_source[_qp] =
      _J[_qp] * _current_component_source.value(_t, _q_point[_qp]);
}
