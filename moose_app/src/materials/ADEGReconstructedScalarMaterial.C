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
      MooseEnum("identity smooth_positive", "identity"),
      "Optional transformation applied to the reconstructed value, gradient, and rate.");
  params.addRangeCheckedParam<Real>("positive_regularization",
                                    1e-10,
                                    "positive_regularization>0",
                                    "Regularization for the smooth-positive transformation.");
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
    _value_transform(getParam<MooseEnum>("value_transform")),
    _positive_regularization(getParam<Real>("positive_regularization")),
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
  else
  {
    const ADReal root =
        sqrt(raw_value * raw_value + _positive_regularization * _positive_regularization);
    const ADReal derivative = 0.5 * (1.0 + raw_value / root);
    _total_value[_qp] = 0.5 * (raw_value + root);
    _total_gradient[_qp] = derivative * raw_gradient;
    _total_dot[_qp] = derivative * raw_dot;
  }
}
