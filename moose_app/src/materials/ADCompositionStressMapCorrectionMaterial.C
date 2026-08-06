#include "ADCompositionStressMapCorrectionMaterial.h"

registerMooseObject("MulticomponentReactiveFlowApp",
                    ADCompositionStressMapCorrectionMaterial);

InputParameters
ADCompositionStressMapCorrectionMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Assembles one independently selectable stress-free-map composition term from current "
      "theory Eq. (183): sign*tr(C*dG0/deta_alpha*G0^{-1}). Use separate instances for "
      "the distension and true-deformation maps.");
  params.addRequiredParam<MaterialPropertyName>(
      "coefficient_tensor_name", "The complete left tensor C preceding dG0/deta_alpha.");
  params.addRequiredParam<MaterialPropertyName>(
      "stress_free_map_inverse_name", "The stress-free map inverse G0^{-1}.");
  params.addRequiredParam<std::vector<MaterialPropertyName>>(
      "stress_free_map_derivative_names",
      "The derivatives dG0/deta_alpha in component order.");
  params.addRequiredParam<std::vector<MaterialPropertyName>>(
      "correction_names", "Scalar output names in the same component order.");
  params.addParam<Real>("sign", -1.0, "Multiplicative sign; Eq. (183) uses -1.");
  return params;
}

ADCompositionStressMapCorrectionMaterial::ADCompositionStressMapCorrectionMaterial(
    const InputParameters & parameters)
  : Material(parameters),
    _coefficient_tensor(
        getADMaterialProperty<RankTwoTensor>("coefficient_tensor_name")),
    _stress_free_map_inverse(
        getADMaterialProperty<RankTwoTensor>("stress_free_map_inverse_name")),
    _sign(getParam<Real>("sign"))
{
  const auto derivative_names =
      getParam<std::vector<MaterialPropertyName>>("stress_free_map_derivative_names");
  const auto correction_names =
      getParam<std::vector<MaterialPropertyName>>("correction_names");
  if (derivative_names.empty())
    paramError("stress_free_map_derivative_names", "Supply at least one component derivative.");
  if (correction_names.size() != derivative_names.size())
    paramError("correction_names", "Supply exactly one output for each map derivative.");

  _map_derivatives.reserve(derivative_names.size());
  _corrections.reserve(correction_names.size());
  for (const auto component : index_range(derivative_names))
  {
    _map_derivatives.push_back(
        &getADMaterialProperty<RankTwoTensor>(derivative_names[component]));
    _corrections.push_back(&declareADProperty<Real>(correction_names[component]));
  }
}

void
ADCompositionStressMapCorrectionMaterial::computeQpProperties()
{
  for (const auto component : index_range(_map_derivatives))
    (*_corrections[component])[_qp] =
        _sign * (_coefficient_tensor[_qp] * (*_map_derivatives[component])[_qp] *
                 _stress_free_map_inverse[_qp])
                    .trace();
}
