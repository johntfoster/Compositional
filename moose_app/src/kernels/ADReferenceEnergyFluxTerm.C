#include "ADReferenceEnergyFluxTerm.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADReferenceEnergyFluxTerm);

InputParameters
ADReferenceEnergyFluxTerm::validParams()
{
  InputParameters params = ADKernel::validParams();
  params.addClassDescription(
      "Atomic scale*Grad(test) dot Q term. Instantiate independently for Fourier/Dufour "
      "nonadvective heat flux and skeleton-relative internal-energy advection.");
  params.addRequiredParam<MaterialPropertyName>("reference_flux_name",
                                                 "AD solid-reference energy flux.");
  params.addParam<Real>("scale", 1.0, "Signed weak-flux multiplier.");
  return params;
}

ADReferenceEnergyFluxTerm::ADReferenceEnergyFluxTerm(const InputParameters & parameters)
  : ADKernel(parameters),
    _flux(getADMaterialProperty<RealVectorValue>("reference_flux_name")),
    _scale(getParam<Real>("scale"))
{
}

ADReal
ADReferenceEnergyFluxTerm::computeQpResidual()
{
  return _scale * _grad_test[_i][_qp] * _flux[_qp];
}
