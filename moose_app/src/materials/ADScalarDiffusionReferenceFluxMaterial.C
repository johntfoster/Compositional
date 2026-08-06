#include "ADScalarDiffusionReferenceFluxMaterial.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADScalarDiffusionReferenceFluxMaterial);

InputParameters
ADScalarDiffusionReferenceFluxMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Builds a reference scalar diffusion flux W = -D Grad_X(u + u_enr) and the "
      "matching isotropic mobility tensor for EG verification problems.");
  params.addRequiredCoupledVar("backbone", "Continuous scalar backbone variable.");
  params.addCoupledVar("enrichment", "Optional elementwise scalar enrichment variable.");
  params.addRequiredRangeCheckedParam<Real>("diffusivity", "diffusivity>0", "Scalar diffusivity.");
  params.addParam<MaterialPropertyName>(
      "mobility_name", "scalar_diffusion_mobility", "Output mobility tensor name.");
  params.addParam<MaterialPropertyName>(
      "reference_flux_name", "scalar_diffusion_reference_flux", "Output reference flux name.");
  params.addParam<MaterialPropertyName>(
      "reference_flux_divergence_name", "", "Optional output name for Div_X(W).");
  return params;
}

ADScalarDiffusionReferenceFluxMaterial::ADScalarDiffusionReferenceFluxMaterial(
    const InputParameters & parameters)
  : Material(parameters),
    _grad_backbone(adCoupledGradient("backbone")),
    _grad_enrichment(isCoupled("enrichment") ? &adCoupledGradient("enrichment") : nullptr),
    _second_backbone(adCoupledSecond("backbone")),
    _second_enrichment(isCoupled("enrichment") ? &adCoupledSecond("enrichment") : nullptr),
    _diffusivity(getParam<Real>("diffusivity")),
    _mobility(declareADProperty<RankTwoTensor>(getParam<MaterialPropertyName>("mobility_name"))),
    _reference_flux(
        declareADProperty<RealVectorValue>(getParam<MaterialPropertyName>("reference_flux_name"))),
    _reference_flux_divergence(
        getParam<MaterialPropertyName>("reference_flux_divergence_name").empty()
            ? nullptr
            : &declareADProperty<Real>(
                  getParam<MaterialPropertyName>("reference_flux_divergence_name")))
{
}

void
ADScalarDiffusionReferenceFluxMaterial::computeQpProperties()
{
  ADRankTwoTensor mobility;
  for (const auto i : make_range(3))
    mobility(i, i) = _diffusivity;
  _mobility[_qp] = mobility;

  ADRealVectorValue total_gradient = _grad_backbone[_qp];
  if (_grad_enrichment)
    total_gradient += (*_grad_enrichment)[_qp];
  _reference_flux[_qp] = -_diffusivity * total_gradient;
  if (_reference_flux_divergence)
  {
    ADReal laplacian = _second_backbone[_qp].tr();
    if (_second_enrichment)
      laplacian += (*_second_enrichment)[_qp].tr();
    (*_reference_flux_divergence)[_qp] = -_diffusivity * laplacian;
  }
}
