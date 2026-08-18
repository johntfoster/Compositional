#include "ADEGReconstructedScalarMaterial.h"

#include <cmath>

registerMooseObject("MulticomponentReactiveFlowApp", ADEGReconstructedScalarMaterial);

InputParameters
ADEGReconstructedScalarMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Declares the enriched-Galerkin total scalar field, reference gradient, and time "
      "derivative from a continuous backbone plus an optional elementwise enrichment.");
  params.addRequiredCoupledVar("backbone", "Continuous P1 backbone field.");
  params.addCoupledVar("enrichment", "Elementwise P0 enrichment field.");
  params.addRequiredParam<std::string>("field_name", "Field prefix for default output names.");
  params.addParam<MaterialPropertyName>("total_value_name", "", "Output name for the total value.");
  params.addParam<MaterialPropertyName>(
      "total_gradient_name", "", "Output name for the total reference gradient.");
  params.addParam<MaterialPropertyName>(
      "total_dot_name", "", "Output name for the total time derivative.");
  params.addParam<MooseEnum>(
      "value_transform",
      MooseEnum("identity smooth_positive bounded simplex_bounded", "identity"),
      "Optional transformation applied to the reconstructed value, gradient, and rate.  "
      "bounded maps a nonnegative reconstructed value into [0, 1], while "
      "simplex_bounded maps it into [0, 1 - complement]. Both maps preserve an exact "
      "zero value for phase disappearance.");
  params.addRangeCheckedParam<Real>("positive_regularization",
                                    1e-10,
                                    "positive_regularization>0",
                                    "Regularization for the smooth-positive transformation.");
  params.addRangeCheckedParam<Real>(
      "nonnegativity_regularization",
      1e-10,
      "nonnegativity_regularization>0",
      "Regularization for the nonnegativity clamp applied before the bounded and "
      "simplex-bounded radial maps.  The smooth-max clamp f(raw) = "
      "0.5*(raw + sqrt(raw^2 + delta^2)) has floor delta/2 at raw = 0; delta is kept "
      "far below the gas-phase activity tolerance (1e-12) so a reconstructed "
      "phase-absent saturation does not trip saturated-PVTO branch selection, and "
      "the map is identity to machine precision at every physical saturation.");
  params.addParam<MaterialPropertyName>(
      "complement_value_name",
      "",
      "Saturation-complement total value that supplies the upper bound "
      "1 - complement of the simplex-bounded transform.");
  params.addParam<MaterialPropertyName>(
      "complement_gradient_name",
      "",
      "Reference gradient of the saturation-complement total for the chain rule of the "
      "simplex-bounded transform.  Defaults to zero when omitted.");
  params.addParam<MaterialPropertyName>(
      "complement_dot_name",
      "",
      "Time derivative of the saturation-complement total for the chain rule of the "
      "simplex-bounded transform.  Defaults to zero when omitted.");
  return params;
}

ADEGReconstructedScalarMaterial::ADEGReconstructedScalarMaterial(
    const InputParameters & parameters)
  : Material(parameters),
    _backbone(adCoupledValue("backbone")),
    _grad_backbone(adCoupledGradient("backbone")),
    _backbone_dot(_fe_problem.isTransient() ? &adCoupledDot("backbone") : nullptr),
    _enrichment(isCoupled("enrichment") ? &adCoupledValue("enrichment") : nullptr),
    _grad_enrichment(isCoupled("enrichment") ? &adCoupledGradient("enrichment") : nullptr),
    _enrichment_dot(_fe_problem.isTransient() && isCoupled("enrichment")
                        ? &adCoupledDot("enrichment")
                        : nullptr),
    _nonnegativity_regularization(getParam<Real>("nonnegativity_regularization")),
    _value_transform(getParam<MooseEnum>("value_transform")),
    _positive_regularization(getParam<Real>("positive_regularization")),
    _complement_value(getParam<MaterialPropertyName>("complement_value_name").empty()
                          ? nullptr
                          : &getADMaterialProperty<Real>(
                                getParam<MaterialPropertyName>("complement_value_name"))),
    _complement_gradient(getParam<MaterialPropertyName>("complement_gradient_name").empty()
                             ? nullptr
                             : &getADMaterialProperty<RealVectorValue>(
                                   getParam<MaterialPropertyName>("complement_gradient_name"))),
    _complement_dot(getParam<MaterialPropertyName>("complement_dot_name").empty()
                        ? nullptr
                        : &getADMaterialProperty<Real>(
                              getParam<MaterialPropertyName>("complement_dot_name"))),
    _total_value(declareADProperty<Real>(
        getParam<MaterialPropertyName>("total_value_name").empty()
            ? MaterialPropertyName(getParam<std::string>("field_name") + "_total")
            : getParam<MaterialPropertyName>("total_value_name"))),
    _total_gradient(declareADProperty<RealVectorValue>(
        getParam<MaterialPropertyName>("total_gradient_name").empty()
            ? MaterialPropertyName(getParam<std::string>("field_name") + "_total_gradient")
            : getParam<MaterialPropertyName>("total_gradient_name"))),
    _total_dot(declareADProperty<Real>(
        getParam<MaterialPropertyName>("total_dot_name").empty()
            ? MaterialPropertyName(getParam<std::string>("field_name") + "_total_dot")
            : getParam<MaterialPropertyName>("total_dot_name")))
{
  if (getParam<std::string>("field_name").empty())
    paramError("field_name", "The reconstructed field prefix must be nonempty.");
  if (_value_transform == "simplex_bounded" && !_complement_value)
    paramError("complement_value_name",
               "The simplex_bounded value transform requires a saturation-complement total.");
}

void
ADEGReconstructedScalarMaterial::computeQpProperties()
{
  const ADReal raw_value = _backbone[_qp] + (_enrichment ? (*_enrichment)[_qp] : 0.0);
  const ADRealVectorValue raw_gradient =
      _grad_backbone[_qp] + (_grad_enrichment ? (*_grad_enrichment)[_qp] : ADRealVectorValue());
  const ADReal raw_dot = (_backbone_dot ? (*_backbone_dot)[_qp] : 0.0) +
                         (_enrichment_dot ? (*_enrichment_dot)[_qp] : 0.0);

  if (_value_transform == "identity")
  {
    _total_value[_qp] = raw_value;
    _total_gradient[_qp] = raw_gradient;
    _total_dot[_qp] = raw_dot;
  }
  else if (_value_transform == "smooth_positive")
  {
    const ADReal root =
        sqrt(raw_value * raw_value + _positive_regularization * _positive_regularization);
    const ADReal derivative = 0.5 * (1.0 + raw_value / root);
    _total_value[_qp] = 0.5 * (raw_value + root);
    _total_gradient[_qp] = derivative * raw_gradient;
    _total_dot[_qp] = derivative * raw_dot;
  }
  else
  {
    mooseAssert(_value_transform == "bounded" || _value_transform == "simplex_bounded",
                "unexpected reconstruction value transform");
    const ADReal upper = _value_transform == "bounded" ? ADReal(1.0)
                                                         : 1.0 - (*_complement_value)[_qp];
    const ADRealVectorValue upper_gradient =
        _value_transform == "bounded" || !_complement_gradient
            ? ADRealVectorValue()
            : -(*_complement_gradient)[_qp];
    const ADReal upper_dot = _value_transform == "bounded" || !_complement_dot
                                 ? ADReal(0.0)
                                 : -(*_complement_dot)[_qp];

    // A nonnegativity clamp keeps the reconstructed raw value nonnegative so
    // the radial map below delivers its documented [0, upper] contract.  A
    // hard branch (zero below the threshold, identity at and above it) is
    // smooth nowhere and toggles its Jacobian entry (derivative 0 vs 1) as
    // Newton iterates across the phase-appearance threshold, which stalls the
    // solve with alternating residuals.  The smooth-max approximation
    // f(raw) = 0.5*(raw + sqrt(raw^2 + delta^2)) is therefore used instead:
    // it is C-infinity, keeps derivative 0.5 at raw = 0 (so the Jacobian
    // block stays coupled at a zero-saturation phase-appearance initial
    // state, avoiding singular "column is exactly zero" solves), approaches
    // identity for raw >> delta, and floors at a tiny positive value
    // delta/2 at raw = 0.  The clamp delta is kept far below the gas-phase
    // activity tolerance (1e-12) so a phase-absent reconstructed saturation
    // (floor delta/2 ~ 5e-14) does not trip the saturated-PVTO branch
    // selection in the benchmark PVT material, which is what keeps the
    // DRSDT-equilibrium closure on its pre-clamp unsaturated branch.  This
    // makes the transform self-contained: plain NEWTON does not enforce the
    // [Bounds] block, so the map cannot rely on bound-enforced backbones to
    // keep a reconstructed saturation from crossing zero.
    const ADReal root = sqrt(raw_value * raw_value +
                             _nonnegativity_regularization * _nonnegativity_regularization);
    const ADReal nonneg_raw = 0.5 * (raw_value + root);
    const ADReal nonneg_derivative = 0.5 * (1.0 + raw_value / root);

    // This eighth-order radial map is identity to leading order at zero,
    // preserves exact phase disappearance, and approaches upper without
    // crossing it.
    const ADReal denominator = pow(pow(nonneg_raw, 8.0) + pow(upper, 8.0), 0.125);
    if (MetaPhysicL::raw_value(denominator) == 0.0)
    {
      _total_value[_qp] = 0.0;
      _total_gradient[_qp] = ADRealVectorValue();
      _total_dot[_qp] = 0.0;
      return;
    }

    const ADReal denominator_to_ninth = pow(denominator, 9.0);
    const ADReal raw_derivative = nonneg_derivative * pow(upper, 9.0) / denominator_to_ninth;
    const ADReal upper_derivative = pow(nonneg_raw, 9.0) / denominator_to_ninth;
    _total_value[_qp] = nonneg_raw * upper / denominator;
    _total_gradient[_qp] = raw_derivative * raw_gradient + upper_derivative * upper_gradient;
    _total_dot[_qp] = raw_derivative * raw_dot + upper_derivative * upper_dot;
  }
}
