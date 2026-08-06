#include "ADMixtureElectricFieldMaterial.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADMixtureElectricFieldMaterial);

InputParameters
ADMixtureElectricFieldMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Computes d=sum_xi phi_xi d_xi, D=J F^{-1}d, varrho=sum rho_xi^alpha z_xi^alpha, "
      "and J varrho for Gauss law and the global electrostatic power identity.");
  params.addRequiredCoupledVar("phase_fractions", "Phase volume fractions in phase order.");
  params.addRequiredParam<std::vector<MaterialPropertyName>>(
      "phase_electric_displacement_names", "Phase d_xi properties in the same order.");
  params.addCoupledVar("charged_component_densities",
                       "Optional current partial component densities rho_xi^alpha.");
  params.addParam<std::vector<Real>>(
      "specific_charges", {}, "Specific charge z_xi^alpha matching charged component densities.");
  params.addParam<MaterialPropertyName>("solid_jacobian_name", "solid_reference_J", "J.");
  params.addParam<MaterialPropertyName>(
      "solid_inverse_deformation_gradient_name", "solid_reference_F_inv", "F^{-1}.");
  params.addParam<MaterialPropertyName>("mixture_electric_displacement_name",
                                        "mixture_electric_displacement", "Output d.");
  params.addParam<MaterialPropertyName>("reference_electric_displacement_name",
                                        "reference_electric_displacement", "Output D.");
  params.addParam<MaterialPropertyName>("current_free_charge_name", "current_free_charge",
                                        "Output varrho.");
  params.addParam<MaterialPropertyName>("reference_free_charge_name", "reference_free_charge",
                                        "Output J varrho.");
  return params;
}

ADMixtureElectricFieldMaterial::ADMixtureElectricFieldMaterial(
    const InputParameters & parameters)
  : Material(parameters),
    _specific_charges(getParam<std::vector<Real>>("specific_charges")),
    _J(getADMaterialProperty<Real>("solid_jacobian_name")),
    _F_inv(getADMaterialProperty<RankTwoTensor>("solid_inverse_deformation_gradient_name")),
    _mixture_displacement(declareADProperty<RealVectorValue>(
        getParam<MaterialPropertyName>("mixture_electric_displacement_name"))),
    _reference_displacement(declareADProperty<RealVectorValue>(
        getParam<MaterialPropertyName>("reference_electric_displacement_name"))),
    _current_free_charge(
        declareADProperty<Real>(getParam<MaterialPropertyName>("current_free_charge_name"))),
    _reference_free_charge(
        declareADProperty<Real>(getParam<MaterialPropertyName>("reference_free_charge_name")))
{
  const auto displacement_names =
      getParam<std::vector<MaterialPropertyName>>("phase_electric_displacement_names");
  if (coupledComponents("phase_fractions") == 0 ||
      coupledComponents("phase_fractions") != displacement_names.size())
    paramError("phase_electric_displacement_names",
               "Supply one phase electric displacement per phase fraction.");
  for (const auto p : make_range(displacement_names.size()))
  {
    _phase_fractions.push_back(&adCoupledValue("phase_fractions", p));
    _phase_displacements.push_back(
        &getADMaterialProperty<RealVectorValue>(displacement_names[p]));
  }

  if (isCoupled("charged_component_densities") &&
      coupledComponents("charged_component_densities") != _specific_charges.size())
    paramError("specific_charges",
               "Supply one specific charge per charged component density.");
  if (!isCoupled("charged_component_densities") && !_specific_charges.empty())
    paramError("specific_charges",
               "Do not supply specific charges without charged component densities.");
  for (const auto c : make_range(coupledComponents("charged_component_densities")))
    _component_densities.push_back(&adCoupledValue("charged_component_densities", c));
}

void
ADMixtureElectricFieldMaterial::computeQpProperties()
{
  _mixture_displacement[_qp].zero();
  for (const auto p : make_range(_phase_fractions.size()))
    _mixture_displacement[_qp] +=
        (*_phase_fractions[p])[_qp] * (*_phase_displacements[p])[_qp];
  _reference_displacement[_qp] = _J[_qp] * _F_inv[_qp] * _mixture_displacement[_qp];

  _current_free_charge[_qp] = 0.0;
  for (const auto c : make_range(_component_densities.size()))
    _current_free_charge[_qp] +=
        _specific_charges[c] * (*_component_densities[c])[_qp];
  _reference_free_charge[_qp] = _J[_qp] * _current_free_charge[_qp];
}
