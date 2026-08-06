#include "ADElectricFieldPotentialConstraint.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADElectricFieldPotentialConstraint);

InputParameters
ADElectricFieldPotentialConstraint::validParams()
{
  InputParameters params = ADKernelValue::validParams();
  params.addClassDescription(
      "Atomic electroquasistatic kinematic constraint E_i+(F^{-T}Grad_X(varphi))_i=0. "
      "Solving E components separately permits arbitrary input-deck electric-enthalpy functions.");
  params.addRequiredRangeCheckedParam<unsigned int>("component", "component<3",
                                                     "Electric-field component.");
  params.addRequiredCoupledVar("electric_potential", "Shared electrostatic potential varphi.");
  params.addParam<MaterialPropertyName>(
      "solid_inverse_deformation_gradient_name", "solid_reference_F_inv", "F^{-1}.");
  return params;
}

ADElectricFieldPotentialConstraint::ADElectricFieldPotentialConstraint(
    const InputParameters & parameters)
  : ADKernelValue(parameters),
    _component(getParam<unsigned int>("component")),
    _potential_gradient(adCoupledGradient("electric_potential")),
    _F_inv(getADMaterialProperty<RankTwoTensor>("solid_inverse_deformation_gradient_name"))
{
  if (_component >= _mesh.dimension())
    paramError("component", "component must be smaller than mesh dimension.");
}

ADReal
ADElectricFieldPotentialConstraint::precomputeQpResidual()
{
  const ADRealVectorValue current_potential_gradient =
      _F_inv[_qp].transpose() * _potential_gradient[_qp];
  return _u[_qp] + current_potential_gradient(_component);
}
