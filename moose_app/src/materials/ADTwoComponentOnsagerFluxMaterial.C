#include "ADTwoComponentOnsagerFluxMaterial.h"

#include <cmath>

registerMooseObject("MulticomponentReactiveFlowApp", ADTwoComponentOnsagerFluxMaterial);

InputParameters
ADTwoComponentOnsagerFluxMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Computes the two current component fluxes w_0 = -(L_00 f_0 + L_01 f_1) and "
      "w_1 = -(L_10 f_0 + L_11 f_1) for a constant symmetric positive-definite "
      "two-by-two Onsager matrix.");
  params.addRequiredParam<std::vector<MaterialPropertyName>>(
      "transport_force_names", "Exactly two spatial transport-force material properties.");
  params.addRequiredParam<std::vector<Real>>(
      "onsager_matrix",
      "Row-major entries L_00 L_01 L_10 L_11 of the symmetric positive-definite matrix.");
  params.addParam<Real>("symmetry_tolerance",
                        1.0e-12,
                        "Absolute tolerance used to enforce L_01 = L_10.");
  params.addParam<MaterialPropertyName>("current_component_0_flux_name",
                                        "current_component_0_onsager_flux",
                                        "Output name for w_0.");
  params.addParam<MaterialPropertyName>("current_component_1_flux_name",
                                        "current_component_1_onsager_flux",
                                        "Output name for w_1.");
  params.addParam<MaterialPropertyName>("reciprocity_residual_name",
                                        "onsager_reciprocity_residual",
                                        "Output name for L_01-L_10.");
  params.addParam<MaterialPropertyName>("positive_definite_determinant_name",
                                        "onsager_positive_definite_determinant",
                                        "Output name for L_00 L_11-L_01 L_10.");
  params.addParam<MaterialPropertyName>(
      "dissipation_name",
      "onsager_dissipation",
      "Output name for sum_i f_i dot (-w_i), which is nonnegative for the validated matrix.");
  return params;
}

ADTwoComponentOnsagerFluxMaterial::ADTwoComponentOnsagerFluxMaterial(
    const InputParameters & parameters)
  : Material(parameters),
    _onsager_matrix(getParam<std::vector<Real>>("onsager_matrix")),
    _component_0_flux(declareADProperty<RealVectorValue>(
        getParam<MaterialPropertyName>("current_component_0_flux_name"))),
    _component_1_flux(declareADProperty<RealVectorValue>(
        getParam<MaterialPropertyName>("current_component_1_flux_name"))),
    _reciprocity_residual(declareADProperty<Real>(
        getParam<MaterialPropertyName>("reciprocity_residual_name"))),
    _positive_definite_determinant(declareADProperty<Real>(
        getParam<MaterialPropertyName>("positive_definite_determinant_name"))),
    _dissipation(
        declareADProperty<Real>(getParam<MaterialPropertyName>("dissipation_name")))
{
  const auto force_names =
      getParam<std::vector<MaterialPropertyName>>("transport_force_names");
  if (force_names.size() != 2)
    paramError("transport_force_names", "Supply exactly two transport-force properties.");
  for (const auto & force_name : force_names)
    _transport_forces.push_back(&getADMaterialProperty<RealVectorValue>(force_name));

  if (_onsager_matrix.size() != 4)
    paramError("onsager_matrix", "Supply exactly four row-major matrix entries.");

  const Real symmetry_tolerance = getParam<Real>("symmetry_tolerance");
  if (symmetry_tolerance < 0.0)
    paramError("symmetry_tolerance", "The symmetry tolerance must be nonnegative.");
  if (std::abs(_onsager_matrix[1] - _onsager_matrix[2]) > symmetry_tolerance)
    paramError("onsager_matrix",
               "Onsager reciprocity requires L_01 = L_10 within symmetry_tolerance.");

  const Real determinant =
      _onsager_matrix[0] * _onsager_matrix[3] - _onsager_matrix[1] * _onsager_matrix[2];
  if (_onsager_matrix[0] <= 0.0 || determinant <= 0.0)
    paramError("onsager_matrix",
               "The symmetric Onsager matrix must be positive definite: require L_00 > 0 "
               "and det(L) > 0.");
}

void
ADTwoComponentOnsagerFluxMaterial::computeQpProperties()
{
  const auto & force_0 = (*_transport_forces[0])[_qp];
  const auto & force_1 = (*_transport_forces[1])[_qp];

  _component_0_flux[_qp] =
      -(_onsager_matrix[0] * force_0 + _onsager_matrix[1] * force_1);
  _component_1_flux[_qp] =
      -(_onsager_matrix[2] * force_0 + _onsager_matrix[3] * force_1);
  _reciprocity_residual[_qp] = _onsager_matrix[1] - _onsager_matrix[2];
  _positive_definite_determinant[_qp] =
      _onsager_matrix[0] * _onsager_matrix[3] - _onsager_matrix[1] * _onsager_matrix[2];
  _dissipation[_qp] =
      force_0 * (-_component_0_flux[_qp]) + force_1 * (-_component_1_flux[_qp]);
}
