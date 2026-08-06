#include "ADGeneralizedTransferWorkMaterial.h"

registerMooseObject("MulticomponentReactiveFlowApp",
                    ADGeneralizedTransferWorkMaterial);

InputParameters ADGeneralizedTransferWorkMaterial::validParams() {
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Composes the manuscript phase/component transfer work L_xi^alpha = "
      "hat_mu_xi^alpha - psi_xi + D_xi(tau)/Dt - |v_xi|^2/2 from selectable AD "
      "material properties, and optionally exposes the neutral coefficient psi_xi + L_xi^alpha "
      "used by the temperature-weighted reaction law.");
  params.addRequiredParam<MaterialPropertyName>("chemical_potential_name",
                                                "hat_mu_xi^alpha.");
  params.addRequiredParam<MaterialPropertyName>("specific_helmholtz_name",
                                                "psi_xi.");
  params.addRequiredParam<MaterialPropertyName>("tau_transfer_offset_name",
                                                "D_xi(tau)/Dt - |v_xi|^2/2.");
  params.addRequiredParam<MaterialPropertyName>(
      "generalized_transfer_work_name", "Output L_xi^alpha property name.");
  params.addParam<MaterialPropertyName>(
      "neutral_conversion_coefficient_name",
      "",
      "Optional output property name for psi_xi + L_xi^alpha = hat_mu_xi^alpha + "
      "D_xi(tau)/Dt - |v_xi|^2/2.");
  return params;
}

ADGeneralizedTransferWorkMaterial::ADGeneralizedTransferWorkMaterial(
    const InputParameters &parameters)
    : Material(parameters), _chemical_potential(getADMaterialProperty<Real>(
                                "chemical_potential_name")),
      _specific_helmholtz(
          getADMaterialProperty<Real>("specific_helmholtz_name")),
      _tau_transfer_offset(
          getADMaterialProperty<Real>("tau_transfer_offset_name")),
      _generalized_transfer_work(declareADProperty<Real>(
          getParam<MaterialPropertyName>("generalized_transfer_work_name"))),
      _neutral_conversion_coefficient(
          getParam<MaterialPropertyName>("neutral_conversion_coefficient_name").empty()
              ? nullptr
              : &declareADProperty<Real>(
                    getParam<MaterialPropertyName>("neutral_conversion_coefficient_name"))) {}

void ADGeneralizedTransferWorkMaterial::computeQpProperties() {
  _generalized_transfer_work[_qp] = _chemical_potential[_qp] -
                                    _specific_helmholtz[_qp] +
                                    _tau_transfer_offset[_qp];
  if (_neutral_conversion_coefficient)
    (*_neutral_conversion_coefficient)[_qp] =
        _chemical_potential[_qp] + _tau_transfer_offset[_qp];
}

