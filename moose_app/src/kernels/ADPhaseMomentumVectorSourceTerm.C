#include "ADPhaseMomentumVectorSourceTerm.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADPhaseMomentumVectorSourceTerm);

InputParameters
ADPhaseMomentumVectorSourceTerm::validParams()
{
  InputParameters params = ADKernelValue::validParams();
  params.addClassDescription(
      "Atomic -test*J*b_i source. Instantiate for gravity (rho*g), pairwise interaction, "
      "external body force, electro-osmotic force, or other current-volume momentum supplies.");
  params.addRequiredRangeCheckedParam<unsigned int>("component", "component<3",
                                                     "Momentum component.");
  params.addRequiredParam<MaterialPropertyName>("source_name", "AD current-volume vector source.");
  params.addParam<Real>("scale", 1.0, "Signed source multiplier.");
  params.addParam<MaterialPropertyName>("solid_jacobian_name", "solid_reference_J", "J.");
  return params;
}

ADPhaseMomentumVectorSourceTerm::ADPhaseMomentumVectorSourceTerm(
    const InputParameters & parameters)
  : ADKernelValue(parameters),
    _component(getParam<unsigned int>("component")),
    _source(getADMaterialProperty<RealVectorValue>("source_name")),
    _J(getADMaterialProperty<Real>("solid_jacobian_name")),
    _scale(getParam<Real>("scale"))
{
  if (_component >= _mesh.dimension())
    paramError("component", "component must be smaller than mesh dimension.");
}

ADReal
ADPhaseMomentumVectorSourceTerm::precomputeQpResidual()
{
  return -_J[_qp] * _scale * _source[_qp](_component);
}
