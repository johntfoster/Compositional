#include "ADSolidDistensionEvolution.h"

#include "Function.h"
#include "metaphysicl/raw_type.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADSolidDistensionEvolution);

InputParameters
ADSolidDistensionEvolution::validParams()
{
  InputParameters params = ADTimeKernel::validParams();
  params.addClassDescription(
      "Implements manuscript Eq. (MC_solid_distension_evolution): "
      "dot(a_s)/a_s-dot(J)/J-dot(rhobar_s)/rhobar_s=0 on the solid reference.");
  params.addParam<MaterialPropertyName>(
      "solid_jacobian_name", "solid_reference_J", "Solid-reference Jacobian J=det(F).");
  params.addParam<MaterialPropertyName>(
      "solid_jacobian_rate_name",
      "solid_reference_J_dot",
      "Material time rate of the solid-reference Jacobian.");
  params.addRequiredCoupledVar("intrinsic_density", "Positive solid intrinsic density rhobar_s.");
  params.addParam<FunctionName>("forcing", "0", "Manufactured rate forcing with units 1/time.");
  return params;
}

ADSolidDistensionEvolution::ADSolidDistensionEvolution(const InputParameters & parameters)
  : ADTimeKernel(parameters),
    _solid_jacobian(getADMaterialProperty<Real>("solid_jacobian_name")),
    _solid_jacobian_dot(getADMaterialProperty<Real>("solid_jacobian_rate_name")),
    _intrinsic_density(adCoupledValue("intrinsic_density")),
    _intrinsic_density_dot(adCoupledDot("intrinsic_density")),
    _forcing(getFunction("forcing"))
{
}

ADReal
ADSolidDistensionEvolution::computeQpResidual()
{
  if (MetaPhysicL::raw_value(_u[_qp]) <= 0.0)
    mooseError(name(), ": solid distension must remain positive.");
  if (MetaPhysicL::raw_value(_intrinsic_density[_qp]) <= 0.0)
    mooseError(name(), ": solid intrinsic density must remain positive.");
  if (MetaPhysicL::raw_value(_solid_jacobian[_qp]) <= 0.0)
    mooseError(name(), ": solid-reference Jacobian must remain positive.");

  return _test[_i][_qp] *
         (_u_dot[_qp] / _u[_qp] - _solid_jacobian_dot[_qp] / _solid_jacobian[_qp] -
          _intrinsic_density_dot[_qp] / _intrinsic_density[_qp] -
          _forcing.value(_t, _q_point[_qp]));
}
