#include "ADPhaseElectricEnthalpyMaterial.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADPhaseElectricEnthalpyMaterial);

InputParameters
ADPhaseElectricEnthalpyMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Computes d_xi=-partial(omega_xi^+)/partial(E), the complete phase electrical Cauchy "
      "stress phi_xi (omega_xi^+ I + E tensor d_xi), and its solid-reference Piola "
      "pull-back. The enthalpy and derivatives may be supplied by ADDerivativeParsedMaterial.");
  params.addRequiredParam<std::string>("phase", "Phase-name prefix for output properties.");
  params.addRequiredCoupledVar("electric_field", "All spatial electric-field components.");
  params.addRequiredCoupledVar("phase_fraction", "Phase volume fraction phi_xi.");
  params.addRequiredParam<MaterialPropertyName>(
      "electric_enthalpy_name", "Phase electric-enthalpy density omega_xi^+.");
  params.addRequiredParam<std::vector<MaterialPropertyName>>(
      "electric_enthalpy_field_derivative_names",
      "Properties partial(omega_xi^+)/partial(E_i), in spatial component order.");
  params.addParam<MaterialPropertyName>("solid_jacobian_name", "solid_reference_J", "J.");
  params.addParam<MaterialPropertyName>(
      "solid_inverse_deformation_gradient_name", "solid_reference_F_inv", "F^{-1}.");
  params.addParam<MaterialPropertyName>("electric_displacement_name", "",
                                        "Output d_xi; defaults to <phase>_electric_displacement.");
  params.addParam<MaterialPropertyName>("maxwell_cauchy_stress_name", "",
                                        "Output phi (omega I + E tensor d) Cauchy stress.");
  params.addParam<MaterialPropertyName>("maxwell_piola_stress_name", "",
                                        "Output J phi (omega I + E tensor d) F^{-T}.");
  return params;
}

ADPhaseElectricEnthalpyMaterial::ADPhaseElectricEnthalpyMaterial(
    const InputParameters & parameters)
  : Material(parameters),
    _phase(getParam<std::string>("phase")),
    _dim(_mesh.dimension()),
    _phase_fraction(adCoupledValue("phase_fraction")),
    _electric_enthalpy(getADMaterialProperty<Real>("electric_enthalpy_name")),
    _J(getADMaterialProperty<Real>("solid_jacobian_name")),
    _F_inv(getADMaterialProperty<RankTwoTensor>("solid_inverse_deformation_gradient_name")),
    _electric_displacement(declareADProperty<RealVectorValue>(
        getParam<MaterialPropertyName>("electric_displacement_name").empty()
            ? MaterialPropertyName(_phase + "_electric_displacement")
            : getParam<MaterialPropertyName>("electric_displacement_name"))),
    _maxwell_cauchy_stress(declareADProperty<RankTwoTensor>(
        getParam<MaterialPropertyName>("maxwell_cauchy_stress_name").empty()
            ? MaterialPropertyName(_phase + "_maxwell_cauchy_stress")
            : getParam<MaterialPropertyName>("maxwell_cauchy_stress_name"))),
    _maxwell_piola_stress(declareADProperty<RankTwoTensor>(
        getParam<MaterialPropertyName>("maxwell_piola_stress_name").empty()
            ? MaterialPropertyName(_phase + "_maxwell_piola_stress")
            : getParam<MaterialPropertyName>("maxwell_piola_stress_name")))
{
  if (_phase.empty())
    paramError("phase", "phase must be nonempty.");
  if (coupledComponents("electric_field") != _dim)
    paramError("electric_field", "Provide exactly dim electric-field components.");
  const auto names =
      getParam<std::vector<MaterialPropertyName>>("electric_enthalpy_field_derivative_names");
  if (names.size() != _dim)
    paramError("electric_enthalpy_field_derivative_names",
               "Supply exactly dim electric-enthalpy field derivatives.");
  for (const auto i : make_range(_dim))
  {
    _electric_field.push_back(&adCoupledValue("electric_field", i));
    _enthalpy_field_derivatives.push_back(&getADMaterialProperty<Real>(names[i]));
  }
}

void
ADPhaseElectricEnthalpyMaterial::computeQpProperties()
{
  ADRealVectorValue E;
  _electric_displacement[_qp].zero();
  _maxwell_cauchy_stress[_qp].zero();
  for (const auto i : make_range(_dim))
  {
    E(i) = (*_electric_field[i])[_qp];
    _electric_displacement[_qp](i) = -(*_enthalpy_field_derivatives[i])[_qp];
  }
  for (const auto i : make_range(_dim))
    for (const auto j : make_range(_dim))
      _maxwell_cauchy_stress[_qp](i, j) =
          _phase_fraction[_qp] *
          ((i == j ? _electric_enthalpy[_qp] : ADReal(0.0)) +
           E(i) * _electric_displacement[_qp](j));
  _maxwell_piola_stress[_qp] =
      _J[_qp] * _maxwell_cauchy_stress[_qp] * _F_inv[_qp].transpose();
}

