#include "SaturationSimplexGeneralDamper.h"

#include "MooseMesh.h"
#include "MooseVariableFE.h"
#include "SystemBase.h"

#include "libmesh/dof_map.h"
#include "libmesh/system.h"

#include <algorithm>
#include <cmath>

registerMooseObject("MulticomponentReactiveFlowApp", SaturationSimplexGeneralDamper);

InputParameters
SaturationSimplexGeneralDamper::validParams()
{
  InputParameters params = GeneralDamper::validParams();
  params.addClassDescription(
      "Limits Newton updates so two continuous-Bernstein-backbone plus P0-enrichment "
      "saturations remain nonnegative and their sum stays below its upper bound.");
  params.addRequiredParam<NonlinearVariableName>("first_backbone", "First continuous backbone.");
  params.addRequiredParam<NonlinearVariableName>("second_backbone", "Second continuous backbone.");
  params.addRequiredParam<NonlinearVariableName>("first_enrichment", "First P0 enrichment.");
  params.addRequiredParam<NonlinearVariableName>("second_enrichment", "Second P0 enrichment.");
  params.addRangeCheckedParam<Real>("maximum_total_saturation",
                                    1.0 - 1.0e-10,
                                    "maximum_total_saturation>0 & maximum_total_saturation<=1",
                                    "Largest admissible sum of the two reconstructed saturations.");
  params.addRangeCheckedParam<Real>(
      "fraction_to_boundary",
      0.9,
      "fraction_to_boundary>0 & fraction_to_boundary<1",
      "Fraction of the admissible Newton step used to retain interior slack.");
  return params;
}

SaturationSimplexGeneralDamper::SaturationSimplexGeneralDamper(
    const InputParameters & parameters)
  : GeneralDamper(parameters),
    _first_backbone_number(
        _sys.getFieldVariable<Real>(0, getParam<NonlinearVariableName>("first_backbone")).number()),
    _second_backbone_number(
        _sys.getFieldVariable<Real>(0, getParam<NonlinearVariableName>("second_backbone")).number()),
    _first_enrichment_number(
        _sys.getFieldVariable<Real>(0, getParam<NonlinearVariableName>("first_enrichment")).number()),
    _second_enrichment_number(
        _sys.getFieldVariable<Real>(0, getParam<NonlinearVariableName>("second_enrichment")).number()),
    _maximum_total_saturation(getParam<Real>("maximum_total_saturation")),
    _fraction_to_boundary(getParam<Real>("fraction_to_boundary"))
{
}

Real
SaturationSimplexGeneralDamper::computeDamping(const NumericVector<Number> & solution,
                                               const NumericVector<Number> & update)
{
  Real damping = 1.0;
  const auto & dof_map = _sys.system().get_dof_map();
  const auto & first_fe_type = _sys.system().variable_type(_first_backbone_number);
  const auto & second_fe_type = _sys.system().variable_type(_second_backbone_number);
  if (first_fe_type != second_fe_type)
    mooseError(name(), ": saturation backbones must use matching finite-element spaces.");

  std::vector<dof_id_type> first_backbone_dofs;
  std::vector<dof_id_type> second_backbone_dofs;
  std::vector<dof_id_type> first_enrichment_dofs;
  std::vector<dof_id_type> second_enrichment_dofs;

  for (const auto * elem : _sys.mesh().getMesh().active_local_element_ptr_range())
  {
    dof_map.dof_indices(elem, first_backbone_dofs, _first_backbone_number);
    dof_map.dof_indices(elem, second_backbone_dofs, _second_backbone_number);
    dof_map.dof_indices(elem, first_enrichment_dofs, _first_enrichment_number);
    dof_map.dof_indices(elem, second_enrichment_dofs, _second_enrichment_number);

    if (first_backbone_dofs.size() != second_backbone_dofs.size())
      mooseError(name(), ": saturation backbone degrees of freedom do not match their basis.");
    if (first_enrichment_dofs.size() != 1 || second_enrichment_dofs.size() != 1)
      mooseError(name(), ": each saturation enrichment must have one P0 coefficient per element.");

    const auto retain_upper_bound = [this, &damping](const Real candidate,
                                                     const Real old,
                                                     const Real step,
                                                     const Real bound)
    {
      if (candidate <= bound || old > bound || std::abs(step) <= 1.0e-30)
        return;

      const Real boundary_damping = (old - bound) / step;
      damping = std::min(
          damping, _fraction_to_boundary * std::clamp(boundary_damping, 0.0, 1.0));
    };
    const auto retain_lower_bound = [this, &damping](const Real candidate,
                                                     const Real old,
                                                     const Real step,
                                                     const Real bound)
    {
      if (candidate >= bound || old < bound || std::abs(step) <= 1.0e-30)
        return;

      const Real boundary_damping = (old - bound) / step;
      damping = std::min(
          damping, _fraction_to_boundary * std::clamp(boundary_damping, 0.0, 1.0));
    };
    const auto first_enrichment = first_enrichment_dofs[0];
    const auto second_enrichment = second_enrichment_dofs[0];
    for (MooseIndex(first_backbone_dofs) i = 0; i < first_backbone_dofs.size(); ++i)
    {
      const Real first_candidate =
          solution(first_backbone_dofs[i]) + solution(first_enrichment);
      const Real second_candidate =
          solution(second_backbone_dofs[i]) + solution(second_enrichment);
      const Real first_update = update(first_backbone_dofs[i]) + update(first_enrichment);
      const Real second_update = update(second_backbone_dofs[i]) + update(second_enrichment);

      // MOOSE uses new = old - damping * update.  Bernstein basis functions
      // are nonnegative and sum to one, so coefficientwise limits preserve
      // the reconstructed fields throughout the element.
      retain_lower_bound(first_candidate, first_candidate + first_update, first_update, 0.0);
      retain_lower_bound(second_candidate,
                         second_candidate + second_update,
                         second_update,
                         0.0);
      retain_upper_bound(first_candidate + second_candidate,
                         first_candidate + second_candidate + first_update + second_update,
                         first_update + second_update,
                         _maximum_total_saturation);
    }
  }

  return damping;
}
