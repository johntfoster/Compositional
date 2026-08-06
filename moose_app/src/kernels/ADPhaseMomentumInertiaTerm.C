#include "ADPhaseMomentumInertiaTerm.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADPhaseMomentumInertiaTerm);

InputParameters
ADPhaseMomentumInertiaTerm::validParams()
{
  InputParameters params = ADTimeKernel::validParams();
  params.addClassDescription(
      "Atomic pulled-back phase material-acceleration term from "
      "Eqs. (el_mom_f_dynamic_capillary) and (solid_reference_overall_momentum).");
  params.addRequiredRangeCheckedParam<unsigned int>("component", "component<3",
                                                     "Momentum component.");
  params.addRequiredCoupledVar("phase_velocity", "All phase velocity components.");
  params.addRequiredCoupledVar("solid_displacements", "All skeleton displacement components.");
  params.addRequiredCoupledVar("bulk_density", "Current bulk phase density.");
  params.addParam<MaterialPropertyName>("solid_jacobian_name", "solid_reference_J", "J.");
  params.addParam<MaterialPropertyName>(
      "solid_inverse_deformation_gradient_name", "solid_reference_F_inv", "F^{-1}.");
  return params;
}

ADPhaseMomentumInertiaTerm::ADPhaseMomentumInertiaTerm(const InputParameters & parameters)
  : ADTimeKernel(parameters),
    _component(getParam<unsigned int>("component")),
    _dim(_mesh.dimension()),
    _bulk_density(adCoupledValue("bulk_density")),
    _J(getADMaterialProperty<Real>("solid_jacobian_name")),
    _F_inv(getADMaterialProperty<RankTwoTensor>("solid_inverse_deformation_gradient_name"))
{
  if (_component >= _dim)
    paramError("component", "component must be smaller than mesh dimension.");
  if (coupledComponents("phase_velocity") != _dim ||
      coupledComponents("solid_displacements") != _dim)
    paramError("phase_velocity", "Provide exactly dim phase velocities and displacements.");
  for (const auto i : make_range(_dim))
  {
    _phase_velocities.push_back(&adCoupledValue("phase_velocity", i));
    _solid_velocities.push_back(&adCoupledDot("solid_displacements", i));
  }
}

ADReal
ADPhaseMomentumInertiaTerm::computeQpResidual()
{
  ADRealVectorValue relative_velocity;
  for (const auto i : make_range(_dim))
    relative_velocity(i) = (*_phase_velocities[i])[_qp] - (*_solid_velocities[i])[_qp];
  const ADRealVectorValue reference_convective_velocity = _F_inv[_qp] * relative_velocity;
  const ADReal acceleration = _u_dot[_qp] + reference_convective_velocity * _grad_u[_qp];
  return _test[_i][_qp] * _J[_qp] * _bulk_density[_qp] * acceleration;
}
