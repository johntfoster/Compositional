#include "ADEntropyViscosityReferenceFluxMaterial.h"

#include "metaphysicl/raw_type.h"

#include <algorithm>
#include <cmath>

registerMooseObject("MulticomponentReactiveFlowApp",
                    ADEntropyViscosityReferenceFluxMaterial);

InputParameters
ADEntropyViscosityReferenceFluxMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Builds the residual entropy-viscosity flux W_ev=-rho_ref*mu_stab*Grad_X(s) "
      "and matching isotropic mobility for a high-order CG+P0 EG scalar. The "
      "coefficient is min(lambda_linear*h*|v|, "
      "lambda_entropy*h^2*|R_entropy|/||E-Ebar||_infinity), following the "
      "Lee-Wheeler high-order EG construction. Global entropy statistics may be "
      "provided as lagged postprocessors or constants.");
  params.addRequiredParam<MaterialPropertyName>("scalar_name",
                                                 "Reconstructed total scalar value.");
  params.addRequiredParam<MaterialPropertyName>("scalar_gradient_name",
                                                 "Reconstructed reference gradient.");
  params.addRequiredParam<MaterialPropertyName>("scalar_dot_name",
                                                 "Reconstructed total scalar rate.");
  params.addParam<MaterialPropertyName>(
      "transport_velocity_name", "", "Optional reference transport velocity.");
  params.addParam<MaterialPropertyName>(
      "entropy_flux_derivative_name",
      "",
      "Optional derivative of the physical reference flux with respect to the reconstructed "
      "scalar. When supplied, its contraction with Grad_X(s) replaces the transport-velocity "
      "term in the entropy residual while transport_velocity_name still sets the linear "
      "viscosity speed.");
  params.addParam<MaterialPropertyName>("source_name", "", "Optional scalar source.");
  params.addParam<std::vector<MaterialPropertyName>>(
      "source_names",
      {},
      "Additional physical reference sources summed in the entropy residual. Positive values "
      "use the same production convention as source_name.");
  params.addParam<MaterialPropertyName>(
      "strong_residual_name",
      "",
      "Optional strong conservation residual. When supplied, E'(s) times this "
      "property forms the entropy residual.");
  params.addParam<MaterialPropertyName>(
      "entropy_residual_name",
      "",
      "Optional directly supplied entropy residual, overriding the built-in "
      "smooth strong-form construction.");
  params.addParam<Real>("mass_coefficient", 1.0, "Constant rho_ref multiplier on the flux.");
  params.addParam<MaterialPropertyName>(
      "mass_coefficient_name", "", "Optional AD rho_ref multiplier on the flux.");
  params.addParam<MaterialPropertyName>(
      "entropy_storage_coefficient_name",
      "",
      "Optional reference phase-mass coefficient A in the stored entropy A E(s).");
  params.addParam<MaterialPropertyName>(
      "entropy_storage_coefficient_rate_name",
      "",
      "Optional material rate dot(A). Supply together with "
      "entropy_storage_coefficient_name to form dot(A) E(s)+A E'(s) dot(s).");
  params.addParam<Real>(
      "storage_coefficient", 1.0, "Coefficient multiplying E'(s)*dot(s).");
  params.addRangeCheckedParam<Real>(
      "lambda_linear", 1e-2, "lambda_linear>=0", "Linear-viscosity constant.");
  params.addRangeCheckedParam<Real>(
      "lambda_entropy", 1e-2, "lambda_entropy>=0", "Entropy-viscosity constant.");
  params.addParam<MooseEnum>(
      "entropy", MooseEnum("power log_barrier", "log_barrier"), "Convex entropy.");
  params.addRangeCheckedParam<unsigned int>(
      "power", 10, "power>=2", "Even exponent b for E(s)=|s|^b/b.");
  params.addRangeCheckedParam<Real>(
      "regularization", 1e-8, "regularization>0", "Smooth absolute-value regularization.");
  params.addRangeCheckedParam<Real>("normalization_floor",
                                    1e-12,
                                    "normalization_floor>0",
                                    "Lower bound on ||E-Ebar||_infinity.");
  params.addParam<bool>(
      "differentiate_viscosity",
      true,
      "Differentiate the nonlinear entropy-viscosity sensor. Set false to lag/freeze the "
      "min, speed, and entropy-residual coefficient while retaining AD derivatives of the "
      "mass coefficient and reconstructed-scalar gradient in the stabilization flux.");
  params.addParam<PostprocessorName>(
      "entropy_average",
      0.0,
      "Lagged domain average Ebar, or a constant when no postprocessor is used.");
  params.addParam<PostprocessorName>(
      "entropy_deviation_norm",
      1.0,
      "Lagged ||E-Ebar||_infinity, or a positive constant normalization.");
  params.addRequiredParam<std::string>("property_prefix", "Prefix for all output properties.");
  return params;
}

ADEntropyViscosityReferenceFluxMaterial::ADEntropyViscosityReferenceFluxMaterial(
    const InputParameters & parameters)
  : Material(parameters),
    _scalar(getADMaterialProperty<Real>(getParam<MaterialPropertyName>("scalar_name"))),
    _scalar_gradient(getADMaterialProperty<RealVectorValue>(
        getParam<MaterialPropertyName>("scalar_gradient_name"))),
    _scalar_dot(getADMaterialProperty<Real>(getParam<MaterialPropertyName>("scalar_dot_name"))),
    _transport_velocity(getParam<MaterialPropertyName>("transport_velocity_name").empty()
                            ? nullptr
                            : &getADMaterialProperty<RealVectorValue>(
                                  getParam<MaterialPropertyName>("transport_velocity_name"))),
    _entropy_flux_derivative(
        getParam<MaterialPropertyName>("entropy_flux_derivative_name").empty()
            ? nullptr
            : &getADMaterialProperty<RealVectorValue>(
                  getParam<MaterialPropertyName>("entropy_flux_derivative_name"))),
    _source(getParam<MaterialPropertyName>("source_name").empty()
                ? nullptr
                : &getADMaterialProperty<Real>(getParam<MaterialPropertyName>("source_name"))),
    _strong_residual(getParam<MaterialPropertyName>("strong_residual_name").empty()
                         ? nullptr
                         : &getADMaterialProperty<Real>(
                               getParam<MaterialPropertyName>("strong_residual_name"))),
    _supplied_entropy_residual(getParam<MaterialPropertyName>("entropy_residual_name").empty()
                                   ? nullptr
                                   : &getADMaterialProperty<Real>(
                                         getParam<MaterialPropertyName>("entropy_residual_name"))),
    _mass_coefficient_property(getParam<MaterialPropertyName>("mass_coefficient_name").empty()
                                   ? nullptr
                                   : &getADMaterialProperty<Real>(
                                         getParam<MaterialPropertyName>("mass_coefficient_name"))),
    _entropy_storage_coefficient(
        getParam<MaterialPropertyName>("entropy_storage_coefficient_name").empty()
            ? nullptr
            : &getADMaterialProperty<Real>(
                  getParam<MaterialPropertyName>("entropy_storage_coefficient_name"))),
    _entropy_storage_coefficient_rate(
        getParam<MaterialPropertyName>("entropy_storage_coefficient_rate_name").empty()
            ? nullptr
            : &getADMaterialProperty<Real>(
                  getParam<MaterialPropertyName>("entropy_storage_coefficient_rate_name"))),
    _mass_coefficient(getParam<Real>("mass_coefficient")),
    _storage_coefficient(getParam<Real>("storage_coefficient")),
    _lambda_linear(getParam<Real>("lambda_linear")),
    _lambda_entropy(getParam<Real>("lambda_entropy")),
    _entropy(getParam<MooseEnum>("entropy")),
    _power(getParam<unsigned int>("power")),
    _regularization(getParam<Real>("regularization")),
    _normalization_floor(getParam<Real>("normalization_floor")),
    _differentiate_viscosity(getParam<bool>("differentiate_viscosity")),
    _entropy_average(getPostprocessorValue("entropy_average")),
    _entropy_deviation_norm(getPostprocessorValue("entropy_deviation_norm")),
    _entropy_value(declareADProperty<Real>(getParam<std::string>("property_prefix") +
                                           "_entropy_value")),
    _entropy_residual(declareADProperty<Real>(getParam<std::string>("property_prefix") +
                                              "_entropy_residual")),
    _linear_viscosity(declareADProperty<Real>(getParam<std::string>("property_prefix") +
                                              "_linear_viscosity")),
    _residual_viscosity(declareADProperty<Real>(getParam<std::string>("property_prefix") +
                                                "_residual_viscosity")),
    _stabilization_viscosity(declareADProperty<Real>(getParam<std::string>("property_prefix") +
                                                     "_stabilization_viscosity")),
    _reference_flux(declareADProperty<RealVectorValue>(getParam<std::string>("property_prefix") +
                                                       "_reference_flux")),
    _mobility(declareADProperty<RankTwoTensor>(getParam<std::string>("property_prefix") +
                                               "_mobility"))
{
  for (const auto & source_name : getParam<std::vector<MaterialPropertyName>>("source_names"))
    _sources.push_back(&getADMaterialProperty<Real>(source_name));
  if (getParam<std::string>("property_prefix").empty())
    paramError("property_prefix", "The entropy-viscosity property prefix must be nonempty.");
  if (_power % 2 != 0)
    paramError("power", "The power entropy exponent must be even.");
  if (_strong_residual && _supplied_entropy_residual)
    paramError("entropy_residual_name",
               "Supply at most one of strong_residual_name and entropy_residual_name.");
  if (_mass_coefficient_property && isParamSetByUser("mass_coefficient"))
    paramError("mass_coefficient_name",
               "Do not also set mass_coefficient when an AD coefficient property is supplied.");
  if (static_cast<bool>(_entropy_storage_coefficient) !=
      static_cast<bool>(_entropy_storage_coefficient_rate))
    paramError("entropy_storage_coefficient_rate_name",
               "Supply entropy_storage_coefficient_name and its rate together.");
}

void
ADEntropyViscosityReferenceFluxMaterial::computeQpProperties()
{
  if (!_differentiate_viscosity)
  {
    const Real s = MetaPhysicL::raw_value(_scalar[_qp]);
    Real entropy;
    Real entropy_prime;
    if (_entropy == "power")
    {
      Real s_to_power_minus_one = 1.0;
      for (unsigned int exponent = 0; exponent + 1 < _power; ++exponent)
        s_to_power_minus_one *= s;
      entropy = s_to_power_minus_one * s / static_cast<Real>(_power);
      entropy_prime = s_to_power_minus_one;
    }
    else
    {
      const Real product = s * (1.0 - s);
      const Real denominator = product * product + _regularization * _regularization;
      entropy = -std::log(std::sqrt(denominator));
      entropy_prime = -product * (1.0 - 2.0 * s) / denominator;
    }

    Real speed_square = 0.0;
    Real advection = 0.0;
    if (_transport_velocity)
      for (const auto i : make_range(3))
      {
        const Real velocity_i = MetaPhysicL::raw_value((*_transport_velocity)[_qp](i));
        speed_square += velocity_i * velocity_i;
        advection += velocity_i * MetaPhysicL::raw_value(_scalar_gradient[_qp](i));
      }
    Real source = _source ? MetaPhysicL::raw_value((*_source)[_qp]) : 0.0;
    for (const auto * additional_source : _sources)
      source += MetaPhysicL::raw_value((*additional_source)[_qp]);
    const Real entropy_transport =
        _entropy_flux_derivative
            ? MetaPhysicL::raw_value((*_entropy_flux_derivative)[_qp] * _scalar_gradient[_qp])
            : (_entropy_storage_coefficient
                   ? MetaPhysicL::raw_value((*_entropy_storage_coefficient)[_qp]) * advection
                   : advection);
    const Real entropy_storage =
        _entropy_storage_coefficient
            ? MetaPhysicL::raw_value((*_entropy_storage_coefficient_rate)[_qp]) * entropy +
                  MetaPhysicL::raw_value((*_entropy_storage_coefficient)[_qp]) * entropy_prime *
                      MetaPhysicL::raw_value(_scalar_dot[_qp])
            : entropy_prime * _storage_coefficient *
                  MetaPhysicL::raw_value(_scalar_dot[_qp]);
    Real entropy_residual;
    if (_supplied_entropy_residual)
      entropy_residual = MetaPhysicL::raw_value((*_supplied_entropy_residual)[_qp]);
    else if (_strong_residual)
      entropy_residual =
          entropy_prime * MetaPhysicL::raw_value((*_strong_residual)[_qp]);
    else
      entropy_residual = entropy_storage + entropy_prime * (entropy_transport - source);

    const Real h = _current_elem->hmin();
    const Real speed = std::sqrt(speed_square + _regularization * _regularization);
    const Real residual_magnitude =
        std::sqrt(entropy_residual * entropy_residual + _regularization * _regularization);
    const Real normalization =
        std::max({std::abs(_entropy_deviation_norm),
                  std::abs(entropy - _entropy_average),
                  _normalization_floor});
    const Real mu_linear = _lambda_linear * h * speed;
    const Real mu_entropy =
        _lambda_entropy * h * h * residual_magnitude / normalization;
    const Real mu = std::min(mu_linear, mu_entropy);
    const ADReal mass_coefficient =
        _mass_coefficient_property ? (*_mass_coefficient_property)[_qp] : _mass_coefficient;
    const ADReal diffusion_coefficient = mass_coefficient * mu;

    _entropy_value[_qp] = entropy;
    _entropy_residual[_qp] = entropy_residual;
    _linear_viscosity[_qp] = mu_linear;
    _residual_viscosity[_qp] = mu_entropy;
    _stabilization_viscosity[_qp] = mu;
    _reference_flux[_qp] = -diffusion_coefficient * _scalar_gradient[_qp];
    ADRankTwoTensor mobility;
    for (const auto i : make_range(3))
      mobility(i, i) = diffusion_coefficient;
    _mobility[_qp] = mobility;
    return;
  }

  const ADReal s = _scalar[_qp];
  ADReal entropy;
  ADReal entropy_prime;
  if (_entropy == "power")
  {
    ADReal s_to_power_minus_one = 1.0;
    for (unsigned int exponent = 0; exponent + 1 < _power; ++exponent)
      s_to_power_minus_one *= s;
    const ADReal s_to_power = s_to_power_minus_one * s;
    entropy = s_to_power / static_cast<Real>(_power);
    entropy_prime = s_to_power_minus_one;
  }
  else
  {
    const ADReal product = s * (1.0 - s);
    const ADReal smooth_abs = sqrt(product * product + _regularization * _regularization);
    entropy = -log(smooth_abs);
    entropy_prime = -product * (1.0 - 2.0 * s) /
                    (product * product + _regularization * _regularization);
  }

  const ADRealVectorValue velocity =
      _transport_velocity ? (*_transport_velocity)[_qp] : ADRealVectorValue();
  ADReal source = _source ? (*_source)[_qp] : 0.0;
  for (const auto * additional_source : _sources)
    source += (*additional_source)[_qp];
  const ADReal entropy_transport =
      _entropy_flux_derivative
          ? (*_entropy_flux_derivative)[_qp] * _scalar_gradient[_qp]
          : (_entropy_storage_coefficient ? (*_entropy_storage_coefficient)[_qp] : ADReal(1.0)) *
                (velocity * _scalar_gradient[_qp]);
  const ADReal entropy_storage =
      _entropy_storage_coefficient
          ? (*_entropy_storage_coefficient_rate)[_qp] * entropy +
                (*_entropy_storage_coefficient)[_qp] * entropy_prime * _scalar_dot[_qp]
          : entropy_prime * _storage_coefficient * _scalar_dot[_qp];
  ADReal entropy_residual;
  if (_supplied_entropy_residual)
    entropy_residual = (*_supplied_entropy_residual)[_qp];
  else if (_strong_residual)
    entropy_residual = entropy_prime * (*_strong_residual)[_qp];
  else
    entropy_residual = entropy_storage + entropy_prime * (entropy_transport - source);

  const Real h = _current_elem->hmin();
  const ADReal speed = sqrt(velocity * velocity +
                            _regularization * _regularization);
  const ADReal residual_magnitude =
      sqrt(entropy_residual * entropy_residual +
           _regularization * _regularization);
  const Real local_entropy_deviation =
      std::abs(MetaPhysicL::raw_value(entropy) - _entropy_average);
  const Real normalization =
      std::max({std::abs(_entropy_deviation_norm),
                local_entropy_deviation,
                _normalization_floor});
  const ADReal mu_linear = _lambda_linear * h * speed;
  const ADReal mu_entropy =
      _lambda_entropy * h * h * residual_magnitude / normalization;
  const ADReal mu = MetaPhysicL::raw_value(mu_linear) < MetaPhysicL::raw_value(mu_entropy)
                        ? mu_linear
                        : mu_entropy;
  const ADReal mass_coefficient =
      _mass_coefficient_property ? (*_mass_coefficient_property)[_qp] : _mass_coefficient;
  const ADReal diffusion_coefficient = mass_coefficient * mu;

  _entropy_value[_qp] = entropy;
  _entropy_residual[_qp] = entropy_residual;
  _linear_viscosity[_qp] = mu_linear;
  _residual_viscosity[_qp] = mu_entropy;
  _stabilization_viscosity[_qp] = mu;
  _reference_flux[_qp] = -diffusion_coefficient * _scalar_gradient[_qp];

  ADRankTwoTensor mobility;
  for (const auto i : make_range(3))
    mobility(i, i) = diffusion_coefficient;
  _mobility[_qp] = mobility;
}
