#include "ADPhaseAppearanceComplementarityMaterial.h"

#include "metaphysicl/raw_type.h"

registerMooseObject("MulticomponentReactiveFlowApp",
                    ADPhaseAppearanceComplementarityMaterial);

InputParameters
ADPhaseAppearanceComplementarityMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Generic semismooth Fischer-Burmeister phase-appearance closure between a "
      "nonnegative phase amount and any nonnegative manuscript-theory stability gap. "
      "It introduces no traditional fugacity-equality or flash assumption.");
  params.addRequiredCoupledVar(
      "phase_amount", "Nonnegative phase volume fraction, saturation, or amount a.");
  params.addRequiredParam<MaterialPropertyName>(
      "stability_gap_name", "Nonnegative incipient-phase stability gap before normalization.");
  params.addRangeCheckedParam<Real>(
      "gap_scale", 1.0, "gap_scale>0", "Positive scale used to nondimensionalize the gap.");
  params.addRangeCheckedParam<Real>(
      "smoothing",
      0.0,
      "smoothing>=0",
      "Fischer-Burmeister smoothing epsilon. Zero selects the exact semismooth relation.");
  params.addParam<std::string>(
      "property_prefix", "phase_appearance", "Prefix for all declared output properties.");
  return params;
}

ADPhaseAppearanceComplementarityMaterial::ADPhaseAppearanceComplementarityMaterial(
    const InputParameters & parameters)
  : Material(parameters),
    _phase_amount(adCoupledValue("phase_amount")),
    _stability_gap(getADMaterialProperty<Real>("stability_gap_name")),
    _gap_scale(getParam<Real>("gap_scale")),
    _smoothing(getParam<Real>("smoothing")),
    _property_prefix(getParam<std::string>("property_prefix")),
    _normalized_stability_gap(
        declareADProperty<Real>(outputName("normalized_stability_gap"))),
    _complementarity_residual(
        declareADProperty<Real>(outputName("complementarity_residual"))),
    _phase_availability(declareADProperty<Real>(outputName("phase_availability")))
{
  if (_property_prefix.empty())
    paramError("property_prefix", "The output prefix must be nonempty.");
}

MaterialPropertyName
ADPhaseAppearanceComplementarityMaterial::outputName(const std::string & suffix) const
{
  return MaterialPropertyName(_property_prefix + "_" + suffix);
}

void
ADPhaseAppearanceComplementarityMaterial::computeQpProperties()
{
  const ADReal amount = _phase_amount[_qp];
  const ADReal gap = _stability_gap[_qp] / _gap_scale;
  _normalized_stability_gap[_qp] = gap;
  _phase_availability[_qp] = amount;

  const Real norm = std::hypot(MetaPhysicL::raw_value(amount),
                               MetaPhysicL::raw_value(gap));
  if (_smoothing == 0.0 && norm <= 1e-14)
    // A finite member of the generalized Jacobian at the exact FB origin.
    _complementarity_residual[_qp] = -amount - gap;
  else
    _complementarity_residual[_qp] =
        sqrt(amount * amount + gap * gap + 2.0 * _smoothing * _smoothing) - amount - gap;
}
