#include "ADBinaryFluidStorageMaterial.h"

#include "metaphysicl/raw_type.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADBinaryFluidStorageMaterial);

InputParameters
ADBinaryFluidStorageMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Computes isothermal one-component fluid density, solid-reference accumulation, and "
      "the consistent AD storage rate for a binary solid-fluid specialization.");
  params.addParam<MaterialPropertyName>(
      "solid_jacobian_name", "solid_reference_J", "Solid-reference Jacobian J_s.");
  params.addParam<MaterialPropertyName>(
      "solid_jacobian_rate_name", "solid_reference_J_dot", "Material time rate of J_s.");
  params.addParam<MaterialPropertyName>(
      "pressure_name", "p_total", "Reconstructed gauge pore pressure.");
  params.addParam<MaterialPropertyName>(
      "pressure_rate_name", "p_total_dot", "Material time rate of gauge pore pressure.");
  params.addRequiredCoupledVar("solid_volume_fraction", "Aggregate solid volume fraction phi_s.");
  params.addParam<MooseEnum>(
      "fluid_eos",
      MooseEnum("ideal_gas constant_bulk_modulus", "ideal_gas"),
      "Isothermal intrinsic-density closure. The ideal_gas option uses gauge pressure and "
      "reference_absolute_pressure; constant_bulk_modulus uses rho=rho_0 exp(p/K_f).");
  params.addRequiredRangeCheckedParam<Real>(
      "reference_density", "reference_density>0", "Fluid density at the reference pressure.");
  params.addRangeCheckedParam<Real>("reference_absolute_pressure",
                                    101325.0,
                                    "reference_absolute_pressure>0",
                                    "Absolute pressure p_0 associated with reference_density.");
  params.addParam<Real>(
      "bulk_modulus",
      0.0,
      "Positive constant fluid bulk modulus K_f required by fluid_eos=constant_bulk_modulus.");
  params.addParam<MaterialPropertyName>(
      "intrinsic_density_name", "binary_fluid_intrinsic_density", "Fluid intrinsic density.");
  params.addParam<MaterialPropertyName>("reference_component_accumulation_name",
                                        "binary_fluid_reference_component_accumulation",
                                        "J_s(1-phi_s)rho_f.");
  params.addParam<MaterialPropertyName>("reference_component_storage_rate_name",
                                        "binary_fluid_reference_component_storage_rate",
                                        "Material time rate of J_s(1-phi_s)rho_f.");
  return params;
}

ADBinaryFluidStorageMaterial::ADBinaryFluidStorageMaterial(const InputParameters & parameters)
  : Material(parameters),
    _J(getADMaterialProperty<Real>("solid_jacobian_name")),
    _J_dot(getADMaterialProperty<Real>("solid_jacobian_rate_name")),
    _pressure(getADMaterialProperty<Real>("pressure_name")),
    _pressure_dot(getADMaterialProperty<Real>("pressure_rate_name")),
    _solid_volume_fraction(adCoupledValue("solid_volume_fraction")),
    _solid_volume_fraction_dot(adCoupledDot("solid_volume_fraction")),
    _fluid_eos(getParam<MooseEnum>("fluid_eos")),
    _reference_density(getParam<Real>("reference_density")),
    _reference_absolute_pressure(getParam<Real>("reference_absolute_pressure")),
    _bulk_modulus(getParam<Real>("bulk_modulus")),
    _intrinsic_density(
        declareADProperty<Real>(getParam<MaterialPropertyName>("intrinsic_density_name"))),
    _reference_component_accumulation(declareADProperty<Real>(
        getParam<MaterialPropertyName>("reference_component_accumulation_name"))),
    _reference_component_accumulation_old(getMaterialPropertyOld<Real>(
        getParam<MaterialPropertyName>("reference_component_accumulation_name"))),
    _reference_component_storage_rate(declareADProperty<Real>(
        getParam<MaterialPropertyName>("reference_component_storage_rate_name")))
{
  if (_fluid_eos == "constant_bulk_modulus" && _bulk_modulus <= 0.0)
    paramError("bulk_modulus",
               "Supply a positive bulk_modulus when fluid_eos=constant_bulk_modulus.");
}

void
ADBinaryFluidStorageMaterial::initQpStatefulProperties()
{
  if (_fluid_eos == "ideal_gas")
    _intrinsic_density[_qp] =
        _reference_density * (1.0 + _pressure[_qp] / _reference_absolute_pressure);
  else
    _intrinsic_density[_qp] = _reference_density * exp(_pressure[_qp] / _bulk_modulus);

  _reference_component_accumulation[_qp] =
      _J[_qp] * (1.0 - _solid_volume_fraction[_qp]) * _intrinsic_density[_qp];
  _reference_component_storage_rate[_qp] = 0.0;
}

void
ADBinaryFluidStorageMaterial::computeQpProperties()
{
  ADReal intrinsic_density_dot;
  if (_fluid_eos == "ideal_gas")
  {
    _intrinsic_density[_qp] =
        _reference_density * (1.0 + _pressure[_qp] / _reference_absolute_pressure);
    intrinsic_density_dot = _reference_density * _pressure_dot[_qp] / _reference_absolute_pressure;
  }
  else
  {
    _intrinsic_density[_qp] = _reference_density * exp(_pressure[_qp] / _bulk_modulus);
    intrinsic_density_dot = _intrinsic_density[_qp] * _pressure_dot[_qp] / _bulk_modulus;
  }
  if (MetaPhysicL::raw_value(_intrinsic_density[_qp]) <= 0.0)
    mooseError("ADBinaryFluidStorageMaterial computed nonpositive intrinsic fluid density.");

  const ADReal fluid_volume_fraction = 1.0 - _solid_volume_fraction[_qp];
  _reference_component_accumulation[_qp] =
      _J[_qp] * fluid_volume_fraction * _intrinsic_density[_qp];

  // The benchmark uses implicit Euler.  Differencing the complete accumulation
  // preserves the discrete component balance exactly; applying backward
  // differences to the factors and then using the continuous product rule does
  // not preserve a nonlinear product at finite time step.
  _reference_component_storage_rate[_qp] =
      _fe_problem.isTransient()
          ? (_reference_component_accumulation[_qp] -
             _reference_component_accumulation_old[_qp]) /
                _dt
          : 0.0;
}
