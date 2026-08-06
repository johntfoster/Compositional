#include "ADSaturationOnsagerForceMaterial.h"

#include "metaphysicl/raw_type.h"

#include <algorithm>
#include <cmath>
#include <set>

registerMooseObject("MulticomponentReactiveFlowApp", ADSaturationOnsagerForceMaterial);

namespace
{
template <typename Scalar>
Scalar
minimumSymmetricEigenvalue(std::vector<Scalar> matrix,
                           const unsigned int size,
                           const Real tolerance,
                           const Real matrix_scale)
{
  for (unsigned int i = 0; i < size; ++i)
    for (unsigned int j = i + 1; j < size; ++j)
    {
      const Scalar average = 0.5 * (matrix[i * size + j] + matrix[j * size + i]);
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
      {
        const Real magnitude = std::abs(MetaPhysicL::raw_value(matrix[i * size + j]));
        if (magnitude > largest_off_diagonal)
        {
          largest_off_diagonal = magnitude;
          p = i;
          q = j;
        }
      }
    if (largest_off_diagonal <= tolerance * matrix_scale)
      break;

    const Scalar app = matrix[p * size + p];
    const Scalar aqq = matrix[q * size + q];
    const Scalar apq = matrix[p * size + q];
    const Scalar tau = (aqq - app) / (2.0 * apq);
    using std::sqrt;
    const Scalar root = sqrt(1.0 + tau * tau);
    const Scalar tangent = MetaPhysicL::raw_value(tau) >= 0.0 ? 1.0 / (tau + root)
                                                               : -1.0 / (-tau + root);
    const Scalar cosine = 1.0 / sqrt(1.0 + tangent * tangent);
    const Scalar sine = tangent * cosine;
    for (unsigned int k = 0; k < size; ++k)
      if (k != p && k != q)
      {
        const Scalar akp = matrix[k * size + p];
        const Scalar akq = matrix[k * size + q];
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

  Scalar minimum = matrix[0];
  for (unsigned int i = 1; i < size; ++i)
    if (MetaPhysicL::raw_value(matrix[i * size + i]) < MetaPhysicL::raw_value(minimum))
      minimum = matrix[i * size + i];
  return minimum;
}
}

InputParameters
ADSaturationOnsagerForceMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Evaluates generalized saturation-force differences, quadratic dissipation, and entropy "
      "production from a symmetric positive-semidefinite Onsager resistance matrix.");
  params.addRequiredParam<std::vector<std::string>>(
      "independent_phase_names",
      "Names of the independent fluid phases; the omitted phase is the saturation reference.");
  params.addRequiredParam<std::vector<MaterialPropertyName>>(
      "saturation_rate_names",
      "AD material properties containing the reconstructed independent saturation rates.");
  params.addParam<std::vector<Real>>(
      "resistance_matrix",
      {},
      "Constant row-major symmetric Onsager matrix T_fg with pressure-time units.");
  params.addParam<std::vector<MaterialPropertyName>>(
      "resistance_property_names",
      {},
      "Optional row-major AD Onsager-resistance properties. Supply exactly one of this parameter "
      "and resistance_matrix.");
  params.addRangeCheckedParam<Real>(
      "positive_semidefinite_tolerance",
      1e-12,
      "positive_semidefinite_tolerance>=0",
      "Dimensionless relative tolerance used when checking symmetry and positive "
      "semidefiniteness against the maximum absolute matrix entry. An exactly zero matrix "
      "has zero scale and is admissible.");
  params.addParam<MaterialPropertyName>(
      "porosity_name", "", "Optional AD current porosity property used in phi T dot(S)^2/theta.");
  params.addRangeCheckedParam<Real>(
      "porosity", 1.0, "porosity>=0", "Constant porosity used when porosity_name is omitted.");
  params.addParam<MaterialPropertyName>(
      "fluid_temperature_name",
      "",
      "Optional AD fluid-temperature property used in phi T dot(S)^2/theta.");
  params.addRangeCheckedParam<Real>(
      "fluid_temperature",
      1.0,
      "fluid_temperature>0",
      "Constant absolute fluid temperature used when fluid_temperature_name is omitted.");
  params.addParam<std::string>(
      "property_prefix", "saturation_onsager", "Prefix for all declared material properties.");
  return params;
}

ADSaturationOnsagerForceMaterial::ADSaturationOnsagerForceMaterial(
    const InputParameters & parameters)
  : Material(parameters),
    _independent_phase_names(getParam<std::vector<std::string>>("independent_phase_names")),
    _resistance_matrix(getParam<std::vector<Real>>("resistance_matrix")),
    _resistance_property_mode(!getParam<std::vector<MaterialPropertyName>>(
                                   "resistance_property_names")
                                   .empty()),
    _positive_semidefinite_tolerance(getParam<Real>("positive_semidefinite_tolerance")),
    _constant_porosity(getParam<Real>("porosity")),
    _constant_fluid_temperature(getParam<Real>("fluid_temperature")),
    _property_prefix(getParam<std::string>("property_prefix")),
    _porosity(getParam<MaterialPropertyName>("porosity_name").empty()
                  ? nullptr
                  : &getADMaterialProperty<Real>("porosity_name")),
    _fluid_temperature(getParam<MaterialPropertyName>("fluid_temperature_name").empty()
                           ? nullptr
                           : &getADMaterialProperty<Real>("fluid_temperature_name")),
    _dissipation_rate(declareADProperty<Real>(prefixedName("dissipation_rate"))),
    _entropy_production_rate(
        declareADProperty<Real>(prefixedName("entropy_production_rate"))),
    _minimum_resistance_eigenvalue(
        declareADProperty<Real>(prefixedName("minimum_resistance_eigenvalue"))),
    _constant_minimum_eigenvalue(0.0)
{
  const auto & rate_names =
      getParam<std::vector<MaterialPropertyName>>("saturation_rate_names");
  const auto & resistance_property_names =
      getParam<std::vector<MaterialPropertyName>>("resistance_property_names");
  const auto phase_count = _independent_phase_names.size();
  if (phase_count == 0)
    paramError("independent_phase_names", "Supply at least one independent fluid phase.");
  if (rate_names.size() != phase_count)
    paramError("saturation_rate_names", "Supply one saturation-rate property per phase name.");
  if (_resistance_property_mode == !_resistance_matrix.empty())
    paramError("resistance_matrix",
               "Supply exactly one of resistance_matrix and resistance_property_names.");
  if (!_resistance_property_mode && _resistance_matrix.size() != phase_count * phase_count)
    paramError("resistance_matrix", "Supply a square row-major matrix of phase_count^2 values.");
  if (_resistance_property_mode &&
      resistance_property_names.size() != phase_count * phase_count)
    paramError("resistance_property_names",
               "Supply a square row-major matrix of phase_count^2 property names.");
  if (_property_prefix.empty())
    paramError("property_prefix", "The material-property prefix must be nonempty.");

  std::set<std::string> unique_names;
  for (const auto & phase_name : _independent_phase_names)
  {
    if (phase_name.empty())
      paramError("independent_phase_names", "Phase names must be nonempty.");
    if (!unique_names.insert(phase_name).second)
      paramError("independent_phase_names", "Independent phase names must be unique.");
  }

  _saturation_rates.reserve(phase_count);
  _resistance_properties.reserve(resistance_property_names.size());
  _force_differences.reserve(phase_count);
  for (unsigned int i = 0; i < phase_count; ++i)
  {
    _saturation_rates.push_back(&getADMaterialProperty<Real>(rate_names[i]));
    _force_differences.push_back(&declareADProperty<Real>(
        prefixedName(_independent_phase_names[i] + "_force_difference")));
  }
  for (const auto & property_name : resistance_property_names)
    _resistance_properties.push_back(&getADMaterialProperty<Real>(property_name));

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

  _constant_minimum_eigenvalue = minimumSymmetricEigenvalue(
      _resistance_matrix, phase_count, _positive_semidefinite_tolerance, matrix_scale);
  if (_constant_minimum_eigenvalue < -_positive_semidefinite_tolerance * matrix_scale)
    paramError("resistance_matrix", "The Onsager resistance matrix must be positive semidefinite.");
}

MaterialPropertyName
ADSaturationOnsagerForceMaterial::prefixedName(const std::string & suffix) const
{
  return MaterialPropertyName(_property_prefix + "_" + suffix);
}

void
ADSaturationOnsagerForceMaterial::computeQpProperties()
{
  const auto phase_count = _independent_phase_names.size();
  std::vector<ADReal> resistance(phase_count * phase_count);
  Real matrix_scale = 0.0;
  for (unsigned int entry = 0; entry < resistance.size(); ++entry)
  {
    resistance[entry] = _resistance_property_mode ? (*_resistance_properties[entry])[_qp]
                                                   : ADReal(_resistance_matrix[entry]);
    matrix_scale =
        std::max(matrix_scale, std::abs(MetaPhysicL::raw_value(resistance[entry])));
  }
  for (unsigned int i = 0; i < phase_count; ++i)
    for (unsigned int j = i + 1; j < phase_count; ++j)
      if (std::abs(MetaPhysicL::raw_value(resistance[i * phase_count + j]) -
                   MetaPhysicL::raw_value(resistance[j * phase_count + i])) >
          _positive_semidefinite_tolerance * matrix_scale)
        mooseError(name(),
                   ": the Onsager resistance matrix must be symmetric at every quadrature point.");

  const ADReal minimum_eigenvalue =
      _resistance_property_mode
          ? minimumSymmetricEigenvalue(
                resistance, phase_count, _positive_semidefinite_tolerance, matrix_scale)
          : ADReal(_constant_minimum_eigenvalue);
  if (_resistance_property_mode &&
      MetaPhysicL::raw_value(minimum_eigenvalue) <
          -_positive_semidefinite_tolerance * matrix_scale)
    mooseError(name(),
               ": the Onsager resistance matrix must be positive semidefinite at every "
               "quadrature point.");

  _dissipation_rate[_qp] = 0.0;
  for (unsigned int i = 0; i < phase_count; ++i)
  {
    ADReal force_difference = 0.0;
    for (unsigned int j = 0; j < phase_count; ++j)
      force_difference +=
          resistance[i * phase_count + j] * (*_saturation_rates[j])[_qp];
    (*_force_differences[i])[_qp] = force_difference;
    _dissipation_rate[_qp] += (*_saturation_rates[i])[_qp] * force_difference;
  }

  const ADReal porosity = _porosity ? (*_porosity)[_qp] : ADReal(_constant_porosity);
  const ADReal temperature =
      _fluid_temperature ? (*_fluid_temperature)[_qp] : ADReal(_constant_fluid_temperature);
  if (MetaPhysicL::raw_value(porosity) < 0.0)
    mooseError(name(), ": porosity must remain nonnegative.");
  if (MetaPhysicL::raw_value(temperature) <= 0.0)
    mooseError(name(), ": fluid temperature must remain positive.");
  _entropy_production_rate[_qp] = porosity * _dissipation_rate[_qp] / temperature;
  _minimum_resistance_eigenvalue[_qp] = minimum_eigenvalue;
}
