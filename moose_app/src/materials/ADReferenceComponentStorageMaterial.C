#include "ADReferenceComponentStorageMaterial.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADReferenceComponentStorageMaterial);

InputParameters
ADReferenceComponentStorageMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription("Computes rho_f^alpha = phi_f rhobar_f eta_f^alpha and "
                             "M_f^alpha = J phi_f rhobar_f eta_f^alpha.");
  params.addParam<MaterialPropertyName>(
      "jacobian_name", "solid_reference_J", "Material property name for J.");
  params.addRequiredCoupledVar("porosity", "Fluid phase volume fraction phi_f.");
  params.addRequiredCoupledVar("intrinsic_density", "Intrinsic phase density rhobar_f.");
  params.addRequiredCoupledVar("component_mass_fraction", "Component mass fraction eta_f^alpha.");
  params.addParam<MaterialPropertyName>("current_component_partial_density_name",
                                        "current_component_partial_density",
                                        "Material property name for rho_f^alpha.");
  params.addParam<MaterialPropertyName>("reference_component_storage_name",
                                        "reference_component_storage",
                                        "Material property name for M_f^alpha.");
  return params;
}

ADReferenceComponentStorageMaterial::ADReferenceComponentStorageMaterial(
    const InputParameters & parameters)
  : Material(parameters),
    _J(getADMaterialProperty<Real>("jacobian_name")),
    _porosity(adCoupledValue("porosity")),
    _intrinsic_density(adCoupledValue("intrinsic_density")),
    _component_mass_fraction(adCoupledValue("component_mass_fraction")),
    _current_component_partial_density(declareADProperty<Real>(
        getParam<MaterialPropertyName>("current_component_partial_density_name"))),
    _reference_component_storage(
        declareADProperty<Real>(getParam<MaterialPropertyName>("reference_component_storage_name")))
{
}

void
ADReferenceComponentStorageMaterial::computeQpProperties()
{
  _current_component_partial_density[_qp] =
      _porosity[_qp] * _intrinsic_density[_qp] * _component_mass_fraction[_qp];
  _reference_component_storage[_qp] = _J[_qp] * _current_component_partial_density[_qp];
}
