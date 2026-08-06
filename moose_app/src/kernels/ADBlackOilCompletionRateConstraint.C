#include "ADBlackOilCompletionRateConstraint.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADBlackOilCompletionRateConstraint);

InputParameters
ADBlackOilCompletionRateConstraint::validParams()
{
  InputParameters params = ADKernelScalarBase::validParams();
  params.addClassDescription(
      "Adds one completion's integrated AD surface rate to a shared scalar well-rate "
      "constraint while preserving derivatives with respect to reconstructed CG/EG fields.");
  params.renameCoupledVar("scalar_variable", "well_rate", "Shared total surface-rate scalar.");
  params.addRequiredParam<MaterialPropertyName>("surface_rate_name",
                                                 "Completion total surface-rate property.");
  params.addRequiredRangeCheckedParam<Real>(
      "completion_reference_volume",
      "completion_reference_volume>0",
      "Reference volume of this completion region.");
  params.addRequiredRangeCheckedParam<Real>(
      "well_rate_fraction",
      "well_rate_fraction>=0 & well_rate_fraction<=1",
      "Fraction of the shared scalar rate subtracted by this completion equation; all "
      "completion fractions for one well must sum to one.");
  params.set<bool>("compute_field_residuals") = false;
  params.set<bool>("compute_scalar_residuals") = true;
  return params;
}

ADBlackOilCompletionRateConstraint::ADBlackOilCompletionRateConstraint(
    const InputParameters & parameters)
  : ADKernelScalarBase(parameters),
    _surface_rate(getADMaterialProperty<Real>("surface_rate_name")),
    _completion_reference_volume(getParam<Real>("completion_reference_volume")),
    _well_rate_fraction(getParam<Real>("well_rate_fraction"))
{
  if (!isCoupledScalar("well_rate"))
    paramError("well_rate", "Couple the shared total surface-rate scalar.");
}

ADReal
ADBlackOilCompletionRateConstraint::computeScalarQpResidual()
{
  return (_surface_rate[_qp] - _well_rate_fraction * _kappa[0]) /
         _completion_reference_volume;
}
