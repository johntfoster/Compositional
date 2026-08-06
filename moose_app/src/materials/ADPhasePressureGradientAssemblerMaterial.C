#include "ADPhasePressureGradientAssemblerMaterial.h"

registerMooseObject("MulticomponentReactiveFlowApp",
                    ADPhasePressureGradientAssemblerMaterial);

InputParameters
ADPhasePressureGradientAssemblerMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Assembles an actual phase-pressure gradient from a reference pressure plus selectable "
      "stored surface-energy, electrical-enthalpy, saturation-force, or other corrections.");
  params.addRequiredParam<MaterialPropertyName>("base_pressure_gradient_name",
                                                 "Reference phase-pressure gradient.");
  params.addParam<std::vector<MaterialPropertyName>>(
      "correction_gradient_names", {}, "Ordered pressure-correction gradient properties.");
  params.addParam<std::vector<Real>>(
      "correction_scales", {}, "One signed multiplier for each correction gradient.");
  params.addRequiredParam<MaterialPropertyName>("phase_pressure_gradient_name",
                                                 "Output actual phase-pressure gradient.");
  return params;
}

ADPhasePressureGradientAssemblerMaterial::ADPhasePressureGradientAssemblerMaterial(
    const InputParameters & parameters)
  : Material(parameters),
    _base_pressure_gradient(
        getADMaterialProperty<RealVectorValue>("base_pressure_gradient_name")),
    _correction_scales(getParam<std::vector<Real>>("correction_scales")),
    _phase_pressure_gradient(declareADProperty<RealVectorValue>(
        getParam<MaterialPropertyName>("phase_pressure_gradient_name")))
{
  const auto names =
      getParam<std::vector<MaterialPropertyName>>("correction_gradient_names");
  if (names.size() != _correction_scales.size())
    paramError("correction_scales", "Supply one scale for each correction gradient.");
  for (const auto & name : names)
    _correction_gradients.push_back(&getADMaterialProperty<RealVectorValue>(name));
}

void
ADPhasePressureGradientAssemblerMaterial::computeQpProperties()
{
  _phase_pressure_gradient[_qp] = _base_pressure_gradient[_qp];
  for (const auto i : index_range(_correction_gradients))
    _phase_pressure_gradient[_qp] +=
        _correction_scales[i] * (*_correction_gradients[i])[_qp];
}
