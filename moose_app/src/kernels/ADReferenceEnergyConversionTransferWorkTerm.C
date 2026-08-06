#include "ADReferenceEnergyConversionTransferWorkTerm.h"

registerMooseObject("MulticomponentReactiveFlowApp",
                    ADReferenceEnergyConversionTransferWorkTerm);

InputParameters
ADReferenceEnergyConversionTransferWorkTerm::validParams()
{
  InputParameters params = ADKernelValue::validParams();
  params.addClassDescription(
      "Atomic +J*sum_alpha L_xi^alpha dot(c)_xi^alpha residual contribution, which is "
      "the negative conversion-transfer work on the RHS of Eq. (MC_energy_balance).");
  params.addRequiredParam<std::vector<MaterialPropertyName>>(
      "generalized_transfer_work_names", "Specific L_xi^alpha properties.");
  params.addRequiredParam<std::vector<MaterialPropertyName>>(
      "current_component_source_names", "Matching current dot(c)_xi^alpha properties.");
  params.addParam<Real>("scale", 1.0, "Signed multiplier.");
  params.addParam<MaterialPropertyName>("solid_jacobian_name", "solid_reference_J", "J.");
  return params;
}

ADReferenceEnergyConversionTransferWorkTerm::ADReferenceEnergyConversionTransferWorkTerm(
    const InputParameters & parameters)
  : ADKernelValue(parameters),
    _J(getADMaterialProperty<Real>("solid_jacobian_name")),
    _scale(getParam<Real>("scale"))
{
  const auto works =
      getParam<std::vector<MaterialPropertyName>>("generalized_transfer_work_names");
  const auto sources =
      getParam<std::vector<MaterialPropertyName>>("current_component_source_names");
  if (works.empty() || works.size() != sources.size())
    paramError("generalized_transfer_work_names",
               "Supply one generalized transfer-work property per component source.");
  for (const auto i : make_range(works.size()))
  {
    _transfer_works.push_back(&getADMaterialProperty<Real>(works[i]));
    _component_sources.push_back(&getADMaterialProperty<Real>(sources[i]));
  }
}

ADReal
ADReferenceEnergyConversionTransferWorkTerm::precomputeQpResidual()
{
  ADReal power = 0.0;
  for (const auto i : make_range(_transfer_works.size()))
    power += (*_transfer_works[i])[_qp] * (*_component_sources[i])[_qp];
  return _scale * _J[_qp] * power;
}
