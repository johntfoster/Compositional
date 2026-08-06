#include "ADSolidPhaseMassVolumeMaterial.h"

registerMooseObject("MulticomponentReactiveFlowApp",
                    ADSolidPhaseMassVolumeMaterial);

InputParameters ADSolidPhaseMassVolumeMaterial::validParams() {
  InputParameters params = Material::validParams();
  params.addClassDescription("Computes the constant-density solid constituent "
                             "storage J phi_s rho_s, its "
                             "solid-reference balance residual, and the "
                             "represented-phase volume residual "
                             "phi_s + phi_f - 1.");
  params.addParam<MaterialPropertyName>("jacobian_name", "solid_reference_J",
                                        "Material property name for J.");
  params.addParam<MaterialPropertyName>("jacobian_rate_name",
                                        "solid_reference_J_dot",
                                        "Material property name for dJ/dt.");
  params.addCoupledVar("solid_volume_fraction",
                       "Current matrix volume fraction phi_s for the legacy spatial-primary mode.");
  params.addCoupledVar(
      "reference_component_storage",
      "Conserved solid-reference component storage J phi_s rho_s. Select this instead of "
      "solid_volume_fraction to reconstruct the current matrix fraction.");
  params.addCoupledVar(
      "fluid_volume_fraction",
      "Current total fluid pore fraction phi_f. Required with the legacy spatial solid-fraction "
      "primary and omitted when porosity is reconstructed from conserved reference storage.");
  params.addRequiredRangeCheckedParam<Real>(
      "solid_intrinsic_density", "solid_intrinsic_density>0",
      "Constant matrix intrinsic density, used unless solid_intrinsic_density_variable is "
      "coupled and also used as the default reference intrinsic density.");
  params.addCoupledVar(
      "solid_intrinsic_density_variable",
      "Optional current solid intrinsic density with its material time derivative.");
  params.addCoupledVar(
      "solid_distension",
      "Optional total solid distension used to audit a_s phi_s rho_s0 = J phi_s rho_s.");
  params.addParam<Real>(
      "solid_reference_intrinsic_density", 0.0,
      "Reference intrinsic density rho_s0. A positive value is required when solid_distension "
      "is coupled; zero selects solid_intrinsic_density.");
  params.addParam<MaterialPropertyName>(
      "current_component_source_name", "",
      "Optional current-volume solid-component production rate sum_m "
      "nu_s(m)^alpha rdot_(m).");
  params.addParam<MaterialPropertyName>("reference_component_storage_name",
                                        "solid_reference_component_storage",
                                        "Output name for J phi_s rho_s.");
  params.addParam<MaterialPropertyName>(
      "reference_component_storage_rate_name",
      "solid_reference_component_storage_rate",
      "Output name for d(J phi_s rho_s)/dt.");
  params.addParam<MaterialPropertyName>(
      "reference_component_balance_residual_name",
      "solid_reference_component_balance_residual",
      "Output name for d(J phi_s rho_s)/dt - J c_s.");
  params.addParam<MaterialPropertyName>("phase_volume_constraint_residual_name",
                                        "phase_volume_constraint_residual",
                                        "Output name for phi_s + phi_f - 1.");
  params.addParam<MaterialPropertyName>(
      "current_solid_volume_fraction_name",
      "solid_current_volume_fraction",
      "Output name for the current matrix volume fraction, including its reconstruction "
      "from solid-reference storage when that primary mode is selected.");
  params.addParam<MaterialPropertyName>(
      "current_solid_bulk_density_name", "solid_current_bulk_density",
      "Output current bulk matrix density phi_s rho_s.");
  params.addParam<MaterialPropertyName>(
      "current_fluid_volume_fraction_name",
      "solid_current_porosity",
      "Output name for the current total fluid pore fraction.");
  params.addParam<MaterialPropertyName>(
      "current_fluid_volume_fraction_rate_name",
      "solid_current_porosity_dot",
      "Output name for the material time rate of the current total fluid pore fraction.");
  params.addParam<MaterialPropertyName>(
      "current_solid_intrinsic_density_name", "solid_current_intrinsic_density",
      "Output name for the current solid intrinsic density.");
  params.addParam<MaterialPropertyName>(
      "solid_distension_mass_relation_residual_name",
      "solid_distension_mass_relation_residual",
      "Output name for a_s phi_s rho_s0 - J phi_s rho_s.");
  return params;
}

ADSolidPhaseMassVolumeMaterial::ADSolidPhaseMassVolumeMaterial(
    const InputParameters &parameters)
    : Material(parameters), _J(getADMaterialProperty<Real>("jacobian_name")),
      _J_dot(getADMaterialProperty<Real>("jacobian_rate_name")),
      _solid_volume_fraction(isCoupled("solid_volume_fraction")
                                 ? &adCoupledValue("solid_volume_fraction")
                                 : nullptr),
      _solid_volume_fraction_dot(isCoupled("solid_volume_fraction")
                                     ? &adCoupledDot("solid_volume_fraction")
                                     : nullptr),
      _reference_component_storage_variable(isCoupled("reference_component_storage")
                                                ? &adCoupledValue("reference_component_storage")
                                                : nullptr),
      _reference_component_storage_variable_dot(isCoupled("reference_component_storage")
                                                    ? &adCoupledDot("reference_component_storage")
                                                    : nullptr),
      _fluid_volume_fraction(isCoupled("fluid_volume_fraction")
                                 ? &adCoupledValue("fluid_volume_fraction")
                                 : nullptr),
      _fluid_volume_fraction_dot(isCoupled("fluid_volume_fraction")
                                     ? &adCoupledDot("fluid_volume_fraction")
                                     : nullptr),
      _constant_solid_intrinsic_density(getParam<Real>("solid_intrinsic_density")),
      _solid_intrinsic_density(isCoupled("solid_intrinsic_density_variable")
                                   ? &adCoupledValue("solid_intrinsic_density_variable")
                                   : nullptr),
      _solid_intrinsic_density_dot(isCoupled("solid_intrinsic_density_variable")
                                       ? &adCoupledDot("solid_intrinsic_density_variable")
                                       : nullptr),
      _solid_distension(isCoupled("solid_distension")
                            ? &adCoupledValue("solid_distension")
                            : nullptr),
      _solid_reference_intrinsic_density(
          getParam<Real>("solid_reference_intrinsic_density") > 0.0
              ? getParam<Real>("solid_reference_intrinsic_density")
              : _constant_solid_intrinsic_density),
      _current_component_source(
          getParam<MaterialPropertyName>("current_component_source_name")
                  .empty()
              ? nullptr
              : &getADMaterialProperty<Real>("current_component_source_name")),
      _reference_component_storage(declareADProperty<Real>(
          getParam<MaterialPropertyName>("reference_component_storage_name"))),
      _reference_component_storage_rate(
          declareADProperty<Real>(getParam<MaterialPropertyName>(
              "reference_component_storage_rate_name"))),
      _reference_component_balance_residual(
          declareADProperty<Real>(getParam<MaterialPropertyName>(
              "reference_component_balance_residual_name"))),
      _phase_volume_constraint_residual(
          declareADProperty<Real>(getParam<MaterialPropertyName>(
              "phase_volume_constraint_residual_name"))),
      _current_solid_volume_fraction(
          declareADProperty<Real>(getParam<MaterialPropertyName>(
              "current_solid_volume_fraction_name"))),
      _current_solid_bulk_density(declareADProperty<Real>(
          getParam<MaterialPropertyName>("current_solid_bulk_density_name"))),
      _current_fluid_volume_fraction(
          declareADProperty<Real>(getParam<MaterialPropertyName>(
              "current_fluid_volume_fraction_name"))),
      _current_fluid_volume_fraction_rate(
          declareADProperty<Real>(getParam<MaterialPropertyName>(
              "current_fluid_volume_fraction_rate_name"))),
      _current_solid_intrinsic_density(
          declareADProperty<Real>(getParam<MaterialPropertyName>(
              "current_solid_intrinsic_density_name"))),
      _solid_distension_mass_relation_residual(
          declareADProperty<Real>(getParam<MaterialPropertyName>(
              "solid_distension_mass_relation_residual_name"))) {
  if ((_solid_volume_fraction != nullptr) ==
      (_reference_component_storage_variable != nullptr))
    paramError("solid_volume_fraction",
               "Select exactly one solid primary: solid_volume_fraction or "
               "reference_component_storage.");
  if (_reference_component_storage_variable && _fluid_volume_fraction)
    paramError("fluid_volume_fraction",
               "Omit fluid_volume_fraction when reference_component_storage is the primary; "
               "the complementary pore fraction is reconstructed exactly.");
  if (_solid_volume_fraction && !_fluid_volume_fraction)
    paramError("fluid_volume_fraction",
               "Supply fluid_volume_fraction with the legacy solid_volume_fraction primary.");
  if (_solid_distension && _solid_reference_intrinsic_density <= 0.0)
    paramError("solid_reference_intrinsic_density",
               "The reference solid intrinsic density must be positive.");
}

void ADSolidPhaseMassVolumeMaterial::computeQpProperties() {
  const ADReal current_intrinsic_density =
      _solid_intrinsic_density ? (*_solid_intrinsic_density)[_qp]
                               : _constant_solid_intrinsic_density;
  const ADReal current_intrinsic_density_rate =
      _solid_intrinsic_density_dot ? (*_solid_intrinsic_density_dot)[_qp] : 0.0;
  if (MetaPhysicL::raw_value(_J[_qp]) <= 0.0)
    mooseError(name(), ": solid-reference Jacobian must remain positive.");
  if (MetaPhysicL::raw_value(current_intrinsic_density) <= 0.0)
    mooseError(name(), ": solid intrinsic density must remain positive.");
  _current_solid_intrinsic_density[_qp] = current_intrinsic_density;

  if (_reference_component_storage_variable) {
    _reference_component_storage[_qp] =
        (*_reference_component_storage_variable)[_qp];
    _reference_component_storage_rate[_qp] =
        (*_reference_component_storage_variable_dot)[_qp];
    _current_solid_volume_fraction[_qp] =
        _reference_component_storage[_qp] /
        (current_intrinsic_density * _J[_qp]);
    const ADReal current_solid_volume_fraction_rate =
        _reference_component_storage_rate[_qp] /
            (current_intrinsic_density * _J[_qp]) -
        _reference_component_storage[_qp] * _J_dot[_qp] /
            (current_intrinsic_density * _J[_qp] * _J[_qp]) -
        _reference_component_storage[_qp] * current_intrinsic_density_rate /
            (current_intrinsic_density * current_intrinsic_density * _J[_qp]);
    _current_fluid_volume_fraction[_qp] =
        1.0 - _current_solid_volume_fraction[_qp];
    _current_fluid_volume_fraction_rate[_qp] =
        -current_solid_volume_fraction_rate;
  } else {
    _current_solid_volume_fraction[_qp] = (*_solid_volume_fraction)[_qp];
    _reference_component_storage[_qp] =
        current_intrinsic_density * _J[_qp] * _current_solid_volume_fraction[_qp];
    _reference_component_storage_rate[_qp] =
        current_intrinsic_density_rate * _J[_qp] * _current_solid_volume_fraction[_qp] +
        current_intrinsic_density *
            (_J_dot[_qp] * _current_solid_volume_fraction[_qp] +
             _J[_qp] * (*_solid_volume_fraction_dot)[_qp]);
    _current_fluid_volume_fraction[_qp] = (*_fluid_volume_fraction)[_qp];
    _current_fluid_volume_fraction_rate[_qp] =
        (*_fluid_volume_fraction_dot)[_qp];
  }

  const ADReal current_source =
      _current_component_source ? (*_current_component_source)[_qp] : 0.0;
  _current_solid_bulk_density[_qp] =
      current_intrinsic_density * _current_solid_volume_fraction[_qp];
  _reference_component_balance_residual[_qp] =
      _reference_component_storage_rate[_qp] - _J[_qp] * current_source;
  _phase_volume_constraint_residual[_qp] =
      _current_solid_volume_fraction[_qp] +
      _current_fluid_volume_fraction[_qp] - 1.0;
  _solid_distension_mass_relation_residual[_qp] =
      _solid_distension
          ? (*_solid_distension)[_qp] * _current_solid_volume_fraction[_qp] *
                    _solid_reference_intrinsic_density -
                _reference_component_storage[_qp]
          : 0.0;
}
