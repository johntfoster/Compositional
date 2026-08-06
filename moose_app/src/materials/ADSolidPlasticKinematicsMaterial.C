#include "ADSolidPlasticKinematicsMaterial.h"

#include "metaphysicl/raw_type.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADSolidPlasticKinematicsMaterial);

InputParameters
ADSolidPlasticKinematicsMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Reconstructs Fbar=A^{-1}F and the dependent elastic arguments "
      "A_e=A A_0^{-1} A_p^{-1} and Fbar_e=Fbar Fbar_0^{-1} Fbar_p^{-1} from the "
      "manuscript solid kinematic factorization.");
  params.addParam<MaterialPropertyName>(
      "solid_deformation_gradient_name", "solid_reference_F", "Common skeleton deformation F.");
  params.addRequiredCoupledVar("distension_tensor", "Row-major active components of total A.");
  params.addRequiredCoupledVar("plastic_distension_tensor",
                               "Row-major active components of plastic A_p.");
  params.addRequiredCoupledVar("plastic_true_deformation",
                               "Row-major active components of plastic Fbar_p.");
  params.addRequiredParam<MaterialPropertyName>("distension_stress_free_map_name",
                                                 "Stress-free distension map A_0.");
  params.addRequiredParam<MaterialPropertyName>("true_deformation_stress_free_map_name",
                                                 "Stress-free true-deformation map Fbar_0.");
  params.addParam<MaterialPropertyName>(
      "distension_name", "solid_distension_tensor", "Reconstructed total distension A.");
  params.addParam<MaterialPropertyName>(
      "true_deformation_name", "solid_true_deformation", "Reconstructed Fbar=A^{-1}F.");
  params.addParam<MaterialPropertyName>(
      "elastic_distension_name", "solid_elastic_distension", "Dependent elastic A_e.");
  params.addParam<MaterialPropertyName>("elastic_true_deformation_name",
                                        "solid_elastic_true_deformation",
                                        "Dependent elastic Fbar_e.");
  params.addParam<MaterialPropertyName>("decomposition_error_name",
                                        "solid_distension_decomposition_error",
                                        "Frobenius norm of F-A Fbar.");
  params.addParam<MaterialPropertyName>("distension_split_error_name",
                                        "solid_distension_split_error",
                                        "Frobenius norm of A-A_e A_p A_0.");
  params.addParam<MaterialPropertyName>("true_deformation_split_error_name",
                                        "solid_true_deformation_split_error",
                                        "Frobenius norm of Fbar-Fbar_e Fbar_p Fbar_0.");
  return params;
}

ADSolidPlasticKinematicsMaterial::ADSolidPlasticKinematicsMaterial(
    const InputParameters & parameters)
  : Material(parameters),
    _dim(_mesh.dimension()),
    _solid_deformation_gradient(
        getADMaterialProperty<RankTwoTensor>("solid_deformation_gradient_name")),
    _distension_stress_free_map(
        getADMaterialProperty<RankTwoTensor>("distension_stress_free_map_name")),
    _true_deformation_stress_free_map(
        getADMaterialProperty<RankTwoTensor>("true_deformation_stress_free_map_name")),
    _distension(declareADProperty<RankTwoTensor>(getParam<MaterialPropertyName>("distension_name"))),
    _true_deformation(
        declareADProperty<RankTwoTensor>(getParam<MaterialPropertyName>("true_deformation_name"))),
    _elastic_distension(declareADProperty<RankTwoTensor>(
        getParam<MaterialPropertyName>("elastic_distension_name"))),
    _elastic_true_deformation(declareADProperty<RankTwoTensor>(
        getParam<MaterialPropertyName>("elastic_true_deformation_name"))),
    _decomposition_error(declareADProperty<Real>(
        getParam<MaterialPropertyName>("decomposition_error_name"))),
    _distension_split_error(declareADProperty<Real>(
        getParam<MaterialPropertyName>("distension_split_error_name"))),
    _true_deformation_split_error(declareADProperty<Real>(
        getParam<MaterialPropertyName>("true_deformation_split_error_name")))
{
  if (_dim < 1 || _dim > 3)
    mooseError("ADSolidPlasticKinematicsMaterial supports dimensions 1, 2, and 3.");
  for (const auto parameter : {"distension_tensor",
                               "plastic_distension_tensor",
                               "plastic_true_deformation"})
    if (coupledComponents(parameter) != _dim * _dim)
      paramError(parameter, "Supply exactly dim*dim row-major active components.");

  for (const auto c : make_range(_dim * _dim))
  {
    _distension_components.push_back(&adCoupledValue("distension_tensor", c));
    _plastic_distension_components.push_back(&adCoupledValue("plastic_distension_tensor", c));
    _plastic_true_deformation_components.push_back(
        &adCoupledValue("plastic_true_deformation", c));
  }
}

ADRankTwoTensor
ADSolidPlasticKinematicsMaterial::coupledTensor(
    const std::vector<const ADVariableValue *> & components) const
{
  ADRankTwoTensor tensor(ADRankTwoTensor::initIdentity);
  for (const auto i : make_range(_dim))
    for (const auto j : make_range(_dim))
      tensor(i, j) = (*components[i * _dim + j])[_qp];
  return tensor;
}

void
ADSolidPlasticKinematicsMaterial::computeQpProperties()
{
  _distension[_qp] = coupledTensor(_distension_components);
  const ADRankTwoTensor A_p = coupledTensor(_plastic_distension_components);
  const ADRankTwoTensor Fbar_p = coupledTensor(_plastic_true_deformation_components);
  const ADRankTwoTensor & F = _solid_deformation_gradient[_qp];
  const ADRankTwoTensor & A_0 = _distension_stress_free_map[_qp];
  const ADRankTwoTensor & Fbar_0 = _true_deformation_stress_free_map[_qp];

  const auto check_orientation = [this](const ADRankTwoTensor & map, const char * label)
  {
    if (MetaPhysicL::raw_value(map.det()) <= 0.0)
      mooseError(name(), ": ", label, " map must remain orientation preserving.");
  };
  check_orientation(F, "skeleton deformation");
  check_orientation(_distension[_qp], "total distension");
  check_orientation(A_p, "plastic distension");
  check_orientation(Fbar_p, "plastic true deformation");
  check_orientation(A_0, "stress-free distension");
  check_orientation(Fbar_0, "stress-free true deformation");

  _true_deformation[_qp] = _distension[_qp].inverse() * F;
  _elastic_distension[_qp] = _distension[_qp] * A_0.inverse() * A_p.inverse();
  _elastic_true_deformation[_qp] =
      _true_deformation[_qp] * Fbar_0.inverse() * Fbar_p.inverse();

  _decomposition_error[_qp] = (F - _distension[_qp] * _true_deformation[_qp]).L2norm();
  _distension_split_error[_qp] =
      (_distension[_qp] - _elastic_distension[_qp] * A_p * A_0).L2norm();
  _true_deformation_split_error[_qp] =
      (_true_deformation[_qp] - _elastic_true_deformation[_qp] * Fbar_p * Fbar_0)
          .L2norm();
}
