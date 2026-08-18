#include "ADAssociatedPlasticFlowMaterial.h"

#include "metaphysicl/raw_type.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADAssociatedPlasticFlowMaterial);

InputParameters
ADAssociatedPlasticFlowMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Implements the manuscript mapped deviatoric driving stress, associated true-plastic "
      "flow, scalar plastic-distension flow, single phase-level mobilities, and dissipation "
      "audits.");
  params.addRequiredParam<MaterialPropertyName>("material_stress_name",
                                                 "Material stress sigma-prime.");
  params.addRequiredParam<MaterialPropertyName>("elastic_true_deformation_name",
                                                 "Elastic true-deformation tensor Fbar_e.");
  params.addRequiredParam<MaterialPropertyName>("distension_tensor_name",
                                                 "Current total distension tensor A_s.");
  params.addRequiredParam<MaterialPropertyName>(
      "elastic_distension_tensor_name", "Elastic distension tensor A_s^e.");
  params.addRangeCheckedParam<Real>("plastic_deformation_mobility",
                                    0.0,
                                    "plastic_deformation_mobility>=0",
                                    "Constant phase Lambda_Fbar; a state-dependent single "
                                    "phase mobility property may replace it.");
  params.addRangeCheckedParam<Real>("plastic_distension_mobility",
                                    0.0,
                                    "plastic_distension_mobility>=0",
                                    "Constant phase Lambda_A; a state-dependent single "
                                    "phase mobility property may replace it.");
  params.addParam<MaterialPropertyName>(
      "plastic_deformation_mobility_property",
      "",
      "Optional state-dependent single phase Lambda_Fbar that replaces the constant.");
  params.addParam<MaterialPropertyName>(
      "plastic_distension_mobility_property",
      "",
      "Optional state-dependent single phase Lambda_A that replaces the constant.");
  params.addParam<MaterialPropertyName>("driving_stress_name",
                                        "true_plastic_driving_stress",
                                        "Mapped deviatoric S_s output.");
  params.addParam<MaterialPropertyName>("plastic_deformation_log_rate_name",
                                        "plastic_deformation_log_rate",
                                        "dot(Fbar_p) Fbar_p^{-1} output.");
  params.addParam<MaterialPropertyName>("plastic_distension_log_rate_name",
                                        "plastic_distension_log_rate",
                                        "Tensor dot(A_p) A_p^{-1} output.");
  params.addParam<MaterialPropertyName>("mean_material_stress_name",
                                        "plastic_mean_material_stress",
                                        "tr(sigma-prime)/3 output.");
  params.addParam<MaterialPropertyName>("scalar_plastic_distension_log_rate_name",
                                        "scalar_plastic_distension_log_rate",
                                        "dot(a_p)/a_p output.");
  params.addParam<MaterialPropertyName>("plastic_deformation_dissipation_name",
                                        "plastic_deformation_dissipation",
                                        "Lambda_Fbar S:S output.");
  params.addParam<MaterialPropertyName>(
      "tensor_plastic_distension_dissipation_name",
      "tensor_plastic_distension_dissipation",
      "Tensor plastic-distension conjugate power output.");
  params.addParam<MaterialPropertyName>("plastic_distension_dissipation_name",
                                        "plastic_distension_dissipation",
                                        "Lambda_A [tr(sigma-prime)/3]^2 output.");
  params.addParam<MaterialPropertyName>("driving_stress_trace_name",
                                        "true_plastic_driving_stress_trace",
                                        "Isochoric trace audit output.");
  return params;
}

ADAssociatedPlasticFlowMaterial::ADAssociatedPlasticFlowMaterial(
    const InputParameters & parameters)
  : Material(parameters),
    _material_stress(getADMaterialProperty<RankTwoTensor>("material_stress_name")),
    _elastic_true_deformation(
        getADMaterialProperty<RankTwoTensor>("elastic_true_deformation_name")),
    _distension_tensor(getADMaterialProperty<RankTwoTensor>("distension_tensor_name")),
    _elastic_distension_tensor(
        getADMaterialProperty<RankTwoTensor>("elastic_distension_tensor_name")),
    _plastic_deformation_mobility(getParam<Real>("plastic_deformation_mobility")),
    _plastic_distension_mobility(getParam<Real>("plastic_distension_mobility")),
    _plastic_deformation_mobility_property(
        getParam<MaterialPropertyName>("plastic_deformation_mobility_property").empty()
            ? nullptr
            : &getADMaterialProperty<Real>(
                  getParam<MaterialPropertyName>("plastic_deformation_mobility_property"))),
    _plastic_distension_mobility_property(
        getParam<MaterialPropertyName>("plastic_distension_mobility_property").empty()
            ? nullptr
            : &getADMaterialProperty<Real>(
                  getParam<MaterialPropertyName>("plastic_distension_mobility_property"))),
    _driving_stress(
        declareADProperty<RankTwoTensor>(getParam<MaterialPropertyName>("driving_stress_name"))),
    _plastic_deformation_log_rate(declareADProperty<RankTwoTensor>(
        getParam<MaterialPropertyName>("plastic_deformation_log_rate_name"))),
    _plastic_distension_log_rate(declareADProperty<RankTwoTensor>(
        getParam<MaterialPropertyName>("plastic_distension_log_rate_name"))),
    _mean_material_stress(
        declareADProperty<Real>(getParam<MaterialPropertyName>("mean_material_stress_name"))),
    _scalar_plastic_distension_log_rate(declareADProperty<Real>(
        getParam<MaterialPropertyName>("scalar_plastic_distension_log_rate_name"))),
    _plastic_deformation_dissipation(declareADProperty<Real>(
        getParam<MaterialPropertyName>("plastic_deformation_dissipation_name"))),
    _tensor_plastic_distension_dissipation(declareADProperty<Real>(
        getParam<MaterialPropertyName>("tensor_plastic_distension_dissipation_name"))),
    _plastic_distension_dissipation(declareADProperty<Real>(
        getParam<MaterialPropertyName>("plastic_distension_dissipation_name"))),
    _driving_stress_trace(
        declareADProperty<Real>(getParam<MaterialPropertyName>("driving_stress_trace_name")))
{
  if (_plastic_deformation_mobility_property && isParamSetByUser("plastic_deformation_mobility"))
    paramError("plastic_deformation_mobility_property",
               "Provide a phase mobility as a constant or as a single property, not both.");
  if (_plastic_distension_mobility_property && isParamSetByUser("plastic_distension_mobility"))
    paramError("plastic_distension_mobility_property",
               "Provide a phase mobility as a constant or as a single property, not both.");
}

ADReal
ADAssociatedPlasticFlowMaterial::mobility(
    const ADMaterialProperty<Real> * property,
    const Real constant,
    const char * label) const
{
  if (!property)
    return constant;
  if (MetaPhysicL::raw_value((*property)[_qp]) < 0.0)
    mooseError(name(), ": ", label, " phase mobility must remain nonnegative.");
  return (*property)[_qp];
}

void
ADAssociatedPlasticFlowMaterial::computeQpProperties()
{
  const ADReal lambda_f = mobility(_plastic_deformation_mobility_property,
                                   _plastic_deformation_mobility,
                                   "plastic-deformation");
  const ADReal lambda_a = mobility(_plastic_distension_mobility_property,
                                   _plastic_distension_mobility,
                                   "plastic-distension");
  const ADRankTwoTensor identity(ADRankTwoTensor::initIdentity);
  const ADRankTwoTensor & sigma = _material_stress[_qp];
  const ADRankTwoTensor & F_e = _elastic_true_deformation[_qp];
  const ADRankTwoTensor & A = _distension_tensor[_qp];
  const ADRankTwoTensor & A_e = _elastic_distension_tensor[_qp];
  if (MetaPhysicL::raw_value(F_e.det()) <= 0.0)
    mooseError(name(), ": elastic true-deformation tensor must remain orientation preserving.");
  if (MetaPhysicL::raw_value(A.det()) <= 0.0)
    mooseError(name(), ": distension tensor must remain orientation preserving.");
  if (MetaPhysicL::raw_value(A_e.det()) <= 0.0)
    mooseError(name(), ": elastic distension tensor must remain orientation preserving.");
  const ADRankTwoTensor deviatoric_transpose =
      sigma.transpose() - sigma.tr() / 3.0 * identity;
  _driving_stress[_qp] =
      F_e.inverse() * A.inverse() * deviatoric_transpose * A * F_e;
  _plastic_deformation_log_rate[_qp] = lambda_f * _driving_stress[_qp].transpose();
  _plastic_distension_log_rate[_qp] =
      lambda_a * A_e.transpose() * sigma * A_e.inverse().transpose();
  _mean_material_stress[_qp] = sigma.tr() / 3.0;
  _scalar_plastic_distension_log_rate[_qp] = lambda_a * _mean_material_stress[_qp];
  _plastic_deformation_dissipation[_qp] =
      lambda_f * _driving_stress[_qp].doubleContraction(_driving_stress[_qp]);
  _tensor_plastic_distension_dissipation[_qp] = sigma.doubleContraction(
      A_e * _plastic_distension_log_rate[_qp] * A_e.inverse());
  _plastic_distension_dissipation[_qp] =
      lambda_a * _mean_material_stress[_qp] * _mean_material_stress[_qp];
  _driving_stress_trace[_qp] = _driving_stress[_qp].tr();
}
