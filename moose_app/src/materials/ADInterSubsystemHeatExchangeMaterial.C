#include "ADInterSubsystemHeatExchangeMaterial.h"

#include "metaphysicl/raw_type.h"

registerMooseObject("MulticomponentReactiveFlowApp",
                    ADInterSubsystemHeatExchangeMaterial);

InputParameters
ADInterSubsystemHeatExchangeMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Implements the manuscript fluid-solid heat exchange q_F=h(theta_S-theta_F), "
      "q_S=-q_F, including exact mixture cancellation and entropy production.");
  params.addCoupledVar("fluid_temperature", "Fluid thermal-subsystem absolute temperature.");
  params.addCoupledVar("solid_temperature", "Solid thermal-subsystem absolute temperature.");
  params.addParam<MaterialPropertyName>(
      "fluid_temperature_name",
      "",
      "Optional AD reconstructed fluid absolute-temperature property; replaces the coupled "
      "fluid_temperature.");
  params.addParam<MaterialPropertyName>(
      "solid_temperature_name",
      "",
      "Optional AD reconstructed solid absolute-temperature property; replaces the coupled "
      "solid_temperature.");
  params.addRangeCheckedParam<Real>("heat_transfer_coefficient",
                                    0.0,
                                    "heat_transfer_coefficient>=0",
                                    "Constant nonnegative current-volume h_FS in W/(m^3 K).");
  params.addParam<MaterialPropertyName>("heat_transfer_coefficient_name",
                                        "",
                                        "Optional nonnegative AD current-volume h_FS property in "
                                        "W/(m^3 K).");
  params.addParam<MaterialPropertyName>("fluid_heat_source_name",
                                        "fluid_solid_heat_exchange_fluid_source",
                                        "Fluid current-volume energy-supply property name in W/m^3.");
  params.addParam<MaterialPropertyName>("solid_heat_source_name",
                                        "fluid_solid_heat_exchange_solid_source",
                                        "Solid current-volume energy-supply property name in W/m^3.");
  params.addParam<MaterialPropertyName>("exchange_cancellation_name",
                                        "fluid_solid_heat_exchange_cancellation",
                                        "q_F+q_S audit property name.");
  params.addParam<MaterialPropertyName>("entropy_production_name",
                                        "fluid_solid_heat_exchange_entropy_production",
                                        "q_F/theta_F+q_S/theta_S entropy-production property name "
                                        "in W/(m^3 K).");
  return params;
}

ADInterSubsystemHeatExchangeMaterial::ADInterSubsystemHeatExchangeMaterial(
    const InputParameters & parameters)
  : Material(parameters),
    _fluid_temperature_variable(
        isCoupled("fluid_temperature") ? &adCoupledValue("fluid_temperature") : nullptr),
    _solid_temperature_variable(
        isCoupled("solid_temperature") ? &adCoupledValue("solid_temperature") : nullptr),
    _fluid_temperature_property(
        getParam<MaterialPropertyName>("fluid_temperature_name").empty()
            ? nullptr
            : &getADMaterialProperty<Real>("fluid_temperature_name")),
    _solid_temperature_property(
        getParam<MaterialPropertyName>("solid_temperature_name").empty()
            ? nullptr
            : &getADMaterialProperty<Real>("solid_temperature_name")),
    _coefficient_property(
        getParam<MaterialPropertyName>("heat_transfer_coefficient_name").empty()
            ? nullptr
            : &getADMaterialProperty<Real>("heat_transfer_coefficient_name")),
    _coefficient(getParam<Real>("heat_transfer_coefficient")),
    _fluid_source(declareADProperty<Real>(getParam<MaterialPropertyName>("fluid_heat_source_name"))),
    _solid_source(declareADProperty<Real>(getParam<MaterialPropertyName>("solid_heat_source_name"))),
    _exchange_cancellation(
        declareADProperty<Real>(getParam<MaterialPropertyName>("exchange_cancellation_name"))),
    _entropy_production(
        declareADProperty<Real>(getParam<MaterialPropertyName>("entropy_production_name")))
{
  if (static_cast<bool>(_fluid_temperature_variable) ==
      static_cast<bool>(_fluid_temperature_property))
    paramError("fluid_temperature_name",
               "Supply exactly one of fluid_temperature or fluid_temperature_name.");
  if (static_cast<bool>(_solid_temperature_variable) ==
      static_cast<bool>(_solid_temperature_property))
    paramError("solid_temperature_name",
               "Supply exactly one of solid_temperature or solid_temperature_name.");
  if (_coefficient_property && isParamSetByUser("heat_transfer_coefficient"))
    paramError("heat_transfer_coefficient_name",
               "Choose a constant coefficient or an AD coefficient property, not both.");
}

void
ADInterSubsystemHeatExchangeMaterial::computeQpProperties()
{
  const ADReal h = _coefficient_property ? (*_coefficient_property)[_qp] : ADReal(_coefficient);
  const ADReal theta_f = _fluid_temperature_property
                             ? (*_fluid_temperature_property)[_qp]
                             : (*_fluid_temperature_variable)[_qp];
  const ADReal theta_s = _solid_temperature_property
                             ? (*_solid_temperature_property)[_qp]
                             : (*_solid_temperature_variable)[_qp];
  if (MetaPhysicL::raw_value(h) < 0.0)
    mooseError(name(), ": heat-transfer coefficient must remain nonnegative.");
  if (MetaPhysicL::raw_value(theta_f) <= 0.0 || MetaPhysicL::raw_value(theta_s) <= 0.0)
    mooseError(name(), ": absolute subsystem temperatures must remain positive.");

  _fluid_source[_qp] = h * (theta_s - theta_f);
  _solid_source[_qp] = -_fluid_source[_qp];
  _exchange_cancellation[_qp] = _fluid_source[_qp] + _solid_source[_qp];
  _entropy_production[_qp] =
      _fluid_source[_qp] / theta_f + _solid_source[_qp] / theta_s;
}
