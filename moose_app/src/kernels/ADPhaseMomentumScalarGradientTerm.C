#include "ADPhaseMomentumScalarGradientTerm.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADPhaseMomentumScalarGradientTerm);

InputParameters
ADPhaseMomentumScalarGradientTerm::validParams()
{
  InputParameters params = ADKernel::validParams();
  params.addClassDescription(
      "Atomic pulled-back scalar-gradient force. Instantiate for equivalent pressure, stored "
      "capillary pressure, dynamic pressure lag, or electric-enthalpy pressure reconstruction.");
  params.addRequiredRangeCheckedParam<unsigned int>("component", "component<3",
                                                     "Momentum component.");
  params.addRequiredCoupledVar("potential", "CG scalar potential.");
  params.addCoupledVar("potential_enrichment", "Optional EG P0 enrichment.");
  params.addCoupledVar("coefficient_variable", "Optional scalar coefficient field.");
  params.addParam<MaterialPropertyName>("coefficient_name", "", "Optional AD coefficient.");
  params.addParam<Real>("coefficient", 1.0, "Constant coefficient.");
  params.addParam<Real>("scale", 1.0, "Signed term multiplier.");
  params.addParam<MaterialPropertyName>("solid_jacobian_name", "solid_reference_J", "J.");
  params.addParam<MaterialPropertyName>(
      "solid_inverse_deformation_gradient_name", "solid_reference_F_inv", "F^{-1}.");
  return params;
}

ADPhaseMomentumScalarGradientTerm::ADPhaseMomentumScalarGradientTerm(
    const InputParameters & parameters)
  : ADKernel(parameters),
    _component(getParam<unsigned int>("component")),
    _gradient(adCoupledGradient("potential")),
    _enrichment_gradient(isCoupled("potential_enrichment")
                             ? &adCoupledGradient("potential_enrichment")
                             : nullptr),
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
  const unsigned int choices = (_coefficient_variable ? 1 : 0) + (_coefficient_property ? 1 : 0) +
                               (isParamSetByUser("coefficient") ? 1 : 0);
  if (choices > 1)
    paramError("coefficient", "Choose only one coefficient source.");
}

ADReal
ADPhaseMomentumScalarGradientTerm::computeQpResidual()
{
  ADRealVectorValue reference_gradient = _gradient[_qp];
  if (_enrichment_gradient)
    reference_gradient += (*_enrichment_gradient)[_qp];
  const ADRealVectorValue current_gradient = _F_inv[_qp].transpose() * reference_gradient;
  const ADReal coefficient = _coefficient_variable
                                 ? (*_coefficient_variable)[_qp]
                                 : (_coefficient_property ? (*_coefficient_property)[_qp]
                                                          : ADReal(_coefficient));
  return _test[_i][_qp] * _J[_qp] * _scale * coefficient * current_gradient(_component);
}
