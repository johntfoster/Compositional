#include "ADPoreVolumeRestrictionMaterial.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADPoreVolumeRestrictionMaterial);

InputParameters
ADPoreVolumeRestrictionMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Assembles every shared-lambda pore-volume restriction in manuscript Eq. "
      "(MC_volume_fraction_restrictions) for arbitrary solid and fluid phase counts.");
  params.addRequiredCoupledVar("pore_volume_multiplier", "Common pore-volume multiplier lambda.");
  params.addRequiredCoupledVar("fluid_saturations", "One pore saturation S_f per fluid phase.");
  params.addRequiredParam<std::vector<MaterialPropertyName>>(
      "solid_pressure_names", "Solid phase intrinsic-pressure properties.");
  params.addRequiredParam<std::vector<MaterialPropertyName>>(
      "solid_omega_plus_names", "Solid reversible omega-plus properties.");
  params.addRequiredParam<std::vector<MaterialPropertyName>>(
      "fluid_pressure_names", "Fluid phase intrinsic-pressure properties.");
  params.addRequiredParam<std::vector<MaterialPropertyName>>(
      "fluid_omega_plus_names", "Fluid reversible omega-plus properties.");
  params.addRequiredParam<std::vector<MaterialPropertyName>>(
      "fluid_gamma_names", "Fluid generalized saturation-force properties gamma_f.");
  params.addRequiredParam<std::vector<MaterialPropertyName>>(
      "solid_restriction_names", "One output residual name per solid phase.");
  params.addParam<MaterialPropertyName>("fluid_restriction_name",
                                        "total_fluid_pore_volume_restriction",
                                        "Total-fluid restriction output name.");
  params.addParam<MaterialPropertyName>("saturation_sum_residual_name",
                                        "fluid_saturation_sum_residual",
                                        "Sum_f S_f-1 diagnostic output name.");
  return params;
}

ADPoreVolumeRestrictionMaterial::ADPoreVolumeRestrictionMaterial(
    const InputParameters & parameters)
  : Material(parameters),
    _lambda(adCoupledValue("pore_volume_multiplier")),
    _fluid_residual(
        declareADProperty<Real>(getParam<MaterialPropertyName>("fluid_restriction_name"))),
    _saturation_sum_residual(
        declareADProperty<Real>(getParam<MaterialPropertyName>("saturation_sum_residual_name")))
{
  const auto solid_p = getParam<std::vector<MaterialPropertyName>>("solid_pressure_names");
  const auto solid_omega =
      getParam<std::vector<MaterialPropertyName>>("solid_omega_plus_names");
  const auto fluid_p = getParam<std::vector<MaterialPropertyName>>("fluid_pressure_names");
  const auto fluid_omega =
      getParam<std::vector<MaterialPropertyName>>("fluid_omega_plus_names");
  const auto fluid_gamma = getParam<std::vector<MaterialPropertyName>>("fluid_gamma_names");
  const auto solid_outputs =
      getParam<std::vector<MaterialPropertyName>>("solid_restriction_names");
  const auto n_solid = solid_p.size();
  const auto n_fluid = coupledComponents("fluid_saturations");
  if (n_solid == 0)
    paramError("solid_pressure_names", "Supply at least one solid phase.");
  if (n_fluid == 0)
    paramError("fluid_saturations", "Supply at least one fluid phase.");
  if (solid_omega.size() != n_solid || solid_outputs.size() != n_solid)
    paramError("solid_restriction_names",
               "Solid pressure, omega-plus, and output lists must have identical sizes.");
  if (fluid_p.size() != n_fluid || fluid_omega.size() != n_fluid ||
      fluid_gamma.size() != n_fluid)
    paramError("fluid_pressure_names",
               "Supply one pressure, omega-plus, and gamma property per fluid saturation.");

  for (const auto s : make_range(n_solid))
  {
    _solid_pressures.push_back(&getADMaterialProperty<Real>(solid_p[s]));
    _solid_omega_plus.push_back(&getADMaterialProperty<Real>(solid_omega[s]));
    _solid_residuals.push_back(&declareADProperty<Real>(solid_outputs[s]));
  }
  for (const auto f : make_range(n_fluid))
  {
    _fluid_saturations.push_back(&adCoupledValue("fluid_saturations", f));
    _fluid_pressures.push_back(&getADMaterialProperty<Real>(fluid_p[f]));
    _fluid_omega_plus.push_back(&getADMaterialProperty<Real>(fluid_omega[f]));
    _fluid_gamma.push_back(&getADMaterialProperty<Real>(fluid_gamma[f]));
  }
}

void
ADPoreVolumeRestrictionMaterial::computeQpProperties()
{
  for (const auto s : index_range(_solid_residuals))
    (*_solid_residuals[s])[_qp] =
        _lambda[_qp] + (*_solid_pressures[s])[_qp] - (*_solid_omega_plus[s])[_qp];

  _fluid_residual[_qp] = _lambda[_qp];
  _saturation_sum_residual[_qp] = -1.0;
  for (const auto f : index_range(_fluid_saturations))
  {
    const ADReal saturation = (*_fluid_saturations[f])[_qp];
    _fluid_residual[_qp] += saturation * ((*_fluid_pressures[f])[_qp] -
                                           (*_fluid_omega_plus[f])[_qp] -
                                           (*_fluid_gamma[f])[_qp]);
    _saturation_sum_residual[_qp] += saturation;
  }
}
