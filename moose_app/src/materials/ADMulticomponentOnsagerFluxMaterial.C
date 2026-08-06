#include "ADMulticomponentOnsagerFluxMaterial.h"

#include "metaphysicl/raw_type.h"

#include <algorithm>
#include <cmath>
#include <limits>

registerMooseObject("MulticomponentReactiveFlowApp",
                    ADMulticomponentOnsagerFluxMaterial);

InputParameters
ADMulticomponentOnsagerFluxMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Implements the tensor-valued reduced Onsager closures in "
      "eq:MC_relative_transport_closures. For N physical components, supply N-1 "
      "temperature-weighted spatial forces and an (N-1)-by-(N-1) block matrix of "
      "spatial mobility tensors D_ab. The material enforces D_ab=D_ba^T, checks positive "
      "definiteness on the active component-by-spatial coordinates, computes the independent "
      "current-volume mass fluxes, and reconstructs the reference-component flux so their sum "
      "is zero. Constant tensor blocks are assembled and audited once; state-dependent blocks "
      "retain per-quadrature-point reciprocity and positive-definiteness guards.");
  params.addRequiredParam<std::vector<MaterialPropertyName>>(
      "transport_force_names",
      "N-1 properties for F_beta=theta*grad((mu_hat_beta-mu_hat_N)/theta)+"
      "(z_beta-z_N)*grad(phi), with units of force per component mass.");
  params.addParam<std::vector<Real>>(
      "mobility_tensor_entries",
      {},
      "Optional constant reduced tensor matrix. List blocks D_ab in component-row-major order; "
      "within each block list the active dim-by-dim spatial entries in row-major order. Units "
      "must map the supplied force per mass to current-volume component mass flux.");
  params.addParam<std::vector<MaterialPropertyName>>(
      "mobility_tensor_property_names",
      {},
      "Optional component-row-major list of (N-1)^2 AD RankTwoTensor mobility properties.");
  params.addParam<std::vector<MaterialPropertyName>>(
      "mobility_tensor_component_property_names",
      {},
      "Optional AD scalar components of the reduced tensor matrix. List blocks in "
      "component-row-major order and each active dim-by-dim block in spatial-row-major order.");
  params.addRequiredParam<std::vector<MaterialPropertyName>>(
      "component_flux_names", "N-1 output names for the independent current component fluxes.");
  params.addRequiredParam<MaterialPropertyName>(
      "reference_component_flux_name",
      "Output name for j_N=-sum_{alpha!=N} j_alpha.");
  params.addCoupledVar(
      "temperature", "Positive absolute subsystem temperature used to convert power to entropy.");
  params.addParam<MaterialPropertyName>(
      "temperature_name",
      "",
      "Optional positive AD absolute-temperature property; replaces the coupled temperature.");
  params.addRangeCheckedParam<Real>(
      "symmetry_tolerance",
      1e-12,
      "symmetry_tolerance>=0",
      "Relative tolerance, scaled by the supplied mobility matrix, for D_ab-D_ba^T.");
  params.addRangeCheckedParam<Real>(
      "positive_definite_tolerance",
      1e-14,
      "positive_definite_tolerance>=0",
      "Minimum admissible block-Cholesky pivot relative to the mobility scale.");
  params.addParam<MaterialPropertyName>(
      "zero_sum_residual_name",
      "multicomponent_onsager_zero_sum_residual",
      "Vector audit property sum_alpha j_alpha, including the reconstructed reference flux.");
  params.addParam<MaterialPropertyName>(
      "reciprocity_residual_name",
      "multicomponent_onsager_reciprocity_residual",
      "Maximum active-coordinate absolute residual in D_ab-D_ba^T.");
  params.addParam<MaterialPropertyName>(
      "minimum_cholesky_pivot_name",
      "multicomponent_onsager_minimum_cholesky_pivot",
      "Minimum raw pivot from the active component-by-spatial Cholesky audit.");
  params.addParam<MaterialPropertyName>(
      "force_flux_power_density_name",
      "multicomponent_onsager_force_flux_power_density",
      "Sum_alpha F_alpha dot (-j_alpha), a nonnegative current-volume power density. This is "
      "theta times the physical entropy-production density.");
  params.addParam<MaterialPropertyName>(
      "entropy_production_name",
      "multicomponent_onsager_entropy_production",
      "Physical current-volume entropy-production density sum_alpha F_alpha dot "
      "(-j_alpha)/theta.");
  return params;
}

ADMulticomponentOnsagerFluxMaterial::ADMulticomponentOnsagerFluxMaterial(
    const InputParameters & parameters)
  : Material(parameters),
    _n_independent_components(
        getParam<std::vector<MaterialPropertyName>>("transport_force_names").size()),
    _dim(_mesh.dimension()),
    _constant_mobility_tensor_entries(getParam<std::vector<Real>>("mobility_tensor_entries")),
    _tensor_property_mobility(
        !getParam<std::vector<MaterialPropertyName>>("mobility_tensor_property_names").empty()),
    _tensor_component_property_mobility(
        !getParam<std::vector<MaterialPropertyName>>(
             "mobility_tensor_component_property_names")
             .empty()),
    _symmetry_tolerance(getParam<Real>("symmetry_tolerance")),
    _positive_definite_tolerance(getParam<Real>("positive_definite_tolerance")),
    _constant_reciprocity_residual(0.0),
    _constant_minimum_cholesky_pivot(0.0),
    _temperature_variable(isCoupled("temperature") ? &adCoupledValue("temperature") : nullptr),
    _temperature_property(
        getParam<MaterialPropertyName>("temperature_name").empty()
            ? nullptr
            : &getADMaterialProperty<Real>("temperature_name")),
    _reference_component_flux(declareADProperty<RealVectorValue>(
        getParam<MaterialPropertyName>("reference_component_flux_name"))),
    _zero_sum_residual(declareADProperty<RealVectorValue>(
        getParam<MaterialPropertyName>("zero_sum_residual_name"))),
    _reciprocity_residual(declareADProperty<Real>(
        getParam<MaterialPropertyName>("reciprocity_residual_name"))),
    _minimum_cholesky_pivot(declareADProperty<Real>(
        getParam<MaterialPropertyName>("minimum_cholesky_pivot_name"))),
    _force_flux_power_density(declareADProperty<Real>(
        getParam<MaterialPropertyName>("force_flux_power_density_name"))),
    _entropy_production(declareADProperty<Real>(
        getParam<MaterialPropertyName>("entropy_production_name")))
{
  const auto force_names =
      getParam<std::vector<MaterialPropertyName>>("transport_force_names");
  const auto tensor_property_names =
      getParam<std::vector<MaterialPropertyName>>("mobility_tensor_property_names");
  const auto tensor_component_property_names = getParam<std::vector<MaterialPropertyName>>(
      "mobility_tensor_component_property_names");
  const auto flux_names =
      getParam<std::vector<MaterialPropertyName>>("component_flux_names");

  if (_n_independent_components == 0)
    paramError("transport_force_names", "Supply at least one independent component force.");
  if (flux_names.size() != _n_independent_components)
    paramError("component_flux_names",
               "Supply exactly N-1 independent flux names, one for each supplied force.");
  if (static_cast<bool>(_temperature_variable) == static_cast<bool>(_temperature_property))
    paramError("temperature_name",
               "Supply exactly one of temperature or temperature_name.");

  const unsigned int mobility_modes =
      static_cast<unsigned int>(!_constant_mobility_tensor_entries.empty()) +
      static_cast<unsigned int>(_tensor_property_mobility) +
      static_cast<unsigned int>(_tensor_component_property_mobility);
  if (mobility_modes != 1)
    paramError("mobility_tensor_entries",
               "Supply exactly one of mobility_tensor_entries, mobility_tensor_property_names, "
               "or mobility_tensor_component_property_names.");

  const auto n_blocks = _n_independent_components * _n_independent_components;
  const auto n_active_entries = n_blocks * _dim * _dim;
  if (!_constant_mobility_tensor_entries.empty() &&
      _constant_mobility_tensor_entries.size() != n_active_entries)
    paramError("mobility_tensor_entries",
               "Supply exactly (N-1)^2*dim^2 active tensor entries.");
  if (_tensor_property_mobility && tensor_property_names.size() != n_blocks)
    paramError("mobility_tensor_property_names",
               "Supply exactly (N-1)^2 tensor-property names.");
  if (_tensor_component_property_mobility &&
      tensor_component_property_names.size() != n_active_entries)
    paramError("mobility_tensor_component_property_names",
               "Supply exactly (N-1)^2*dim^2 AD tensor-component property names.");

  _transport_forces.reserve(_n_independent_components);
  _independent_component_fluxes.reserve(_n_independent_components);
  for (const auto component : make_range(_n_independent_components))
  {
    _transport_forces.push_back(
        &getADMaterialProperty<RealVectorValue>(force_names[component]));
    _independent_component_fluxes.push_back(
        &declareADProperty<RealVectorValue>(flux_names[component]));
  }
  if (_tensor_property_mobility)
    for (const auto & property_name : tensor_property_names)
      _mobility_tensor_properties.push_back(
          &getADMaterialProperty<RankTwoTensor>(property_name));
  if (_tensor_component_property_mobility)
    for (const auto & property_name : tensor_component_property_names)
      _mobility_tensor_component_properties.push_back(
          &getADMaterialProperty<Real>(property_name));

  if (!_constant_mobility_tensor_entries.empty())
  {
    _constant_mobility_tensors.resize(n_blocks);
    for (const auto block : make_range(n_blocks))
      for (const auto i : make_range(_dim))
        for (const auto j : make_range(_dim))
          _constant_mobility_tensors[block](i, j) =
              _constant_mobility_tensor_entries[block * _dim * _dim + i * _dim + j];
    const auto audit = auditMobility(_constant_mobility_tensors);
    _constant_reciprocity_residual = audit.first;
    _constant_minimum_cholesky_pivot = audit.second;
  }
}

std::pair<Real, Real>
ADMulticomponentOnsagerFluxMaterial::auditMobility(
    const std::vector<RankTwoTensor> & mobility) const
{
  const auto n = _n_independent_components;
  Real matrix_scale = 0.0;
  Real reciprocity = 0.0;
  for (const auto alpha : make_range(n))
    for (const auto beta : make_range(n))
      for (const auto i : make_range(_dim))
        for (const auto j : make_range(_dim))
        {
          const Real value = mobility[alpha * n + beta](i, j);
          const Real transpose_value = mobility[beta * n + alpha](j, i);
          matrix_scale = std::max(matrix_scale, std::abs(value));
          reciprocity = std::max(reciprocity, std::abs(value - transpose_value));
        }
  // Keep the audit relative to the supplied mobility units.  A unit floor here would make
  // otherwise admissible small dimensional mobilities fail a nominally relative tolerance.
  if (reciprocity > _symmetry_tolerance * matrix_scale)
    mooseError(name(),
               ": Onsager tensor reciprocity failed; maximum |D_ab-D_ba^T| = ",
               reciprocity,
               ".");

  const auto block_size = n * _dim;
  std::vector<Real> symmetric_raw(block_size * block_size, 0.0);
  for (const auto alpha : make_range(n))
    for (const auto beta : make_range(n))
      for (const auto i : make_range(_dim))
        for (const auto j : make_range(_dim))
        {
          const auto row = alpha * _dim + i;
          const auto column = beta * _dim + j;
          symmetric_raw[row * block_size + column] =
              0.5 * (mobility[alpha * n + beta](i, j) +
                     mobility[beta * n + alpha](j, i));
        }

  Real minimum_pivot = std::numeric_limits<Real>::max();
  std::vector<Real> cholesky(block_size * block_size, 0.0);
  for (const auto row : make_range(block_size))
    for (const auto column : make_range(row + 1))
    {
      Real value = symmetric_raw[row * block_size + column];
      for (const auto k : make_range(column))
        value -= cholesky[row * block_size + k] * cholesky[column * block_size + k];
      if (row == column)
      {
        minimum_pivot = std::min(minimum_pivot, value);
        // A zero mobility matrix remains inadmissible because both sides are zero.
        if (value <= _positive_definite_tolerance * matrix_scale)
          mooseError(name(),
                     ": Onsager tensor mobility is not positive definite; pivot ",
                     value,
                     ".");
        cholesky[row * block_size + column] = std::sqrt(value);
      }
      else
        cholesky[row * block_size + column] =
            value / cholesky[column * block_size + column];
    }
  return {reciprocity, minimum_pivot};
}

void
ADMulticomponentOnsagerFluxMaterial::computeQpProperties()
{
  const auto n = _n_independent_components;
  std::vector<ADRankTwoTensor> mobility(n * n);
  if (!_constant_mobility_tensors.empty())
    for (const auto block : make_range(n * n))
      mobility[block] = _constant_mobility_tensors[block];
  else
    for (const auto alpha : make_range(n))
      for (const auto beta : make_range(n))
      {
        const auto block = alpha * n + beta;
        if (_tensor_property_mobility)
          mobility[block] = (*_mobility_tensor_properties[block])[_qp];
        else
          for (const auto i : make_range(_dim))
            for (const auto j : make_range(_dim))
            {
              const auto entry = block * _dim * _dim + i * _dim + j;
              mobility[block](i, j) =
                  (*_mobility_tensor_component_properties[entry])[_qp];
            }
      }

  if (!_constant_mobility_tensors.empty())
  {
    _reciprocity_residual[_qp] = _constant_reciprocity_residual;
    _minimum_cholesky_pivot[_qp] = _constant_minimum_cholesky_pivot;
  }
  else
  {
    std::vector<RankTwoTensor> raw_mobility(n * n);
    for (const auto block : make_range(n * n))
      for (const auto i : make_range(_dim))
        for (const auto j : make_range(_dim))
          raw_mobility[block](i, j) = MetaPhysicL::raw_value(mobility[block](i, j));
    const auto audit = auditMobility(raw_mobility);
    _reciprocity_residual[_qp] = audit.first;
    _minimum_cholesky_pivot[_qp] = audit.second;
  }

  _reference_component_flux[_qp] = ADRealVectorValue();
  _force_flux_power_density[_qp] = 0.0;
  for (const auto alpha : make_range(n))
  {
    (*_independent_component_fluxes[alpha])[_qp] = ADRealVectorValue();
    for (const auto beta : make_range(n))
      (*_independent_component_fluxes[alpha])[_qp] -=
          mobility[alpha * n + beta] * (*_transport_forces[beta])[_qp];
    _reference_component_flux[_qp] -= (*_independent_component_fluxes[alpha])[_qp];
    _force_flux_power_density[_qp] +=
        (*_transport_forces[alpha])[_qp] *
        (-(*_independent_component_fluxes[alpha])[_qp]);
  }

  _zero_sum_residual[_qp] = _reference_component_flux[_qp];
  for (const auto alpha : make_range(n))
    _zero_sum_residual[_qp] += (*_independent_component_fluxes[alpha])[_qp];

  const ADReal temperature =
      _temperature_property ? (*_temperature_property)[_qp] : (*_temperature_variable)[_qp];
  if (MetaPhysicL::raw_value(temperature) <= 0.0)
    mooseError(name(), ": absolute subsystem temperature must remain positive.");
  _entropy_production[_qp] = _force_flux_power_density[_qp] / temperature;
}
