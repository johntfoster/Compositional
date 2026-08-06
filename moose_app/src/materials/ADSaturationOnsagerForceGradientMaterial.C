#include "ADSaturationOnsagerForceGradientMaterial.h"

#include "metaphysicl/raw_type.h"

#include <algorithm>
#include <cmath>
#include <set>

registerMooseObject("MulticomponentReactiveFlowApp",
                    ADSaturationOnsagerForceGradientMaterial);

namespace
{
Real
minimumSymmetricEigenvalue(std::vector<Real> matrix,
                           const unsigned int size,
                           const Real tolerance,
                           const Real matrix_scale)
{
  for (unsigned int i = 0; i < size; ++i)
    for (unsigned int j = i + 1; j < size; ++j)
    {
      const Real average = 0.5 * (matrix[i * size + j] + matrix[j * size + i]);
      matrix[i * size + j] = average;
      matrix[j * size + i] = average;
    }

  const unsigned int iteration_limit = std::max<unsigned int>(20, 50 * size * size);
  for (unsigned int iteration = 0; iteration < iteration_limit; ++iteration)
  {
    unsigned int p = 0;
    unsigned int q = 0;
    Real largest_off_diagonal = 0.0;
    for (unsigned int i = 0; i < size; ++i)
      for (unsigned int j = i + 1; j < size; ++j)
        if (std::abs(matrix[i * size + j]) > largest_off_diagonal)
        {
          largest_off_diagonal = std::abs(matrix[i * size + j]);
          p = i;
          q = j;
        }
    if (largest_off_diagonal <= tolerance * matrix_scale)
      break;

    const Real app = matrix[p * size + p];
    const Real aqq = matrix[q * size + q];
    const Real apq = matrix[p * size + q];
    const Real tau = (aqq - app) / (2.0 * apq);
    const Real tangent =
        std::copysign(1.0 / (std::abs(tau) + std::sqrt(1.0 + tau * tau)), tau);
    const Real cosine = 1.0 / std::sqrt(1.0 + tangent * tangent);
    const Real sine = tangent * cosine;
    for (unsigned int k = 0; k < size; ++k)
      if (k != p && k != q)
      {
        const Real akp = matrix[k * size + p];
        const Real akq = matrix[k * size + q];
        matrix[k * size + p] = cosine * akp - sine * akq;
        matrix[p * size + k] = matrix[k * size + p];
        matrix[k * size + q] = sine * akp + cosine * akq;
        matrix[q * size + k] = matrix[k * size + q];
      }
    matrix[p * size + p] = cosine * cosine * app - 2.0 * sine * cosine * apq +
                            sine * sine * aqq;
    matrix[q * size + q] = sine * sine * app + 2.0 * sine * cosine * apq +
                            cosine * cosine * aqq;
    matrix[p * size + q] = 0.0;
    matrix[q * size + p] = 0.0;
  }

  Real minimum = matrix[0];
  for (unsigned int i = 1; i < size; ++i)
    minimum = std::min(minimum, matrix[i * size + i]);
  return minimum;
}
}

InputParameters
ADSaturationOnsagerForceGradientMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Maps reconstructed saturation-rate gradients through the same symmetric "
      "positive-semidefinite Onsager resistance used for generalized saturation forces.");
  params.addRequiredParam<std::vector<std::string>>(
      "independent_phase_names", "Independent phases in resistance-matrix order.");
  params.addRequiredParam<std::vector<MaterialPropertyName>>(
      "saturation_rate_gradient_names", "One reference saturation-rate gradient per phase.");
  params.addParam<std::vector<Real>>(
      "resistance_matrix", {}, "Constant row-major symmetric Onsager resistance matrix.");
  params.addParam<std::vector<MaterialPropertyName>>(
      "resistance_property_names",
      {},
      "Optional row-major AD Onsager-resistance properties. Supply exactly one of this parameter "
      "and resistance_matrix.");
  params.addParam<std::vector<MaterialPropertyName>>(
      "resistance_gradient_property_names",
      {},
      "Row-major AD spatial gradients required with resistance_property_names so that the full "
      "product rule is evaluated. Supply explicit zero-gradient properties for a spatially "
      "constant specialization.");
  params.addParam<std::vector<MaterialPropertyName>>(
      "saturation_rate_names",
      {},
      "Saturation-rate properties required with resistance_gradient_property_names.");
  params.addRangeCheckedParam<Real>("positive_semidefinite_tolerance",
                                     1e-12,
                                     "positive_semidefinite_tolerance>=0",
                                     "Dimensionless relative matrix-validation tolerance scaled "
                                     "by the maximum absolute matrix entry. An exactly zero matrix "
                                     "has zero scale and is admissible.");
  params.addParam<std::string>("property_prefix",
                               "saturation_onsager",
                               "Prefix shared with the saturation-force properties.");
  return params;
}

ADSaturationOnsagerForceGradientMaterial::ADSaturationOnsagerForceGradientMaterial(
    const InputParameters & parameters)
  : Material(parameters),
    _independent_phase_names(getParam<std::vector<std::string>>("independent_phase_names")),
    _resistance_matrix(getParam<std::vector<Real>>("resistance_matrix")),
    _resistance_property_mode(!getParam<std::vector<MaterialPropertyName>>(
                                   "resistance_property_names")
                                   .empty()),
    _positive_semidefinite_tolerance(getParam<Real>("positive_semidefinite_tolerance")),
    _property_prefix(getParam<std::string>("property_prefix"))
{
  const auto gradient_names =
      getParam<std::vector<MaterialPropertyName>>("saturation_rate_gradient_names");
  const auto & rate_names = getParam<std::vector<MaterialPropertyName>>("saturation_rate_names");
  const auto & resistance_property_names =
      getParam<std::vector<MaterialPropertyName>>("resistance_property_names");
  const auto & resistance_gradient_names =
      getParam<std::vector<MaterialPropertyName>>("resistance_gradient_property_names");
  const auto phase_count = _independent_phase_names.size();
  if (phase_count == 0)
    paramError("independent_phase_names", "Supply at least one independent phase.");
  if (gradient_names.size() != phase_count)
    paramError("saturation_rate_gradient_names", "Supply one gradient per phase.");
  if (_resistance_property_mode == !_resistance_matrix.empty())
    paramError("resistance_matrix",
               "Supply exactly one of resistance_matrix and resistance_property_names.");
  if (!_resistance_property_mode && _resistance_matrix.size() != phase_count * phase_count)
    paramError("resistance_matrix", "Supply phase_count squared row-major entries.");
  if (_resistance_property_mode &&
      resistance_property_names.size() != phase_count * phase_count)
    paramError("resistance_property_names",
               "Supply phase_count squared row-major property names.");
  if (resistance_gradient_names.empty() != rate_names.empty())
    paramError("resistance_gradient_property_names",
               "Supply resistance_gradient_property_names and saturation_rate_names together.");
  if (_resistance_property_mode && resistance_gradient_names.empty())
    paramError("resistance_gradient_property_names",
               "Property-valued resistance requires resistance gradients and saturation rates "
               "for the full product rule.");
  if (!resistance_gradient_names.empty() && !_resistance_property_mode)
    paramError("resistance_gradient_property_names",
               "Resistance gradients require resistance_property_names.");
  if (!resistance_gradient_names.empty() &&
      resistance_gradient_names.size() != phase_count * phase_count)
    paramError("resistance_gradient_property_names",
               "Supply phase_count squared row-major resistance gradients.");
  if (!rate_names.empty() && rate_names.size() != phase_count)
    paramError("saturation_rate_names", "Supply one saturation-rate property per phase.");
  if (_property_prefix.empty())
    paramError("property_prefix", "The property prefix must be nonempty.");

  std::set<std::string> unique_names;
  for (const auto & phase_name : _independent_phase_names)
    if (phase_name.empty() || !unique_names.insert(phase_name).second)
      paramError("independent_phase_names", "Phase names must be nonempty and unique.");

  for (unsigned int i = 0; i < phase_count; ++i)
  {
    if (!rate_names.empty())
      _saturation_rates.push_back(&getADMaterialProperty<Real>(rate_names[i]));
    _saturation_rate_gradients.push_back(
        &getADMaterialProperty<RealVectorValue>(gradient_names[i]));
    _force_difference_gradients.push_back(&declareADProperty<RealVectorValue>(
        prefixedName(_independent_phase_names[i] + "_force_difference_gradient")));
  }
  for (unsigned int entry = 0; entry < resistance_property_names.size(); ++entry)
  {
    _resistance_properties.push_back(
        &getADMaterialProperty<Real>(resistance_property_names[entry]));
    if (!resistance_gradient_names.empty())
      _resistance_gradients.push_back(
          &getADMaterialProperty<RealVectorValue>(resistance_gradient_names[entry]));
  }

  if (_resistance_property_mode)
    return;

  Real matrix_scale = 0.0;
  for (const auto value : _resistance_matrix)
    matrix_scale = std::max(matrix_scale, std::abs(value));
  for (unsigned int i = 0; i < phase_count; ++i)
    for (unsigned int j = i + 1; j < phase_count; ++j)
      if (std::abs(_resistance_matrix[i * phase_count + j] -
                   _resistance_matrix[j * phase_count + i]) >
          _positive_semidefinite_tolerance * matrix_scale)
        paramError("resistance_matrix", "The Onsager resistance matrix must be symmetric.");

  const Real minimum_eigenvalue = minimumSymmetricEigenvalue(
      _resistance_matrix, phase_count, _positive_semidefinite_tolerance, matrix_scale);
  if (minimum_eigenvalue < -_positive_semidefinite_tolerance * matrix_scale)
    paramError("resistance_matrix", "The Onsager resistance matrix must be positive semidefinite.");
}

MaterialPropertyName
ADSaturationOnsagerForceGradientMaterial::prefixedName(const std::string & suffix) const
{
  return MaterialPropertyName(_property_prefix + "_" + suffix);
}

void
ADSaturationOnsagerForceGradientMaterial::computeQpProperties()
{
  const auto phase_count = _independent_phase_names.size();
  std::vector<Real> resistance_values(phase_count * phase_count);
  Real matrix_scale = 0.0;
  for (unsigned int entry = 0; entry < resistance_values.size(); ++entry)
  {
    resistance_values[entry] =
        _resistance_property_mode
            ? MetaPhysicL::raw_value((*_resistance_properties[entry])[_qp])
            : _resistance_matrix[entry];
    matrix_scale = std::max(matrix_scale, std::abs(resistance_values[entry]));
  }
  if (_resistance_property_mode)
  {
    for (unsigned int i = 0; i < phase_count; ++i)
      for (unsigned int j = i + 1; j < phase_count; ++j)
        if (std::abs(resistance_values[i * phase_count + j] -
                     resistance_values[j * phase_count + i]) >
            _positive_semidefinite_tolerance * matrix_scale)
          mooseError(
              name(),
              ": the Onsager resistance matrix must be symmetric at every quadrature point.");
    if (minimumSymmetricEigenvalue(resistance_values,
                                   phase_count,
                                   _positive_semidefinite_tolerance,
                                   matrix_scale) <
        -_positive_semidefinite_tolerance * matrix_scale)
      mooseError(name(),
                 ": the Onsager resistance matrix must be positive semidefinite at every "
                 "quadrature point.");
  }

  for (unsigned int i = 0; i < phase_count; ++i)
  {
    (*_force_difference_gradients[i])[_qp] = ADRealVectorValue();
    for (unsigned int j = 0; j < phase_count; ++j)
    {
      const unsigned int entry = i * phase_count + j;
      const ADReal resistance = _resistance_property_mode
                                    ? (*_resistance_properties[entry])[_qp]
                                    : ADReal(_resistance_matrix[entry]);
      (*_force_difference_gradients[i])[_qp] +=
          resistance * (*_saturation_rate_gradients[j])[_qp];
      if (!_resistance_gradients.empty())
        (*_force_difference_gradients[i])[_qp] +=
            (*_saturation_rates[j])[_qp] * (*_resistance_gradients[entry])[_qp];
    }
  }
}
