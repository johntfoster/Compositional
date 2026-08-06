#include "ADPhaseMomentumStressTerm.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADPhaseMomentumStressTerm);

InputParameters
ADPhaseMomentumStressTerm::validParams()
{
  InputParameters params = ADKernel::validParams();
  params.addClassDescription(
      "Atomic +Grad(test):P term. Use separate instances for material stress, Biot pressure "
      "stress, phase or mixture Maxwell stress, and other reversible stresses.");
  params.addRequiredRangeCheckedParam<unsigned int>("component", "component<3",
                                                     "Momentum component.");
  params.addRequiredParam<MaterialPropertyName>("piola_stress_name",
                                                 "AD first-Piola stress property.");
  params.addParam<Real>("scale", 1.0, "Signed stress multiplier.");
  return params;
}

ADPhaseMomentumStressTerm::ADPhaseMomentumStressTerm(const InputParameters & parameters)
  : ADKernel(parameters),
    _component(getParam<unsigned int>("component")),
    _piola_stress(getADMaterialProperty<RankTwoTensor>("piola_stress_name")),
    _scale(getParam<Real>("scale"))
{
  if (_component >= _mesh.dimension())
    paramError("component", "component must be smaller than mesh dimension.");
}

ADReal
ADPhaseMomentumStressTerm::computeQpResidual()
{
  ADReal residual = 0.0;
  for (const auto j : make_range(_mesh.dimension()))
    residual += _grad_test[_i][_qp](j) * _piola_stress[_qp](_component, j);
  return _scale * residual;
}
