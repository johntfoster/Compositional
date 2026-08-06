#include "CoefficientBounds.h"

#include "FEProblemBase.h"
#include "PetscSupport.h"
#include "SystemBase.h"

#include "libmesh/dof_map.h"
#include "libmesh/threads.h"

registerMooseObject("MulticomponentReactiveFlowApp", CoefficientBounds);

namespace
{
Threads::spin_mutex coefficient_bounds_mutex;
}

InputParameters
CoefficientBounds::validParams()
{
  InputParameters params = AuxKernel::validParams();
  params.addClassDescription(
      "Sets a constant PETSc VI bound on every coefficient of a scalar finite-element variable.");
  params.addRequiredParam<NonlinearVariableName>("bounded_variable", "Variable to be bounded.");
  params.addRequiredParam<Real>("bound_value", "Constant coefficient bound.");
  params.addParam<MooseEnum>(
      "bound_type", MooseEnum("upper=0 lower=1", "upper"), "Upper or lower bound.");
  params.registerBase("Bounds");
  return params;
}

CoefficientBounds::CoefficientBounds(const InputParameters & parameters)
  : AuxKernel(parameters),
    _bound_type(static_cast<int>(getParam<MooseEnum>("bound_type")) == 0 ? BoundType::UPPER
                                                                         : BoundType::LOWER),
    _bound_value(getParam<Real>("bound_value")),
    _bounded_var(
        _nl_sys.getVariable(_tid, getParam<NonlinearVariableName>("bounded_variable"))),
    _bounded_vector(_nl_sys.getVector(_bound_type == BoundType::UPPER ? "upper_bound"
                                                                      : "lower_bound"))
{
  if (_bounded_var.isFV())
    paramError("bounded_variable", "CoefficientBounds is intended for finite-element variables.");
  if (_bounded_var.count() != 1)
    paramError("bounded_variable", "CoefficientBounds currently supports scalar variables only.");
}

void
CoefficientBounds::initialSetup()
{
  if (!Moose::PetscSupport::isSNESVI(*dynamic_cast<FEProblemBase *>(&_c_fe_problem)))
    mooseDoOnce(mooseWarning(
        "A variational-inequality SNES solver must be used with CoefficientBounds."));
}

Real
CoefficientBounds::computeValue()
{
  std::vector<dof_id_type> dof_indices;
  const auto & dof_map = _nl_sys.system().get_dof_map();
  dof_map.dof_indices(_current_elem, dof_indices, _bounded_var.number());

  const auto first_local = _bounded_vector.first_local_index();
  const auto last_local = _bounded_vector.last_local_index();
  Threads::spin_mutex::scoped_lock lock(coefficient_bounds_mutex);
  for (const auto dof : dof_indices)
    if (dof >= first_local && dof < last_local)
      _bounded_vector.set(dof, _bound_value);

  return 0.0;
}
