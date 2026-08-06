#include "ADReferenceRelativeVelocityMaterial.h"

#include "metaphysicl/raw_type.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADReferenceRelativeVelocityMaterial);

InputParameters
ADReferenceRelativeVelocityMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Computes the solid-reference relative phase velocity c=W/(J*rho_bulk), with an "
      "optional inactive-phase switch, as a reusable AD vector property.");
  params.addRequiredParam<MaterialPropertyName>("reference_relative_mass_flux_name",
                                                 "Reference relative mass flux W.");
  params.addParam<MaterialPropertyName>(
      "jacobian_name", "solid_reference_J", "Solid-reference Jacobian J.");
  params.addRequiredParam<MaterialPropertyName>("bulk_density_name",
                                                 "Current bulk phase density rho_bulk.");
  params.addParam<MaterialPropertyName>(
      "phase_active_name", "", "Optional active-phase indicator.");
  params.addRangeCheckedParam<Real>("active_tolerance",
                                    1e-12,
                                    "active_tolerance>=0",
                                    "Tolerance for inactive phase and denominator checks.");
  params.addParam<bool>(
      "deactivate_on_nonpositive_mass",
      false,
      "If true, return zero relative velocity when J*rho is nonpositive in a nonlinear trial "
      "state instead of raising an error.");
  params.addRequiredParam<MaterialPropertyName>("reference_relative_velocity_name",
                                                 "Output AD velocity property.");
  return params;
}

ADReferenceRelativeVelocityMaterial::ADReferenceRelativeVelocityMaterial(
    const InputParameters & parameters)
  : Material(parameters),
    _reference_relative_mass_flux(getADMaterialProperty<RealVectorValue>(
        getParam<MaterialPropertyName>("reference_relative_mass_flux_name"))),
    _J(getADMaterialProperty<Real>(getParam<MaterialPropertyName>("jacobian_name"))),
    _bulk_density(getADMaterialProperty<Real>(getParam<MaterialPropertyName>("bulk_density_name"))),
    _phase_active(getParam<MaterialPropertyName>("phase_active_name").empty()
                      ? nullptr
                      : &getADMaterialProperty<Real>("phase_active_name")),
    _active_tolerance(getParam<Real>("active_tolerance")),
    _deactivate_on_nonpositive_mass(getParam<bool>("deactivate_on_nonpositive_mass")),
    _reference_relative_velocity(declareADProperty<RealVectorValue>(
        getParam<MaterialPropertyName>("reference_relative_velocity_name")))
{
}

void
ADReferenceRelativeVelocityMaterial::computeQpProperties()
{
  const bool inactive = _phase_active &&
                        MetaPhysicL::raw_value((*_phase_active)[_qp]) <= _active_tolerance;
  if (inactive)
  {
    _reference_relative_velocity[_qp] = ADRealVectorValue();
    return;
  }

  const ADReal denominator = _J[_qp] * _bulk_density[_qp];
  if (MetaPhysicL::raw_value(denominator) <= _active_tolerance)
  {
    if (_deactivate_on_nonpositive_mass)
    {
      _reference_relative_velocity[_qp] = ADRealVectorValue();
      return;
    }
    mooseError(name(), ": cannot compute W/(J*rho_bulk) with nonpositive denominator.");
  }
  _reference_relative_velocity[_qp] = _reference_relative_mass_flux[_qp] / denominator;
}
