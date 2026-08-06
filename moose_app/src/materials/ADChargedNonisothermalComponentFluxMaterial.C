#include "ADChargedNonisothermalComponentFluxMaterial.h"

registerMooseObject("MulticomponentReactiveFlowApp",
                    ADChargedNonisothermalComponentFluxMaterial);

InputParameters ADChargedNonisothermalComponentFluxMaterial::validParams() {
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Computes a current component flux from neutral-potential, "
      "electric-potential, and "
      "temperature gradients. The electric contribution uses only Grad(phi), "
      "so the flux and "
      "electric work are invariant under an electric-potential gauge shift.");
  params.addCoupledVar("neutral_potential", "Neutral component potential.");
  params.addParam<MaterialPropertyName>(
      "neutral_potential_gradient_name", "",
      "Optional AD material property containing the reconstructed neutral-potential gradient.");
  params.addCoupledVar(
      "electric_potential",
      "Electric potential for the direct electric-field force.");
  params.addCoupledVar("temperature",
                       "Temperature field for the thermal driving term.");
  params.addRangeCheckedParam<Real>("mobility", 0.0, "mobility>=0",
                                    "Constant scalar component mobility.");
  params.addParam<MaterialPropertyName>(
      "electric_potential_gradient_name", "",
      "Optional AD material property containing the reconstructed electric-potential gradient.");
  params.addParam<MaterialPropertyName>(
      "temperature_gradient_name", "",
      "Optional AD material property containing the reconstructed temperature gradient.");
  params.addParam<MaterialPropertyName>(
      "mobility_name", "",
      "Optional positive AD material property for a state-dependent scalar component mobility.");
  params.addParam<Real>("charge_number", 0.0,
                        "Charge coefficient multiplying Grad(phi).");
  params.addParam<Real>("thermal_force_coefficient", 0.0,
                        "Coefficient multiplying Grad(temperature).");
  params.addParam<MaterialPropertyName>(
      "transport_force_name", "component_transport_force",
      "Material property name for the full transport force.");
  params.addParam<MaterialPropertyName>(
      "current_component_flux_name", "current_component_extra_flux",
      "Material property name for the current component flux.");
  params.addParam<MaterialPropertyName>(
      "current_charge_flux_name", "current_charge_flux",
      "Material property name for charge_number times the component flux.");
  params.addParam<MaterialPropertyName>(
      "electric_field_work_name", "electric_field_work",
      "Material property name for the direct electric-field work on the charge "
      "flux.");
  return params;
}

ADChargedNonisothermalComponentFluxMaterial::
    ADChargedNonisothermalComponentFluxMaterial(
        const InputParameters &parameters)
    : Material(parameters),
      _grad_neutral_potential(isCoupled("neutral_potential")
                                  ? &adCoupledGradient("neutral_potential")
                                  : nullptr),
      _neutral_potential_gradient(
          getParam<MaterialPropertyName>("neutral_potential_gradient_name").empty()
              ? nullptr
              : &getADMaterialProperty<RealVectorValue>(
                    "neutral_potential_gradient_name")),
      _grad_electric_potential(isCoupled("electric_potential")
                                   ? &adCoupledGradient("electric_potential")
                                   : nullptr),
      _electric_potential_gradient(
          getParam<MaterialPropertyName>("electric_potential_gradient_name").empty()
              ? nullptr
              : &getADMaterialProperty<RealVectorValue>(
                    "electric_potential_gradient_name")),
      _grad_temperature(isCoupled("temperature")
                            ? &adCoupledGradient("temperature")
                            : nullptr),
      _temperature_gradient(
          getParam<MaterialPropertyName>("temperature_gradient_name").empty()
              ? nullptr
              : &getADMaterialProperty<RealVectorValue>("temperature_gradient_name")),
      _mobility(getParam<Real>("mobility")),
      _mobility_property(getParam<MaterialPropertyName>("mobility_name").empty()
                             ? nullptr
                             : &getADMaterialProperty<Real>("mobility_name")),
      _charge_number(getParam<Real>("charge_number")),
      _thermal_force_coefficient(getParam<Real>("thermal_force_coefficient")),
      _transport_force(declareADProperty<RealVectorValue>(
          getParam<MaterialPropertyName>("transport_force_name"))),
      _current_component_flux(declareADProperty<RealVectorValue>(
          getParam<MaterialPropertyName>("current_component_flux_name"))),
      _current_charge_flux(declareADProperty<RealVectorValue>(
          getParam<MaterialPropertyName>("current_charge_flux_name"))),
      _electric_field_work(declareADProperty<Real>(
          getParam<MaterialPropertyName>("electric_field_work_name"))) {
  if ((!_grad_neutral_potential && !_neutral_potential_gradient) ||
      (_grad_neutral_potential && _neutral_potential_gradient))
    paramError("neutral_potential",
               "Supply exactly one of neutral_potential or neutral_potential_gradient_name.");
  if ((_grad_electric_potential && _electric_potential_gradient) ||
      (_charge_number != 0.0 && !_grad_electric_potential && !_electric_potential_gradient))
    paramError("electric_potential",
               "Supply exactly one electric-potential gradient source when charge_number is nonzero.");
  if ((_grad_temperature && _temperature_gradient) ||
      (_thermal_force_coefficient != 0.0 && !_grad_temperature && !_temperature_gradient))
    paramError("temperature",
               "Supply exactly one temperature-gradient source when thermal_force_coefficient is nonzero.");
  if (_mobility_property && isParamSetByUser("mobility"))
    paramError("mobility_name", "Supply either mobility or mobility_name, not both.");
  if (!_mobility_property && !isParamSetByUser("mobility"))
    paramError("mobility", "Supply either mobility or mobility_name.");
}

void ADChargedNonisothermalComponentFluxMaterial::computeQpProperties() {
  ADRealVectorValue force = _neutral_potential_gradient
                                ? (*_neutral_potential_gradient)[_qp]
                                : (*_grad_neutral_potential)[_qp];
  if (_electric_potential_gradient)
    force += _charge_number * (*_electric_potential_gradient)[_qp];
  else if (_grad_electric_potential)
    force += _charge_number * (*_grad_electric_potential)[_qp];
  if (_temperature_gradient)
    force += _thermal_force_coefficient * (*_temperature_gradient)[_qp];
  else if (_grad_temperature)
    force += _thermal_force_coefficient * (*_grad_temperature)[_qp];

  _transport_force[_qp] = force;
  const ADReal mobility = _mobility_property ? (*_mobility_property)[_qp] : _mobility;
  _current_component_flux[_qp] = -mobility * force;
  _current_charge_flux[_qp] = _charge_number * _current_component_flux[_qp];

  ADRealVectorValue electric_field;
  if (_electric_potential_gradient)
    electric_field = -(*_electric_potential_gradient)[_qp];
  else if (_grad_electric_potential)
    electric_field = -(*_grad_electric_potential)[_qp];
  _electric_field_work[_qp] = _current_charge_flux[_qp] * electric_field;
}
