#include "PlasticDistensionAction.h"

#include "FEProblem.h"
#include "Factory.h"
#include "MooseMesh.h"

registerMooseAction("MulticomponentReactiveFlowApp", PlasticDistensionAction, "add_kernel");

InputParameters
PlasticDistensionAction::validParams()
{
  InputParameters params = Action::validParams();
  params.addClassDescription(
      "Selects exactly one manuscript plastic-distension representation and creates either all "
      "dim*dim ADPlasticDistensionEvolution kernels or one "
      "ADScalarPlasticDistensionEvolution kernel.");
  MooseEnum modes("tensor scalar");
  params.addRequiredParam<MooseEnum>("mode", modes, "Plastic-distension representation.");
  params.addParam<std::vector<VariableName>>(
      "tensor_variables", {}, "Row-major dim*dim components of the tensor A_p.");
  params.addParam<NonlinearVariableName>(
      "scalar_variable", "Positive scalar plastic distension a_p.");
  params.addParam<MaterialPropertyName>("tensor_log_rate_name",
                                        "plastic_distension_log_rate",
                                        "Tensor plastic-distension logarithmic-rate property.");
  params.addParam<MaterialPropertyName>("scalar_log_rate_name",
                                        "scalar_plastic_distension_log_rate",
                                        "Scalar plastic-distension logarithmic-rate property.");
  params.addParam<FunctionName>(
      "tensor_forcing", "0", "Optional manufactured forcing for every tensor component.");
  params.addParam<std::vector<FunctionName>>(
      "tensor_forcing_names",
      {},
      "Optional row-major dim*dim component forcings; mutually exclusive with tensor_forcing.");
  params.addParam<std::vector<SubdomainName>>(
      "block", "Subdomains on which the selected evolution kernels act.");
  return params;
}

PlasticDistensionAction::PlasticDistensionAction(const InputParameters & parameters)
  : Action(parameters)
{
}

void
PlasticDistensionAction::act()
{
  const auto & mode = getParam<MooseEnum>("mode");
  const auto & tensor_variables = getParam<std::vector<VariableName>>("tensor_variables");
  const bool has_scalar = isParamValid("scalar_variable");

  if (mode == "tensor")
  {
    if (has_scalar)
      paramError("scalar_variable", "Do not provide scalar_variable when mode=tensor.");

    const unsigned int dim = _problem->mesh().dimension();
    if (tensor_variables.size() != dim * dim)
      paramError("tensor_variables",
                 "mode=tensor requires exactly dim*dim row-major tensor variables; received ",
                 tensor_variables.size(),
                 " for mesh dimension ",
                 dim,
                 ".");
    const auto & tensor_forcings =
        getParam<std::vector<FunctionName>>("tensor_forcing_names");
    if (isParamSetByUser("tensor_forcing") && !tensor_forcings.empty())
      paramError("tensor_forcing_names",
                 "Choose one common tensor_forcing or row-major tensor_forcing_names, not both.");
    if (!tensor_forcings.empty() && tensor_forcings.size() != dim * dim)
      paramError("tensor_forcing_names",
                 "Supply exactly dim*dim row-major component forcings or leave the list empty.");

    for (const auto row : make_range(dim))
      for (const auto column : make_range(dim))
      {
        InputParameters kernel_params =
            _factory.getValidParams("ADPlasticDistensionEvolution");
        kernel_params.set<NonlinearVariableName>("variable") =
            tensor_variables[row * dim + column];
        kernel_params.set<unsigned int>("row") = row;
        kernel_params.set<unsigned int>("column") = column;
        kernel_params.set<std::vector<VariableName>>("plastic_distension_tensor") =
            tensor_variables;
        kernel_params.set<MaterialPropertyName>("plastic_distension_log_rate_name") =
            getParam<MaterialPropertyName>("tensor_log_rate_name");
        kernel_params.set<FunctionName>("forcing") =
            tensor_forcings.empty() ? getParam<FunctionName>("tensor_forcing")
                                    : tensor_forcings[row * dim + column];
        if (isParamValid("block"))
          kernel_params.set<std::vector<SubdomainName>>("block") =
              getParam<std::vector<SubdomainName>>("block");

        _problem->addKernel("ADPlasticDistensionEvolution",
                            _name + "_tensor_" + std::to_string(row) + "_" +
                                std::to_string(column),
                            kernel_params);
      }
  }
  else
  {
    if (!tensor_variables.empty())
      paramError("tensor_variables", "Do not provide tensor_variables when mode=scalar.");
    if (!has_scalar)
      paramError("scalar_variable", "mode=scalar requires scalar_variable.");

    InputParameters kernel_params =
        _factory.getValidParams("ADScalarPlasticDistensionEvolution");
    kernel_params.set<NonlinearVariableName>("variable") =
        getParam<NonlinearVariableName>("scalar_variable");
    kernel_params.set<MaterialPropertyName>("plastic_distension_log_rate_name") =
        getParam<MaterialPropertyName>("scalar_log_rate_name");
    if (isParamValid("block"))
      kernel_params.set<std::vector<SubdomainName>>("block") =
          getParam<std::vector<SubdomainName>>("block");
    _problem->addKernel(
        "ADScalarPlasticDistensionEvolution", _name + "_scalar", kernel_params);
  }
}
