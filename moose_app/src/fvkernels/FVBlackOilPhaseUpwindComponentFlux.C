#include "FVBlackOilPhaseUpwindComponentFlux.h"

#include "MathFVUtils.h"
#include "metaphysicl/raw_type.h"

#include <cmath>

registerADMooseObject("MulticomponentReactiveFlowApp", FVBlackOilPhaseUpwindComponentFlux);

InputParameters
FVBlackOilPhaseUpwindComponentFlux::validParams()
{
  InputParameters params = FVFluxKernel::validParams();
  params.addClassDescription(
      "Assembles one conservative fixed-reference black-oil component flux by applying "
      "first-order upstream weighting separately to every Darcy phase flux.");
  params.addRequiredParam<std::vector<MaterialPropertyName>>(
      "phase_pressure_names", "Phase-pressure properties, one per transported phase.");
  params.addRequiredParam<std::vector<MaterialPropertyName>>(
      "phase_intrinsic_density_names", "Intrinsic phase-density properties.");
  params.addRequiredParam<std::vector<MaterialPropertyName>>(
      "phase_viscosity_names", "Phase-viscosity properties.");
  params.addRequiredParam<std::vector<MaterialPropertyName>>(
      "phase_relative_permeability_names", "Phase relative-permeability properties.");
  params.addRequiredParam<std::vector<MaterialPropertyName>>(
      "phase_component_mass_fraction_names", "Selected component mass fraction in each phase.");
  params.addRequiredParam<MaterialPropertyName>(
      "permeability_name", "Scalar absolute-permeability property.");
  params.addParam<RealVectorValue>(
      "gravity", RealVectorValue(0, 0, 0), "Spatial gravity vector in the fixed reference frame.");
  params.set<unsigned short>("ghost_layers") = 2;
  return params;
}

FVBlackOilPhaseUpwindComponentFlux::FVBlackOilPhaseUpwindComponentFlux(
    const InputParameters & parameters)
  : FVFluxKernel(parameters),
    _permeability(
        getADMaterialProperty<Real>(getParam<MaterialPropertyName>("permeability_name"))),
    _permeability_neighbor(
        getNeighborADMaterialProperty<Real>(getParam<MaterialPropertyName>("permeability_name"))),
    _gravity(getParam<RealVectorValue>("gravity"))
{
  const auto & pressure_names =
      getParam<std::vector<MaterialPropertyName>>("phase_pressure_names");
  const auto & density_names =
      getParam<std::vector<MaterialPropertyName>>("phase_intrinsic_density_names");
  const auto & viscosity_names =
      getParam<std::vector<MaterialPropertyName>>("phase_viscosity_names");
  const auto & relative_permeability_names =
      getParam<std::vector<MaterialPropertyName>>("phase_relative_permeability_names");
  const auto & fraction_names =
      getParam<std::vector<MaterialPropertyName>>("phase_component_mass_fraction_names");

  const auto phase_count = pressure_names.size();
  if (!phase_count)
    paramError("phase_pressure_names", "Supply at least one transported phase.");
  if (density_names.size() != phase_count || viscosity_names.size() != phase_count ||
      relative_permeability_names.size() != phase_count || fraction_names.size() != phase_count)
    paramError("phase_pressure_names", "Supply one pressure, density, viscosity, relative "
                                       "permeability, and component fraction for every phase.");

  for (const auto i : make_range(phase_count))
  {
    _phase_pressure.push_back(&getADMaterialProperty<Real>(pressure_names[i]));
    _phase_pressure_neighbor.push_back(&getNeighborADMaterialProperty<Real>(pressure_names[i]));
    _phase_density.push_back(&getADMaterialProperty<Real>(density_names[i]));
    _phase_density_neighbor.push_back(&getNeighborADMaterialProperty<Real>(density_names[i]));
    _phase_viscosity.push_back(&getADMaterialProperty<Real>(viscosity_names[i]));
    _phase_viscosity_neighbor.push_back(
        &getNeighborADMaterialProperty<Real>(viscosity_names[i]));
    _phase_relative_permeability.push_back(
        &getADMaterialProperty<Real>(relative_permeability_names[i]));
    _phase_relative_permeability_neighbor.push_back(
        &getNeighborADMaterialProperty<Real>(relative_permeability_names[i]));
    _phase_component_mass_fraction.push_back(
        &getADMaterialProperty<Real>(fraction_names[i]));
    _phase_component_mass_fraction_neighbor.push_back(
        &getNeighborADMaterialProperty<Real>(fraction_names[i]));
  }
}

ADReal
FVBlackOilPhaseUpwindComponentFlux::computeQpResidual()
{
  if (onBoundary(*_face_info))
    return 0.0;

  const ADReal face_permeability =
      MetaPhysicL::raw_value(_permeability[_qp]) > 0.0 &&
              MetaPhysicL::raw_value(_permeability_neighbor[_qp]) > 0.0
          ? Moose::FV::harmonicInterpolation(
                _permeability[_qp], _permeability_neighbor[_qp], *_face_info, true)
          : 0.0;
  const Real gravity_normal = _gravity * _normal;
  ADReal component_flux = 0.0;

  for (const auto i : make_range(_phase_pressure.size()))
  {
    const ADReal density_average =
        0.5 * ((*_phase_density[i])[_qp] + (*_phase_density_neighbor[i])[_qp]);
    const ADReal darcy_driver =
        ((*_phase_pressure[i])[_qp] - (*_phase_pressure_neighbor[i])[_qp]) /
            _face_info->dCNMag() +
        density_average * gravity_normal;
    const bool element_is_upwind = MetaPhysicL::raw_value(darcy_driver) >= 0.0;

    const ADReal density = element_is_upwind ? (*_phase_density[i])[_qp]
                                             : (*_phase_density_neighbor[i])[_qp];
    const ADReal viscosity = element_is_upwind ? (*_phase_viscosity[i])[_qp]
                                               : (*_phase_viscosity_neighbor[i])[_qp];
    const ADReal relative_permeability =
        element_is_upwind ? (*_phase_relative_permeability[i])[_qp]
                          : (*_phase_relative_permeability_neighbor[i])[_qp];
    const ADReal component_fraction =
        element_is_upwind ? (*_phase_component_mass_fraction[i])[_qp]
                          : (*_phase_component_mass_fraction_neighbor[i])[_qp];

    if (MetaPhysicL::raw_value(viscosity) <= 0.0)
      mooseError(name(), ": phase viscosity must be positive.");
    if (MetaPhysicL::raw_value(relative_permeability) < 0.0)
      mooseError(name(), ": phase relative permeability must be nonnegative.");

    component_flux += component_fraction * density * relative_permeability / viscosity *
                      face_permeability * darcy_driver;
  }

  return component_flux;
}
