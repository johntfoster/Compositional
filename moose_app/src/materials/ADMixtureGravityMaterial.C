#include "ADMixtureGravityMaterial.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADMixtureGravityMaterial);

InputParameters ADMixtureGravityMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription("Sums current bulk phase densities and forms rho g.");
  params.addRequiredParam<std::vector<MaterialPropertyName>>("bulk_density_names", "Current bulk phase densities.");
  params.addRequiredParam<RealVectorValue>("gravity", "Gravity acceleration vector.");
  params.addParam<MaterialPropertyName>("mixture_density_name", "mixture_current_density", "Output rho.");
  params.addParam<MaterialPropertyName>("gravity_force_name", "mixture_gravity_force", "Output rho g.");
  return params;
}
ADMixtureGravityMaterial::ADMixtureGravityMaterial(const InputParameters & p)
  : Material(p), _gravity(getParam<RealVectorValue>("gravity")),
    _density(declareADProperty<Real>(getParam<MaterialPropertyName>("mixture_density_name"))),
    _force(declareADProperty<RealVectorValue>(getParam<MaterialPropertyName>("gravity_force_name")))
{
  for (const auto & name : getParam<std::vector<MaterialPropertyName>>("bulk_density_names"))
    _densities.push_back(&getADMaterialProperty<Real>(name));
  if (_densities.empty())
    paramError("bulk_density_names", "Supply at least one phase density.");
}
void ADMixtureGravityMaterial::computeQpProperties()
{
  _density[_qp] = 0.0;
  for (const auto * density : _densities)
    _density[_qp] += (*density)[_qp];
  _force[_qp] = _density[_qp] * _gravity;
}
