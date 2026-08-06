#include "ADUpwindReferenceComponentFluxDG.h"

#include "metaphysicl/raw_type.h"

#include <algorithm>

registerMooseObject("MulticomponentReactiveFlowApp", ADUpwindReferenceComponentFluxDG);

InputParameters
ADUpwindReferenceComponentFluxDG::validParams()
{
  InputParameters params = ADDGKernel::validParams();
  params.addClassDescription(
      "Assembles one conservative numerical component flux by upwinding every phase "
      "contribution with the sign of that phase's reference relative mass flux.");
  params.addRequiredParam<std::vector<MaterialPropertyName>>(
      "phase_reference_relative_mass_flux_names", "Reference relative mass flux for each phase.");
  params.addRequiredParam<std::vector<MaterialPropertyName>>(
      "phase_component_mass_fraction_names", "Component mass fraction in each phase.");
  params.addParam<MaterialPropertyName>(
      "mobility_name", "", "Optional mobility tensor for a discontinuous pressure penalty.");
  params.addRangeCheckedParam<Real>("sigma", 0.0, "sigma>=0", "Interior penalty multiplier.");
  return params;
}

ADUpwindReferenceComponentFluxDG::ADUpwindReferenceComponentFluxDG(
    const InputParameters & parameters)
  : ADDGKernel(parameters),
    _mobility(getParam<MaterialPropertyName>("mobility_name").empty()
                  ? nullptr
                  : &getADMaterialProperty<RankTwoTensor>(
                        getParam<MaterialPropertyName>("mobility_name"))),
    _mobility_neighbor(getParam<MaterialPropertyName>("mobility_name").empty()
                           ? nullptr
                           : &getNeighborADMaterialProperty<RankTwoTensor>(
                                 getParam<MaterialPropertyName>("mobility_name"))),
    _sigma(getParam<Real>("sigma"))
{
  const auto & flux_names =
      getParam<std::vector<MaterialPropertyName>>("phase_reference_relative_mass_flux_names");
  const auto & fraction_names =
      getParam<std::vector<MaterialPropertyName>>("phase_component_mass_fraction_names");
  if (flux_names.empty())
    paramError("phase_reference_relative_mass_flux_names", "Supply at least one phase flux.");
  if (flux_names.size() != fraction_names.size())
    paramError("phase_component_mass_fraction_names",
               "Supply exactly one component mass fraction for each phase flux.");

  for (std::size_t i = 0; i < flux_names.size(); ++i)
  {
    _phase_flux.push_back(&getADMaterialProperty<RealVectorValue>(flux_names[i]));
    _phase_flux_neighbor.push_back(
        &getNeighborADMaterialProperty<RealVectorValue>(flux_names[i]));
    _phase_fraction.push_back(&getADMaterialProperty<Real>(fraction_names[i]));
    _phase_fraction_neighbor.push_back(
        &getNeighborADMaterialProperty<Real>(fraction_names[i]));
  }
}

ADReal
ADUpwindReferenceComponentFluxDG::computeQpResidual(Moose::DGResidualType type)
{
  ADReal numerical_flux = 0.0;
  for (std::size_t i = 0; i < _phase_flux.size(); ++i)
  {
    const ADReal flux_element = (*_phase_flux[i])[_qp] * _normals[_qp];
    const ADReal flux_neighbor = (*_phase_flux_neighbor[i])[_qp] * _normals[_qp];
    const bool element_is_upwind =
        MetaPhysicL::raw_value(flux_element + flux_neighbor) >= 0.0;
    numerical_flux += element_is_upwind
                          ? (*_phase_fraction[i])[_qp] * flux_element
                          : (*_phase_fraction_neighbor[i])[_qp] * flux_neighbor;
  }

  if (_mobility)
  {
    const ADReal normal_mobility =
        0.5 * (_normals[_qp] * ((*_mobility)[_qp] * _normals[_qp]) +
               _normals[_qp] * ((*_mobility_neighbor)[_qp] * _normals[_qp]));
    numerical_flux += _sigma / std::min(_current_elem->hmin(), _neighbor_elem->hmin()) *
                      normal_mobility * (_u[_qp] - _u_neighbor[_qp]);
  }

  switch (type)
  {
    case Moose::Element:
      return numerical_flux * _test[_i][_qp];
    case Moose::Neighbor:
      return -numerical_flux * _test_neighbor[_i][_qp];
  }
  mooseError("Unsupported DG residual type.");
}
