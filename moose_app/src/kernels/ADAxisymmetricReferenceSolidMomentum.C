#include "ADAxisymmetricReferenceSolidMomentum.h"

#include "Function.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADAxisymmetricReferenceSolidMomentum);

InputParameters
ADAxisymmetricReferenceSolidMomentum::validParams()
{
  InputParameters params = ADKernel::validParams();
  params += FunctionInterface::validParams();
  params.addClassDescription(
      "Quasi-static solid-reference momentum in axisymmetric RZ coordinates, including the "
      "radial test/R times P_thetaTheta contribution.");
  params.addRequiredRangeCheckedParam<unsigned int>(
      "component", "component<2", "Momentum component: 0 radial or 1 axial.");
  params.addParam<MaterialPropertyName>(
      "first_piola_stress_name",
      "reference_solid_total_first_piola",
      "Material property for the total first Piola stress in radial-axial-circumferential order.");
  params.addParam<MaterialPropertyName>("solid_jacobian_name",
                                        "solid_reference_J",
                                        "Material property name for J.");
  params.addCoupledVar(
      "current_volume_force",
      "Optional radial and axial current-volume force components; the kernel multiplies them by J.");
  params.addParam<FunctionName>(
      "reference_body_force",
      "0",
      "Reference-volume force component b_0 appearing in Div_X P + b_0 = 0.");
  return params;
}

ADAxisymmetricReferenceSolidMomentum::ADAxisymmetricReferenceSolidMomentum(
    const InputParameters & parameters)
  : ADKernel(parameters),
    _component(getParam<unsigned int>("component")),
    _first_piola_stress(getADMaterialProperty<RankTwoTensor>("first_piola_stress_name")),
    _solid_J(getADMaterialProperty<Real>("solid_jacobian_name")),
    _reference_body_force(getFunction("reference_body_force"))
{
  if (isCoupled("current_volume_force") && coupledComponents("current_volume_force") != 2)
    paramError("current_volume_force", "Provide exactly two current-volume force components.");

  _current_volume_force.reserve(2);
  if (isCoupled("current_volume_force"))
    for (const auto i : make_range(2))
      _current_volume_force.push_back(&adCoupledValue("current_volume_force", i));
}

void
ADAxisymmetricReferenceSolidMomentum::initialSetup()
{
  if (_mesh.dimension() != 2)
    mooseError("ADAxisymmetricReferenceSolidMomentum requires a two-dimensional mesh.");
  if (getBlockCoordSystem() != Moose::COORD_RZ)
    mooseError("ADAxisymmetricReferenceSolidMomentum requires coord_type = RZ.");
  if (_mesh.getAxisymmetricRadialCoord() != 0)
    mooseError("ADAxisymmetricReferenceSolidMomentum requires coordinate 0 to be radial.");
}

ADReal
ADAxisymmetricReferenceSolidMomentum::computeQpResidual()
{
  ADReal residual = _grad_test[_i][_qp](0) * _first_piola_stress[_qp](_component, 0) +
                    _grad_test[_i][_qp](1) * _first_piola_stress[_qp](_component, 1);

  if (_component == 0)
    residual +=
        _test[_i][_qp] / _ad_q_point[_qp](0) * _first_piola_stress[_qp](2, 2);

  ADReal reference_force = _reference_body_force.value(_t, _q_point[_qp]);
  if (!_current_volume_force.empty())
    reference_force += _solid_J[_qp] * (*_current_volume_force[_component])[_qp];

  return residual - _test[_i][_qp] * reference_force;
}
