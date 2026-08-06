#include "ADEGScalarRateGradientMaterial.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADEGScalarRateGradientMaterial);

InputParameters
ADEGScalarRateGradientMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Computes Grad_X(dot(a)+dot(a_enr)) for a transient enriched-Galerkin scalar field.");
  params.addRequiredCoupledVar("backbone", "Continuous scalar backbone.");
  params.addCoupledVar("enrichment", "Optional elementwise enrichment.");
  params.addRequiredParam<MaterialPropertyName>("total_rate_gradient_name",
                                                 "Output reference rate-gradient property.");
  return params;
}

ADEGScalarRateGradientMaterial::ADEGScalarRateGradientMaterial(
    const InputParameters & parameters)
  : Material(parameters),
    _backbone_gradient_dot(_fe_problem.isTransient() ? &adCoupledGradientDot("backbone")
                                                     : nullptr),
    _enrichment_gradient_dot(_fe_problem.isTransient() && isCoupled("enrichment")
                                 ? &adCoupledGradientDot("enrichment")
                                 : nullptr),
    _total_rate_gradient(declareADProperty<RealVectorValue>(
        getParam<MaterialPropertyName>("total_rate_gradient_name")))
{
}

void
ADEGScalarRateGradientMaterial::computeQpProperties()
{
  _total_rate_gradient[_qp] =
      _backbone_gradient_dot ? (*_backbone_gradient_dot)[_qp] : ADRealVectorValue();
  if (_enrichment_gradient_dot)
    _total_rate_gradient[_qp] += (*_enrichment_gradient_dot)[_qp];
}
