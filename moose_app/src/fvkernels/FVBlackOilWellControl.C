#include "FVBlackOilWellControl.h"

#include "ADUtils.h"
#include "Assembly.h"
#include "MooseVariableScalar.h"
#include "metaphysicl/raw_type.h"

#include <cmath>

registerADMooseObject("MulticomponentReactiveFlowApp", FVBlackOilWellControl);

InputParameters
FVBlackOilWellControl::validParams()
{
  InputParameters params = FVElementalKernel::validParams();
  params.addClassDescription(
      "Adds a one-completion AD surface-rate or rate/BHP complementarity equation to a shared "
      "scalar bottom-hole-pressure variable without adding a field residual.");
  params.addRequiredCoupledVar("bottom_hole_pressure", "Shared scalar bottom-hole pressure.");
  params.addRequiredParam<MaterialPropertyName>("surface_rate_name", "AD completion surface rate.");
  params.addRequiredParam<Real>("target_surface_rate", "Signed surface-rate target.");
  params.addParam<bool>("apply_bhp_limit", false, "Apply a minimum or maximum BHP limit.");
  params.addParam<MooseEnum>(
      "bhp_limit_type", MooseEnum("minimum maximum", "minimum"), "Type of BHP limit.");
  params.addParam<Real>("bhp_limit", 0.0, "Bottom-hole-pressure limit.");
  return params;
}

FVBlackOilWellControl::FVBlackOilWellControl(const InputParameters & parameters)
  : FVElementalKernel(parameters),
    _bhp_var(*getScalarVar("bottom_hole_pressure", 0)),
    _bhp(adCoupledScalarValue("bottom_hole_pressure")),
    _surface_rate(
        getADMaterialProperty<Real>(getParam<MaterialPropertyName>("surface_rate_name"))),
    _target_surface_rate(getParam<Real>("target_surface_rate")),
    _apply_bhp_limit(getParam<bool>("apply_bhp_limit")),
    _bhp_limit_type(getParam<MooseEnum>("bhp_limit_type")),
    _bhp_limit(getParam<Real>("bhp_limit"))
{
  if (_bhp_var.order() != 1)
    paramError("bottom_hole_pressure", "Use a FIRST-order scalar BHP variable.");
}

ADReal
FVBlackOilWellControl::controlResidual() const
{
  const ADReal rate = _surface_rate[_qp];
  if (!_apply_bhp_limit)
    return rate - _target_surface_rate;

  const bool minimum = _bhp_limit_type == "minimum";
  const ADReal a = minimum ? _target_surface_rate - rate : rate - _target_surface_rate;
  const ADReal b = minimum ? _bhp[0] - _bhp_limit : _bhp_limit - _bhp[0];
  return sqrt(a * a + b * b) - a - b;
}

void
FVBlackOilWellControl::computeResidualAndJacobian()
{
  addResidualsAndJacobian(_assembly,
                          std::array<ADReal, 1>{{controlResidual()}},
                          _bhp_var.dofIndices(),
                          _bhp_var.scalingFactor());
}

void
FVBlackOilWellControl::computeResidual()
{
  addResiduals(_assembly,
               std::array<Real, 1>{{MetaPhysicL::raw_value(controlResidual())}},
               _bhp_var.dofIndices(),
               _bhp_var.scalingFactor());
}

void
FVBlackOilWellControl::computeJacobian()
{
}

void
FVBlackOilWellControl::computeOffDiagJacobian()
{
  addJacobian(_assembly,
              std::array<ADReal, 1>{{controlResidual()}},
              _bhp_var.dofIndices(),
              _bhp_var.scalingFactor());
}
