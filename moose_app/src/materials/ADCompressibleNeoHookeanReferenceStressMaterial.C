#include "ADCompressibleNeoHookeanReferenceStressMaterial.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADCompressibleNeoHookeanReferenceStressMaterial);

InputParameters
ADCompressibleNeoHookeanReferenceStressMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Computes the effective first Piola stress P'' for a compressible Neo-Hookean "
      "solid free-energy specialization on the solid reference configuration.");
  params.addParam<MaterialPropertyName>("deformation_gradient_name",
                                        "solid_reference_F",
                                        "Material property name for F.");
  params.addParam<MaterialPropertyName>("jacobian_name",
                                        "solid_reference_J",
                                        "Material property name for J=det(F).");
  params.addParam<MaterialPropertyName>(
      "inverse_deformation_gradient_name", "solid_reference_F_inv", "Material property name for F^{-1}.");
  params.addParam<MaterialPropertyName>(
      "effective_first_piola_name",
      "solid_effective_first_piola",
      "Material property name for the effective first Piola stress P''.");
  params.addRequiredRangeCheckedParam<Real>("shear_modulus",
                                            "shear_modulus>0",
                                            "Compressible Neo-Hookean shear modulus.");
  params.addRequiredParam<Real>("lame_lambda", "First Lame parameter for the volumetric energy.");
  return params;
}

ADCompressibleNeoHookeanReferenceStressMaterial::
    ADCompressibleNeoHookeanReferenceStressMaterial(const InputParameters & parameters)
  : Material(parameters),
    _F(getADMaterialProperty<RankTwoTensor>("deformation_gradient_name")),
    _J(getADMaterialProperty<Real>("jacobian_name")),
    _F_inv(getADMaterialProperty<RankTwoTensor>("inverse_deformation_gradient_name")),
    _effective_first_piola(
        declareADProperty<RankTwoTensor>(getParam<MaterialPropertyName>("effective_first_piola_name"))),
    _shear_modulus(getParam<Real>("shear_modulus")),
    _lame_lambda(getParam<Real>("lame_lambda"))
{
}

void
ADCompressibleNeoHookeanReferenceStressMaterial::computeQpProperties()
{
  const ADRankTwoTensor F_inv_T = _F_inv[_qp].transpose();
  _effective_first_piola[_qp] =
      _shear_modulus * (_F[_qp] - F_inv_T) + _lame_lambda * log(_J[_qp]) * F_inv_T;
}
