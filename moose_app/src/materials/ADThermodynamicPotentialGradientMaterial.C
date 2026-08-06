#include "ADThermodynamicPotentialGradientMaterial.h"

registerMooseObject("MulticomponentReactiveFlowApp",
                    ADThermodynamicPotentialGradientMaterial);

InputParameters
ADThermodynamicPotentialGradientMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Forms an AD thermodynamic-potential gradient from named constitutive "
      "derivatives and state gradients using the chain rule.");
  params.addRequiredParam<std::vector<MaterialPropertyName>>(
      "potential_derivative_names", "Properties d(psi)/d(y_a), in state order.");
  params.addRequiredParam<std::vector<MaterialPropertyName>>(
      "state_gradient_names", "Properties Grad_X(y_a), in the same state order.");
  params.addParam<MaterialPropertyName>(
      "direct_gradient_name", "",
      "Optional explicit reference gradient of psi at fixed state.");
  params.addRequiredParam<MaterialPropertyName>(
      "potential_gradient_name", "Output property Grad_X(psi).");
  return params;
}

ADThermodynamicPotentialGradientMaterial::ADThermodynamicPotentialGradientMaterial(
    const InputParameters & parameters)
  : Material(parameters),
    _direct_gradient(
        getParam<MaterialPropertyName>("direct_gradient_name").empty()
            ? nullptr
            : &getADMaterialProperty<RealVectorValue>("direct_gradient_name")),
    _potential_gradient(declareADProperty<RealVectorValue>(
        getParam<MaterialPropertyName>("potential_gradient_name")))
{
  const auto derivative_names =
      getParam<std::vector<MaterialPropertyName>>("potential_derivative_names");
  const auto gradient_names =
      getParam<std::vector<MaterialPropertyName>>("state_gradient_names");

  if (derivative_names.empty())
    paramError("potential_derivative_names", "Supply at least one state derivative.");
  if (derivative_names.size() != gradient_names.size())
    paramError("state_gradient_names",
               "Supply exactly one state gradient for every potential derivative.");

  _derivatives.reserve(derivative_names.size());
  _state_gradients.reserve(gradient_names.size());
  for (const auto & name : derivative_names)
    _derivatives.push_back(&getADMaterialProperty<Real>(name));
  for (const auto & name : gradient_names)
    _state_gradients.push_back(&getADMaterialProperty<RealVectorValue>(name));
}

void
ADThermodynamicPotentialGradientMaterial::computeQpProperties()
{
  _potential_gradient[_qp].zero();
  if (_direct_gradient)
    _potential_gradient[_qp] = (*_direct_gradient)[_qp];

  for (std::size_t a = 0; a < _derivatives.size(); ++a)
    _potential_gradient[_qp] += (*_derivatives[a])[_qp] * (*_state_gradients[a])[_qp];
}
