#include "ADReferenceThermalEnergyMaterial.h"

#include "Function.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADReferenceThermalEnergyMaterial);

InputParameters
ADReferenceThermalEnergyMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params += FunctionInterface::validParams();
  params.addClassDescription(
      "Computes the spatial Fourier heat flux q=-k F^{-T} Grad_X(theta), its "
      "solid-reference pull-back Q=J F^{-1}q, and the J-weighted direct relative-current "
      "electric work and volumetric heat supply for a stationary thermal energy balance.");
  params.addRequiredParam<MaterialPropertyName>(
      "reference_temperature_gradient_name",
      "AD material property containing the reconstructed reference temperature gradient.");
  params.addRangeCheckedParam<Real>(
      "thermal_conductivity", 0.0, "thermal_conductivity>=0", "Constant Fourier conductivity.");
  params.addParam<MaterialPropertyName>(
      "thermal_conductivity_name", "", "Optional nonnegative AD Fourier conductivity property.");
  params.addParam<MaterialPropertyName>(
      "inverse_deformation_gradient_name",
      "solid_reference_F_inv",
      "Material property containing F^{-1}.");
  params.addParam<MaterialPropertyName>(
      "jacobian_inverse_deformation_gradient_name",
      "solid_reference_J_F_inv",
      "Material property containing J F^{-1}.");
  params.addParam<MaterialPropertyName>(
      "jacobian_name", "solid_reference_J", "Material property containing J.");
  params.addRequiredParam<std::vector<MaterialPropertyName>>(
      "electric_field_work_names",
      "Direct current-volume electric-field-work properties to sum before multiplying by J.");
  params.addParam<FunctionName>(
      "current_volumetric_heat_supply", "0", "Current-volume volumetric heat supply rho r.");
  params.addParam<MaterialPropertyName>(
      "current_heat_flux_name", "current_heat_flux", "Output spatial heat-flux property name.");
  params.addParam<MaterialPropertyName>(
      "reference_heat_flux_name", "reference_heat_flux", "Output reference heat-flux name.");
  params.addParam<MaterialPropertyName>(
      "reference_electric_work_name",
      "reference_electric_work",
      "Output J-weighted direct electric-work name.");
  params.addParam<MaterialPropertyName>(
      "reference_heat_supply_name",
      "reference_heat_supply",
      "Output J-weighted volumetric heat-supply name.");
  params.addParam<MaterialPropertyName>(
      "reference_energy_source_name",
      "reference_energy_source",
      "Output sum of reference electric work and heat supply.");
  return params;
}

ADReferenceThermalEnergyMaterial::ADReferenceThermalEnergyMaterial(
    const InputParameters & parameters)
  : Material(parameters),
    _reference_temperature_gradient(getADMaterialProperty<RealVectorValue>(
        getParam<MaterialPropertyName>("reference_temperature_gradient_name"))),
    _thermal_conductivity(getParam<Real>("thermal_conductivity")),
    _thermal_conductivity_property(
        getParam<MaterialPropertyName>("thermal_conductivity_name").empty()
            ? nullptr
            : &getADMaterialProperty<Real>(
                  getParam<MaterialPropertyName>("thermal_conductivity_name"))),
    _F_inv(getADMaterialProperty<RankTwoTensor>("inverse_deformation_gradient_name")),
    _J_F_inv(
        getADMaterialProperty<RankTwoTensor>("jacobian_inverse_deformation_gradient_name")),
    _J(getADMaterialProperty<Real>("jacobian_name")),
    _current_volumetric_heat_supply(getFunction("current_volumetric_heat_supply")),
    _current_heat_flux(declareADProperty<RealVectorValue>(
        getParam<MaterialPropertyName>("current_heat_flux_name"))),
    _reference_heat_flux(declareADProperty<RealVectorValue>(
        getParam<MaterialPropertyName>("reference_heat_flux_name"))),
    _reference_electric_work(declareADProperty<Real>(
        getParam<MaterialPropertyName>("reference_electric_work_name"))),
    _reference_heat_supply(declareADProperty<Real>(
        getParam<MaterialPropertyName>("reference_heat_supply_name"))),
    _reference_energy_source(declareADProperty<Real>(
        getParam<MaterialPropertyName>("reference_energy_source_name")))
{
  if (_thermal_conductivity_property && isParamSetByUser("thermal_conductivity"))
    paramError("thermal_conductivity_name",
               "Supply either thermal_conductivity or thermal_conductivity_name, not both.");
  if (!_thermal_conductivity_property && !isParamSetByUser("thermal_conductivity"))
    paramError("thermal_conductivity",
               "Supply either thermal_conductivity or thermal_conductivity_name.");

  for (const auto & name :
       getParam<std::vector<MaterialPropertyName>>("electric_field_work_names"))
    _electric_field_work.push_back(&getADMaterialProperty<Real>(name));
  if (_electric_field_work.empty())
    paramError("electric_field_work_names", "Supply at least one direct electric-work property.");
}

void
ADReferenceThermalEnergyMaterial::computeQpProperties()
{
  const ADReal conductivity =
      _thermal_conductivity_property ? (*_thermal_conductivity_property)[_qp]
                                     : _thermal_conductivity;
  if (MetaPhysicL::raw_value(conductivity) < 0.0)
    mooseError("ADReferenceThermalEnergyMaterial requires nonnegative thermal conductivity.");

  const ADRealVectorValue spatial_temperature_gradient =
      _F_inv[_qp].transpose() * _reference_temperature_gradient[_qp];
  _current_heat_flux[_qp] = -conductivity * spatial_temperature_gradient;
  _reference_heat_flux[_qp] = _J_F_inv[_qp] * _current_heat_flux[_qp];

  ADReal current_electric_work = 0.0;
  for (const auto * work : _electric_field_work)
    current_electric_work += (*work)[_qp];
  _reference_electric_work[_qp] = _J[_qp] * current_electric_work;
  _reference_heat_supply[_qp] =
      _J[_qp] * _current_volumetric_heat_supply.value(_t, _q_point[_qp]);
  _reference_energy_source[_qp] =
      _reference_electric_work[_qp] + _reference_heat_supply[_qp];
}
