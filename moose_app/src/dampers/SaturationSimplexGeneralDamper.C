#include "SaturationSimplexGeneralDamper.h"

#include "MooseMesh.h"
#include "MooseVariableFE.h"
#include "SystemBase.h"

#include "libmesh/dof_map.h"
#include "libmesh/fe_base.h"
#include "libmesh/quadrature_gauss.h"
#include "libmesh/system.h"

#include <algorithm>
#include <cmath>

registerMooseObject("MulticomponentReactiveFlowApp", SaturationSimplexGeneralDamper);

InputParameters
SaturationSimplexGeneralDamper::validParams()
{
  InputParameters params = GeneralDamper::validParams();
  params.addClassDescription(
      "Limits Newton updates so the sum of two continuous-backbone plus P0-enrichment "
      "saturations remains below its upper bound at the element quadrature points.");
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

  const auto mesh_dimension = _sys.mesh().getMesh().mesh_dimension();
  auto fe = libMesh::FEBase::build(mesh_dimension, first_fe_type);
  // Fifth-order Gauss sampling covers the material quadrature used by the
  // coupled P2 saturation residuals and detects interior extrema missed by
  // the finite-element type's lower default rule.
  libMesh::QGauss quadrature(mesh_dimension, FIFTH);
  fe->attach_quadrature_rule(&quadrature);
  const auto & phi = fe->get_phi();
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

    fe->reinit(elem);
    if (first_backbone_dofs.size() != second_backbone_dofs.size() ||
        first_backbone_dofs.size() != phi.size())
      mooseError(name(), ": saturation backbone degrees of freedom do not match their basis.");
    if (first_enrichment_dofs.size() != 1 || second_enrichment_dofs.size() != 1)
      mooseError(name(), ": each saturation enrichment must have one P0 coefficient per element.");

    for (unsigned int qp = 0; qp < quadrature.n_points(); ++qp)
    {
      const auto first_enrichment = first_enrichment_dofs[0];
      const auto second_enrichment = second_enrichment_dofs[0];
      Real first_candidate = solution(first_enrichment);
      Real second_candidate = solution(second_enrichment);
      Real first_update = update(first_enrichment);
      Real second_update = update(second_enrichment);
      for (MooseIndex(first_backbone_dofs) i = 0; i < first_backbone_dofs.size(); ++i)
      {
        first_candidate += phi[i][qp] * solution(first_backbone_dofs[i]);
        second_candidate += phi[i][qp] * solution(second_backbone_dofs[i]);
        first_update += phi[i][qp] * update(first_backbone_dofs[i]);
        second_update += phi[i][qp] * update(second_backbone_dofs[i]);
      }

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

      // MOOSE uses new = old - damping * update.
      retain_upper_bound(first_candidate + second_candidate,
                         first_candidate + second_candidate + first_update + second_update,
                         first_update + second_update,
                         _maximum_total_saturation);
    }
  }

  return damping;
}
