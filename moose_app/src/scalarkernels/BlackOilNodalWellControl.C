#include "BlackOilNodalWellControl.h"

#include "Assembly.h"

#include <cmath>

registerMooseObject("MulticomponentReactiveFlowApp", BlackOilNodalWellControl);

InputParameters
BlackOilNodalWellControl::validParams()
{
  InputParameters params = NodalScalarKernel::validParams();
  params.addClassDescription(
      "Enforces a completion-averaged surface rate with one scalar BHP and optional "
      "rate/BHP complementarity.");
  params.addRequiredCoupledVar("pressure", "Continuous completion-cell pressure backbone.");
  params.addRequiredParam<PostprocessorName>("surface_rate", "Exact completion-averaged surface rate.");
  params.addRequiredParam<PostprocessorName>(
      "surface_productivity", "Completion-averaged surface productivity.");
  params.addRequiredParam<Real>("target_surface_rate", "Signed surface-rate target.");
  params.addParam<bool>("apply_bhp_limit", false, "Apply a minimum or maximum BHP limit.");
  params.addParam<MooseEnum>(
      "bhp_limit_type", MooseEnum("minimum maximum", "minimum"), "Type of BHP limit.");
  params.addParam<Real>("bhp_limit", 0.0, "BHP limit.");
  return params;
}

BlackOilNodalWellControl::BlackOilNodalWellControl(const InputParameters & parameters)
  : NodalScalarKernel(parameters),
    _pressure_var(coupled("pressure")),
    _pressure(coupledValue("pressure")),
    _surface_rate(getPostprocessorValue("surface_rate")),
    _surface_productivity(getPostprocessorValue("surface_productivity")),
    _target_surface_rate(getParam<Real>("target_surface_rate")),
    _apply_bhp_limit(getParam<bool>("apply_bhp_limit")),
    _bhp_limit_type(getParam<MooseEnum>("bhp_limit_type")),
    _bhp_limit(getParam<Real>("bhp_limit"))
{
  if (_var.order() != 1)
    paramError("variable", "Use a FIRST-order scalar BHP variable.");
  if (_node_ids.empty())
    paramError("nodes", "Supply the completion-cell node ids.");
}

void
BlackOilNodalWellControl::residualDerivatives(Real & residual,
                                              Real & derivative_rate,
                                              Real & derivative_bhp) const
{
  const Real rate = _surface_rate;
  const Real rate_bhp_derivative = -_surface_productivity;

  if (!_apply_bhp_limit)
  {
    residual = rate - _target_surface_rate;
    derivative_rate = 1.0;
    derivative_bhp = rate_bhp_derivative;
    return;
  }

  const bool minimum = _bhp_limit_type == "minimum";
  const Real a = minimum ? _target_surface_rate - rate : rate - _target_surface_rate;
  const Real b = minimum ? _u[0] - _bhp_limit : _bhp_limit - _u[0];
  const Real norm = std::sqrt(a * a + b * b);
  residual = norm - a - b;

  const Real derivative_residual_a = norm == 0.0 ? -1.0 : a / norm - 1.0;
  const Real derivative_residual_b = norm == 0.0 ? -1.0 : b / norm - 1.0;
  const Real derivative_a_rate = minimum ? -1.0 : 1.0;
  const Real derivative_b_bhp = minimum ? 1.0 : -1.0;
  derivative_rate = derivative_residual_a * derivative_a_rate;
  derivative_bhp = derivative_rate * rate_bhp_derivative +
                   derivative_residual_b * derivative_b_bhp;
}

void
BlackOilNodalWellControl::computeResidual()
{
  prepareVectorTag(_assembly, _var.number());
  Real derivative_rate;
  Real derivative_bhp;
  residualDerivatives(_local_re(0), derivative_rate, derivative_bhp);
  assignTaggedLocalResidual();
}

void
BlackOilNodalWellControl::computeJacobian()
{
  Real residual;
  Real derivative_rate;
  Real derivative_bhp;
  residualDerivatives(residual, derivative_rate, derivative_bhp);

  prepareMatrixTag(_assembly, _var.number(), _var.number());
  _local_ke(0, 0) = derivative_bhp;
  assignTaggedLocalMatrix();

  prepareMatrixTag(_assembly, _var.number(), _pressure_var);
  const Real derivative_pressure_node =
      derivative_rate * _surface_productivity / _pressure.size();
  for (unsigned int j = 0; j < _local_ke.n(); ++j)
    _local_ke(0, j) = derivative_pressure_node;
  assignTaggedLocalMatrix();
}
