#include "BlackOilMultiCompletionWellControl.h"

#include "Assembly.h"
#include "Function.h"

#include <algorithm>
#include <cmath>

registerMooseObject("MulticomponentReactiveFlowApp", BlackOilMultiCompletionWellControl);

InputParameters
BlackOilMultiCompletionWellControl::validParams()
{
  InputParameters params = NodalScalarKernel::validParams();
  params.addClassDescription(
      "Enforces a sum of completion surface rates with one datum BHP, completion-specific "
      "productivities and pressure Jacobian weights, and optional rate/BHP complementarity.");
  params.addRequiredCoupledVar("pressure", "Continuous completion-cell pressure backbone.");
  params.addRequiredParam<std::vector<PostprocessorName>>(
      "surface_rates", "One completion-averaged surface rate per boundary.");
  params.addRequiredParam<std::vector<PostprocessorName>>(
      "surface_productivities", "One completion-averaged surface productivity per boundary.");
  params.addRequiredParam<std::vector<BoundaryName>>(
      "completion_boundaries",
      "One node boundary per completion; boundaries may overlap and must be contained in the "
      "NodalScalarKernel boundary union.");
  params.addRequiredParam<Real>("target_surface_rate", "Constant total signed surface-rate target.");
  params.addParam<FunctionName>(
      "target_surface_rate_function",
      "",
      "Optional time-dependent total signed surface-rate target; when supplied, it overrides "
      "target_surface_rate.");
  params.addParam<bool>("apply_bhp_limit", false, "Apply a minimum or maximum datum-BHP limit.");
  params.addParam<MooseEnum>("bhp_limit_type", MooseEnum("minimum maximum", "minimum"),
                             "Type of datum-BHP limit.");
  params.addParam<Real>("bhp_limit", 0.0, "Datum-BHP limit.");
  return params;
}

BlackOilMultiCompletionWellControl::BlackOilMultiCompletionWellControl(
    const InputParameters & parameters)
  : NodalScalarKernel(parameters),
    _pressure_var(coupled("pressure")),
    _pressure(coupledValue("pressure")),
    _target_surface_rate(getParam<Real>("target_surface_rate")),
    _target_surface_rate_function(
        getParam<FunctionName>("target_surface_rate_function").empty()
            ? nullptr
            : &getFunction("target_surface_rate_function")),
    _apply_bhp_limit(getParam<bool>("apply_bhp_limit")),
    _bhp_limit_type(getParam<MooseEnum>("bhp_limit_type")),
    _bhp_limit(getParam<Real>("bhp_limit"))
{
  if (_var.order() != 1)
    paramError("variable", "Use a FIRST-order scalar datum-BHP variable.");
  if (_node_ids.empty())
    paramError("boundary", "Supply a boundary containing the union of all completion nodes.");

  const auto rate_names = getParam<std::vector<PostprocessorName>>("surface_rates");
  const auto productivity_names =
      getParam<std::vector<PostprocessorName>>("surface_productivities");
  const auto completion_boundaries =
      getParam<std::vector<BoundaryName>>("completion_boundaries");
  const auto completion_count = completion_boundaries.size();
  if (completion_count == 0)
    paramError("completion_boundaries", "Supply at least one completion boundary.");
  if (rate_names.size() != completion_count)
    paramError("surface_rates", "Supply one surface-rate postprocessor per completion boundary.");
  if (productivity_names.size() != completion_count)
    paramError("surface_productivities",
               "Supply one productivity postprocessor per completion boundary.");

  for (const auto & name : rate_names)
    _surface_rates.push_back(&getPostprocessorValueByName(name));
  for (const auto & name : productivity_names)
    _surface_productivities.push_back(&getPostprocessorValueByName(name));
  for (const auto & boundary_name : completion_boundaries)
  {
    const auto nodes = _mesh.getNodeList(_mesh.getBoundaryID(boundary_name));
    if (nodes.empty())
      paramError("completion_boundaries",
                 "Every completion boundary must contain at least one node.");
    std::vector<Real> weights(_node_ids.size(), 0.0);
    for (const auto node_id : nodes)
    {
      const auto position = std::find(_node_ids.begin(), _node_ids.end(), node_id);
      if (position == _node_ids.end())
        paramError("completion_boundaries",
                   "Every completion node must belong to the boundary union.");
      weights[std::distance(_node_ids.begin(), position)] += 1.0 / nodes.size();
    }
    _completion_pressure_weights.push_back(std::move(weights));
  }
}

void
BlackOilMultiCompletionWellControl::residualDerivatives(Real & residual,
                                                         Real & derivative_rate,
                                                         Real & derivative_bhp) const
{
  Real total_rate = 0.0;
  Real total_productivity = 0.0;
  for (const auto * rate : _surface_rates)
    total_rate += *rate;
  for (const auto * productivity : _surface_productivities)
    total_productivity += *productivity;

  const Real rate_bhp_derivative = -total_productivity;
  const Real target_surface_rate =
      _target_surface_rate_function
          ? _target_surface_rate_function->value(_t, Point())
          : _target_surface_rate;
  if (!_apply_bhp_limit)
  {
    residual = total_rate - target_surface_rate;
    derivative_rate = 1.0;
    derivative_bhp = rate_bhp_derivative;
    return;
  }

  const bool minimum = _bhp_limit_type == "minimum";
  const Real a = minimum ? target_surface_rate - total_rate
                         : total_rate - target_surface_rate;
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
BlackOilMultiCompletionWellControl::computeResidual()
{
  prepareVectorTag(_assembly, _var.number());
  Real derivative_rate;
  Real derivative_bhp;
  residualDerivatives(_local_re(0), derivative_rate, derivative_bhp);
  assignTaggedLocalResidual();
}

void
BlackOilMultiCompletionWellControl::computeJacobian()
{
  Real residual;
  Real derivative_rate;
  Real derivative_bhp;
  residualDerivatives(residual, derivative_rate, derivative_bhp);

  prepareMatrixTag(_assembly, _var.number(), _var.number());
  _local_ke(0, 0) = derivative_bhp;
  assignTaggedLocalMatrix();

  prepareMatrixTag(_assembly, _var.number(), _pressure_var);
  for (unsigned int column = 0; column < _local_ke.n() && column < _node_ids.size();
       ++column)
  {
    Real pressure_derivative = 0.0;
    for (unsigned int completion = 0; completion < _completion_pressure_weights.size();
         ++completion)
      pressure_derivative += (*_surface_productivities[completion]) *
                             _completion_pressure_weights[completion][column];
    _local_ke(0, column) = derivative_rate * pressure_derivative;
  }
  assignTaggedLocalMatrix();
}


