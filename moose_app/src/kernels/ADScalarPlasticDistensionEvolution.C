#include "ADScalarPlasticDistensionEvolution.h"

#include "metaphysicl/raw_type.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADScalarPlasticDistensionEvolution);

InputParameters
ADScalarPlasticDistensionEvolution::validParams()
{
  InputParameters params = ADTimeKernel::validParams();
  params.addClassDescription(
      "Implements manuscript Eq. (MC_scalar_plastic_distension_flow_rule) as "
      "dot(a_p)/a_p minus the associated constitutive log rate.");
  params.addParam<MaterialPropertyName>("plastic_distension_log_rate_name",
                                        "scalar_plastic_distension_log_rate",
                                        "Associated scalar plastic-distension log-rate property.");
  return params;
}

ADScalarPlasticDistensionEvolution::ADScalarPlasticDistensionEvolution(
    const InputParameters & parameters)
  : ADTimeKernel(parameters),
    _plastic_distension_log_rate(
        getADMaterialProperty<Real>("plastic_distension_log_rate_name"))
{
}

ADReal
ADScalarPlasticDistensionEvolution::computeQpResidual()
{
  if (MetaPhysicL::raw_value(_u[_qp]) <= 0.0)
    mooseError(name(), ": scalar plastic distension must remain positive.");
  return _test[_i][_qp] *
         (_u_dot[_qp] / _u[_qp] - _plastic_distension_log_rate[_qp]);
}
