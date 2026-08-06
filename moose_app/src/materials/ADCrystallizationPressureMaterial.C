#include "ADCrystallizationPressureMaterial.h"

#include "metaphysicl/raw_type.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADCrystallizationPressureMaterial);

InputParameters
ADCrystallizationPressureMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Implements the manuscript crystallization pressure-work affinity, supersaturation "
      "specialization, and stress-shifted equilibrium supersaturation for one mechanism.");
  params.addRequiredParam<MooseEnum>("pressure_model", MooseEnum("prescribed supersaturation"), "How p_xtal is supplied.");
  params.addRequiredParam<MaterialPropertyName>("solid_intrinsic_density_name", "Positive rhobar_s.");
  params.addRequiredParam<MaterialPropertyName>("solid_material_stress_name", "Single-prime Cauchy stress sigma_s'.");
  params.addRequiredParam<MaterialPropertyName>("fluid_temperature_name", "Positive fluid temperature.");
  params.addParam<MaterialPropertyName>("supersaturation_name", "", "Positive Omega for pressure_model=supersaturation.");
  params.addParam<MaterialPropertyName>("crystallization_pressure_name", "", "Prescribed p_xtal for pressure_model=prescribed.");
  params.addParam<MaterialPropertyName>("reaction_affinity_name", "", "Optional independently assembled reaction affinity used to report a closure residual.");
  params.addRequiredRangeCheckedParam<Real>("gas_constant", "gas_constant>0", "Gas constant in units consistent with the affinity basis.");
  params.addRequiredRangeCheckedParam<Real>("solid_molar_volume", "solid_molar_volume>0", "Molar volume V_s.");
  params.addParam<std::string>("property_prefix", "crystallization_pressure", "Output property prefix.");
  return params;
}

ADCrystallizationPressureMaterial::ADCrystallizationPressureMaterial(const InputParameters & parameters)
  : Material(parameters),
    _pressure_model(getParam<MooseEnum>("pressure_model")),
    _intrinsic_density(getADMaterialProperty<Real>("solid_intrinsic_density_name")),
    _material_stress(getADMaterialProperty<RankTwoTensor>("solid_material_stress_name")),
    _fluid_temperature(getADMaterialProperty<Real>("fluid_temperature_name")),
    _supersaturation(getParam<MaterialPropertyName>("supersaturation_name").empty() ? nullptr : &getADMaterialProperty<Real>("supersaturation_name")),
    _prescribed_pressure(getParam<MaterialPropertyName>("crystallization_pressure_name").empty() ? nullptr : &getADMaterialProperty<Real>("crystallization_pressure_name")),
    _reaction_affinity(getParam<MaterialPropertyName>("reaction_affinity_name").empty() ? nullptr : &getADMaterialProperty<Real>("reaction_affinity_name")),
    _gas_constant(getParam<Real>("gas_constant")),
    _molar_volume(getParam<Real>("solid_molar_volume")),
    _property_prefix(getParam<std::string>("property_prefix")),
    _specific_volume(declareADProperty<Real>(prefixedName("specific_volume"))),
    _mean_material_stress(declareADProperty<Real>(prefixedName("mean_material_stress"))),
    _crystallization_pressure(declareADProperty<Real>(prefixedName("crystallization_pressure"))),
    _volumetric_affinity(declareADProperty<Real>(prefixedName("volumetric_affinity"))),
    _equilibrium_supersaturation(declareADProperty<Real>(prefixedName("equilibrium_supersaturation"))),
    _affinity_residual(declareADProperty<Real>(prefixedName("affinity_residual")))
{
  if (_property_prefix.empty())
    paramError("property_prefix", "The material-property prefix must be nonempty.");
  if (_pressure_model == "supersaturation" && !_supersaturation)
    paramError("supersaturation_name", "pressure_model=supersaturation requires supersaturation_name.");
  if (_pressure_model == "prescribed" && !_prescribed_pressure)
    paramError("crystallization_pressure_name", "pressure_model=prescribed requires crystallization_pressure_name.");
  if (_pressure_model == "supersaturation" && _prescribed_pressure)
    paramError("crystallization_pressure_name", "Do not supply crystallization_pressure_name with pressure_model=supersaturation.");
  if (_pressure_model == "prescribed" && _supersaturation)
    paramError("supersaturation_name", "Do not supply supersaturation_name with pressure_model=prescribed.");
}

MaterialPropertyName
ADCrystallizationPressureMaterial::prefixedName(const std::string & suffix) const
{
  return MaterialPropertyName(_property_prefix + "_" + suffix);
}

void
ADCrystallizationPressureMaterial::computeQpProperties()
{
  if (MetaPhysicL::raw_value(_intrinsic_density[_qp]) <= 0.0)
    mooseError(name(), ": solid intrinsic density must be positive.");
  if (MetaPhysicL::raw_value(_fluid_temperature[_qp]) <= 0.0)
    mooseError(name(), ": fluid temperature must be positive.");
  if (_supersaturation && MetaPhysicL::raw_value((*_supersaturation)[_qp]) <= 0.0)
    mooseError(name(), ": supersaturation must be positive.");

  _specific_volume[_qp] = 1.0 / _intrinsic_density[_qp];
  _mean_material_stress[_qp] = _material_stress[_qp].trace() / 3.0;
  _crystallization_pressure[_qp] = _pressure_model == "supersaturation"
      ? _gas_constant * _fluid_temperature[_qp] / _molar_volume * log((*_supersaturation)[_qp])
      : (*_prescribed_pressure)[_qp];
  _volumetric_affinity[_qp] = _specific_volume[_qp] * (_crystallization_pressure[_qp] + _mean_material_stress[_qp]);
  _equilibrium_supersaturation[_qp] = exp(-_molar_volume * _mean_material_stress[_qp] / (_gas_constant * _fluid_temperature[_qp]));
  _affinity_residual[_qp] = _reaction_affinity ? (*_reaction_affinity)[_qp] - _volumetric_affinity[_qp] : 0.0;
}
