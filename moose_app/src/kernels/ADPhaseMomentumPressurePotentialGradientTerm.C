#include "ADPhaseMomentumPressurePotentialGradientTerm.h"

registerMooseObject("MulticomponentReactiveFlowApp",
                    ADPhaseMomentumPressurePotentialGradientTerm);

InputParameters
ADPhaseMomentumPressurePotentialGradientTerm::validParams()
{
  InputParameters params = ADKernelValue::validParams();
  params.addClassDescription(
      "Consumes one assembled reference gradient of p_f-omega_f^+ in a pulled-back phase-"
      "momentum residual. This is the single insertion point for the equivalent-pressure, "
      "surface-energy, and saturation-force contributions. The electric-enthalpy gradient "
      "cancels from this scalar potential, while the anisotropic Maxwell force is a separate "
      "momentum term.");
  params.addRequiredRangeCheckedParam<unsigned int>(
      "component", "component<3", "Cartesian momentum component.");
  params.addRequiredParam<MaterialPropertyName>(
      "phase_momentum_pressure_potential_gradient_name",
      "Assembled reference gradient Grad_X(p_f-omega_f^+).");
  params.addCoupledVar("coefficient_variable", "Optional phase-fraction coefficient field.");
  params.addParam<MaterialPropertyName>("coefficient_name", "", "Optional AD coefficient.");
  params.addParam<Real>("coefficient", 1.0, "Constant coefficient.");
  params.addParam<Real>("scale", 1.0, "Signed term multiplier.");
  params.addParam<MaterialPropertyName>("solid_jacobian_name", "solid_reference_J", "J.");
  params.addParam<MaterialPropertyName>(
      "solid_inverse_deformation_gradient_name", "solid_reference_F_inv", "F^{-1}.");
  return params;
}

ADPhaseMomentumPressurePotentialGradientTerm::ADPhaseMomentumPressurePotentialGradientTerm(
    const InputParameters & parameters)
  : ADKernelValue(parameters),
    _component(getParam<unsigned int>("component")),
    _reference_pressure_potential_gradient(getADMaterialProperty<RealVectorValue>(
        "phase_momentum_pressure_potential_gradient_name")),
    _coefficient_variable(isCoupled("coefficient_variable")
                              ? &adCoupledValue("coefficient_variable")
                              : nullptr),
    _coefficient_property(getParam<MaterialPropertyName>("coefficient_name").empty()
                              ? nullptr
                              : &getADMaterialProperty<Real>("coefficient_name")),
    _coefficient(getParam<Real>("coefficient")),
    _scale(getParam<Real>("scale")),
    _J(getADMaterialProperty<Real>("solid_jacobian_name")),
    _F_inv(getADMaterialProperty<RankTwoTensor>("solid_inverse_deformation_gradient_name"))
{
  if (_component >= _mesh.dimension())
    paramError("component", "component must be smaller than mesh dimension.");
  const unsigned int choices = (_coefficient_variable ? 1 : 0) +
                               (_coefficient_property ? 1 : 0) +
                               (isParamSetByUser("coefficient") ? 1 : 0);
  if (choices > 1)
    paramError("coefficient", "Choose only one coefficient source.");
}

ADReal
ADPhaseMomentumPressurePotentialGradientTerm::precomputeQpResidual()
{
  const ADRealVectorValue current_pressure_potential_gradient =
      _F_inv[_qp].transpose() * _reference_pressure_potential_gradient[_qp];
  const ADReal coefficient = _coefficient_variable
                                 ? (*_coefficient_variable)[_qp]
                                 : (_coefficient_property ? (*_coefficient_property)[_qp]
                                                          : ADReal(_coefficient));
  return _J[_qp] * _scale * coefficient * current_pressure_potential_gradient(_component);
}
