#include "ADAxisymmetricSolidReferenceKinematics.h"

#include "MooseUtils.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADAxisymmetricSolidReferenceKinematics);

InputParameters
ADAxisymmetricSolidReferenceKinematics::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Computes the axisymmetric solid-reference F, J, material time rate of J, F^{-1}, "
      "and J F^{-1}, including the circumferential stretch 1+u_r/R.");
  params.addRequiredCoupledVar("radial_displacement", "Solid radial displacement u_r.");
  params.addRequiredCoupledVar("axial_displacement", "Solid axial displacement u_z.");
  params.addParam<MaterialPropertyName>("deformation_gradient_name",
                                        "solid_reference_F",
                                        "Material property name for F.");
  params.addParam<MaterialPropertyName>(
      "jacobian_name", "solid_reference_J", "Material property name for J=det(F).");
  params.addParam<MaterialPropertyName>("jacobian_dot_name",
                                        "solid_reference_J_dot",
                                        "Material property name for the material time rate of J.");
  params.addParam<MaterialPropertyName>("inverse_deformation_gradient_name",
                                        "solid_reference_F_inv",
                                        "Material property name for F^{-1}.");
  params.addParam<MaterialPropertyName>("jacobian_inverse_deformation_gradient_name",
                                        "solid_reference_J_F_inv",
                                        "Material property name for J F^{-1}.");
  return params;
}

ADAxisymmetricSolidReferenceKinematics::ADAxisymmetricSolidReferenceKinematics(
    const InputParameters & parameters)
  : Material(parameters),
    _radial_displacement(adCoupledValue("radial_displacement")),
    _axial_displacement(adCoupledValue("axial_displacement")),
    _radial_displacement_old(_fe_problem.isTransient()
                                 ? &coupledValueOld("radial_displacement")
                                 : nullptr),
    _radial_displacement_gradient(adCoupledGradient("radial_displacement")),
    _axial_displacement_gradient(adCoupledGradient("axial_displacement")),
    _radial_displacement_gradient_old(_fe_problem.isTransient()
                                          ? &coupledGradientOld("radial_displacement")
                                          : nullptr),
    _axial_displacement_gradient_old(_fe_problem.isTransient()
                                         ? &coupledGradientOld("axial_displacement")
                                         : nullptr),
    _F(declareADProperty<RankTwoTensor>(getParam<MaterialPropertyName>("deformation_gradient_name"))),
    _J(declareADProperty<Real>(getParam<MaterialPropertyName>("jacobian_name"))),
    _J_dot(declareADProperty<Real>(getParam<MaterialPropertyName>("jacobian_dot_name"))),
    _F_inv(declareADProperty<RankTwoTensor>(
        getParam<MaterialPropertyName>("inverse_deformation_gradient_name"))),
    _J_F_inv(declareADProperty<RankTwoTensor>(
        getParam<MaterialPropertyName>("jacobian_inverse_deformation_gradient_name")))
{
}

void
ADAxisymmetricSolidReferenceKinematics::initialSetup()
{
  if (_mesh.dimension() != 2)
    mooseError("ADAxisymmetricSolidReferenceKinematics requires a two-dimensional mesh.");
  if (getBlockCoordSystem() != Moose::COORD_RZ)
    mooseError("ADAxisymmetricSolidReferenceKinematics requires coord_type = RZ.");
  if (_mesh.getAxisymmetricRadialCoord() != 0)
    mooseError("ADAxisymmetricSolidReferenceKinematics requires coordinate 0 to be radial.");
}

void
ADAxisymmetricSolidReferenceKinematics::computeQpProperties()
{
  const Real reference_radius = _q_point[_qp](0);

  _F[_qp].zero();
  _F[_qp](0, 0) = 1.0 + _radial_displacement_gradient[_qp](0);
  _F[_qp](0, 1) = _radial_displacement_gradient[_qp](1);
  _F[_qp](1, 0) = _axial_displacement_gradient[_qp](0);
  _F[_qp](1, 1) = 1.0 + _axial_displacement_gradient[_qp](1);
  _F[_qp](2, 2) =
      1.0 + (MooseUtils::absoluteFuzzyEqual(reference_radius, 0.0)
                 ? _radial_displacement_gradient[_qp](0)
                 : _radial_displacement[_qp] / reference_radius);

  _J[_qp] = _F[_qp].det();
  _F_inv[_qp] = _F[_qp].inverse();
  _J_F_inv[_qp] = _F_inv[_qp] * _J[_qp];

  ADRankTwoTensor F_dot;
  F_dot.zero();
  if (_fe_problem.isTransient())
  {
    F_dot(0, 0) = (_radial_displacement_gradient[_qp](0) -
                   (*_radial_displacement_gradient_old)[_qp](0)) /
                  _dt;
    F_dot(0, 1) = (_radial_displacement_gradient[_qp](1) -
                   (*_radial_displacement_gradient_old)[_qp](1)) /
                  _dt;
    F_dot(1, 0) = (_axial_displacement_gradient[_qp](0) -
                   (*_axial_displacement_gradient_old)[_qp](0)) /
                  _dt;
    F_dot(1, 1) = (_axial_displacement_gradient[_qp](1) -
                   (*_axial_displacement_gradient_old)[_qp](1)) /
                  _dt;
    F_dot(2, 2) = MooseUtils::absoluteFuzzyEqual(reference_radius, 0.0)
                      ? (_radial_displacement_gradient[_qp](0) -
                         (*_radial_displacement_gradient_old)[_qp](0)) /
                            _dt
                      : (_radial_displacement[_qp] - (*_radial_displacement_old)[_qp]) /
                            (_dt * reference_radius);
  }
  _J_dot[_qp] = _J[_qp] * (F_dot * _F_inv[_qp]).trace();
}
