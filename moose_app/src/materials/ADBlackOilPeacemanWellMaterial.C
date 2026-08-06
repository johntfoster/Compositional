#include "ADBlackOilPeacemanWellMaterial.h"

#include "metaphysicl/raw_type.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADBlackOilPeacemanWellMaterial);

InputParameters
ADBlackOilPeacemanWellMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Computes BHP- or surface-rate-controlled Peaceman phase rates and reference water, "
      "stock-tank oil, and stock-tank gas component sources on a completion block, with an "
      "optional BHP constraint for rate control.");
  params.addParam<MooseEnum>("pressure_source",
                             MooseEnum("material coupled", "material"),
                             "Source for the three phase pressures.");
  params.addParam<MaterialPropertyName>("water_pressure_name", "", "Water pressure property.");
  params.addParam<MaterialPropertyName>("oil_pressure_name", "", "Oil pressure property.");
  params.addParam<MaterialPropertyName>("gas_pressure_name", "", "Gas pressure property.");
  params.addCoupledVar("water_pressure", "Water pressure variable when pressure_source=coupled.");
  params.addCoupledVar("oil_pressure", "Oil pressure variable when pressure_source=coupled.");
  params.addCoupledVar("gas_pressure", "Gas pressure variable when pressure_source=coupled.");
  params.addParam<MooseEnum>(
      "mobility_source",
      MooseEnum("mobility relative_permeability_viscosity", "mobility"),
      "Use supplied well-mobility properties or compute k_r/mu from separate properties.");
  params.addParam<MaterialPropertyName>("water_mobility_name", "", "Water well mobility k_rw/mu_w.");
  params.addParam<MaterialPropertyName>("oil_mobility_name", "", "Oil well mobility k_ro/mu_o.");
  params.addParam<MaterialPropertyName>("gas_mobility_name", "", "Gas well mobility k_rg/mu_g.");
  params.addParam<MaterialPropertyName>("water_relative_permeability_name", "", "Water relative permeability.");
  params.addParam<MaterialPropertyName>("oil_relative_permeability_name", "", "Oil relative permeability.");
  params.addParam<MaterialPropertyName>("gas_relative_permeability_name", "", "Gas relative permeability.");
  params.addParam<MaterialPropertyName>("water_viscosity_name", "", "Water viscosity.");
  params.addParam<MaterialPropertyName>("oil_viscosity_name", "", "Oil viscosity.");
  params.addParam<MaterialPropertyName>("gas_viscosity_name", "", "Gas viscosity.");
  params.addRequiredParam<MaterialPropertyName>("water_fvf_name", "Water B_w property.");
  params.addRequiredParam<MaterialPropertyName>("oil_fvf_name", "Oil B_o property.");
  params.addRequiredParam<MaterialPropertyName>("gas_fvf_name", "Gas B_g property.");
  params.addRequiredParam<MaterialPropertyName>(
      "solution_gas_oil_ratio_name", "Dissolved gas-oil ratio R_s property.");
  params.addParam<bool>(
      "apply_datum_correction", false,
      "Convert the reported datum BHP to completion depth using a wellbore hydrostatic density.");
  params.addParam<MooseEnum>(
      "wellbore_density_source", MooseEnum("constant material", "constant"),
      "Source for the hydrostatic wellbore density.");
  params.addParam<Real>("wellbore_density", 0.0,
                        "Positive constant wellbore density when datum correction is enabled.");
  params.addParam<MaterialPropertyName>("wellbore_density_name", "",
                                        "Wellbore density property when its source is material.");
  params.addParam<Real>("completion_depth", 0.0,
                        "Positive-downward completion reference depth.");
  params.addParam<Real>("bhp_datum_depth", 0.0,
                        "Positive-downward depth at which BHP and its limit are reported.");
  params.addRangeCheckedParam<Real>("gravity_magnitude", 9.80665,
                                    "gravity_magnitude>=0", "Gravity magnitude for datum conversion.");
  params.addRequiredRangeCheckedParam<Real>("well_index", "well_index>=0", "Peaceman well index.");
  params.addParam<MooseEnum>(
      "control_mode",
      MooseEnum("bhp scalar_bhp oil_surface_rate gas_surface_rate", "bhp"),
      "Completion control: prescribed BHP, a coupled scalar BHP, stock-tank oil rate, or "
      "stock-tank gas rate.");
  params.addCoupledVar("bottom_hole_pressure_variable", "Shared scalar well BHP.");
  params.addParam<MooseEnum>(
      "injection_phase",
      MooseEnum("none water oil gas", "none"),
      "Injected phase for a negative surface-rate target. Production controls use none.");
  params.addParam<Real>("bottom_hole_pressure", 0.0, "Prescribed BHP for bhp control mode.");
  params.addParam<Real>(
      "target_surface_rate",
      0.0,
      "Production-positive target stock-tank rate for a surface-rate control mode.");
  params.addParam<bool>(
      "apply_bhp_limit", false, "Apply a minimum or maximum BHP limit to a rate control.");
  params.addParam<MooseEnum>(
      "bhp_limit_type", MooseEnum("minimum maximum", "minimum"), "Type of BHP limit.");
  params.addParam<Real>("bhp_limit", 0.0, "BHP limit applied when apply_bhp_limit is true.");
  params.addRequiredRangeCheckedParam<Real>("completion_reference_volume",
                                            "completion_reference_volume>0",
                                            "Reference volume over which the source is applied.");
  params.addRequiredRangeCheckedParam<Real>(
      "water_surface_density", "water_surface_density>0", "Stock-tank water density.");
  params.addRequiredRangeCheckedParam<Real>(
      "oil_surface_density", "oil_surface_density>0", "Stock-tank oil density.");
  params.addRequiredRangeCheckedParam<Real>(
      "gas_surface_density", "gas_surface_density>0", "Stock-tank gas density.");
  params.addParam<std::string>("property_prefix", "black_oil_well", "Property-name prefix.");
  return params;
}

ADBlackOilPeacemanWellMaterial::ADBlackOilPeacemanWellMaterial(
    const InputParameters & parameters)
  : Material(parameters),
    _pressure_source(getParam<MooseEnum>("pressure_source")),
    _water_pressure_property(_pressure_source == "material"
                                 ? &getADMaterialProperty<Real>("water_pressure_name")
                                 : nullptr),
    _oil_pressure_property(_pressure_source == "material"
                               ? &getADMaterialProperty<Real>("oil_pressure_name")
                               : nullptr),
    _gas_pressure_property(_pressure_source == "material"
                               ? &getADMaterialProperty<Real>("gas_pressure_name")
                               : nullptr),
    _water_pressure_variable(_pressure_source == "coupled" ? &adCoupledValue("water_pressure")
                                                            : nullptr),
    _oil_pressure_variable(_pressure_source == "coupled" ? &adCoupledValue("oil_pressure")
                                                          : nullptr),
    _gas_pressure_variable(_pressure_source == "coupled" ? &adCoupledValue("gas_pressure")
                                                          : nullptr),
    _wellbore_density_property(
        getParam<MooseEnum>("wellbore_density_source") == "material" &&
                !getParam<MaterialPropertyName>("wellbore_density_name").empty()
            ? &getADMaterialProperty<Real>("wellbore_density_name")
            : nullptr),
    _bottom_hole_pressure_variable(
        getParam<MooseEnum>("control_mode") == "scalar_bhp"
            ? &adCoupledScalarValue("bottom_hole_pressure_variable")
            : nullptr),
    _mobility_source(getParam<MooseEnum>("mobility_source")),
    _water_mobility(_mobility_source == "mobility"
                        ? &getADMaterialProperty<Real>("water_mobility_name")
                        : nullptr),
    _oil_mobility(_mobility_source == "mobility"
                      ? &getADMaterialProperty<Real>("oil_mobility_name")
                      : nullptr),
    _gas_mobility(_mobility_source == "mobility"
                      ? &getADMaterialProperty<Real>("gas_mobility_name")
                      : nullptr),
    _water_relative_permeability(
        _mobility_source == "relative_permeability_viscosity"
            ? &getADMaterialProperty<Real>("water_relative_permeability_name")
            : nullptr),
    _oil_relative_permeability(
        _mobility_source == "relative_permeability_viscosity"
            ? &getADMaterialProperty<Real>("oil_relative_permeability_name")
            : nullptr),
    _gas_relative_permeability(
        _mobility_source == "relative_permeability_viscosity"
            ? &getADMaterialProperty<Real>("gas_relative_permeability_name")
            : nullptr),
    _water_viscosity(_mobility_source == "relative_permeability_viscosity"
                         ? &getADMaterialProperty<Real>("water_viscosity_name")
                         : nullptr),
    _oil_viscosity(_mobility_source == "relative_permeability_viscosity"
                       ? &getADMaterialProperty<Real>("oil_viscosity_name")
                       : nullptr),
    _gas_viscosity(_mobility_source == "relative_permeability_viscosity"
                       ? &getADMaterialProperty<Real>("gas_viscosity_name")
                       : nullptr),
    _water_fvf(getADMaterialProperty<Real>("water_fvf_name")),
    _oil_fvf(getADMaterialProperty<Real>("oil_fvf_name")),
    _gas_fvf(getADMaterialProperty<Real>("gas_fvf_name")),
    _solution_gas_oil_ratio(getADMaterialProperty<Real>("solution_gas_oil_ratio_name")),
    _well_index(getParam<Real>("well_index")),
    _control_mode(getParam<MooseEnum>("control_mode")),
    _injection_phase(getParam<MooseEnum>("injection_phase")),
    _bottom_hole_pressure(getParam<Real>("bottom_hole_pressure")),
    _target_surface_rate(getParam<Real>("target_surface_rate")),
    _apply_datum_correction(getParam<bool>("apply_datum_correction")),
    _wellbore_density_source(getParam<MooseEnum>("wellbore_density_source")),
    _wellbore_density(getParam<Real>("wellbore_density")),
    _completion_depth(getParam<Real>("completion_depth")),
    _bhp_datum_depth(getParam<Real>("bhp_datum_depth")),
    _gravity_magnitude(getParam<Real>("gravity_magnitude")),
    _apply_bhp_limit(getParam<bool>("apply_bhp_limit")),
    _bhp_limit_type(getParam<MooseEnum>("bhp_limit_type")),
    _bhp_limit(getParam<Real>("bhp_limit")),
    _completion_reference_volume(getParam<Real>("completion_reference_volume")),
    _water_surface_density(getParam<Real>("water_surface_density")),
    _oil_surface_density(getParam<Real>("oil_surface_density")),
    _gas_surface_density(getParam<Real>("gas_surface_density")),
    _water_reservoir_rate(declareADProperty<Real>(
        getParam<std::string>("property_prefix") + "_water_reservoir_rate")),
    _oil_reservoir_rate(declareADProperty<Real>(
        getParam<std::string>("property_prefix") + "_oil_reservoir_rate")),
    _gas_reservoir_rate(declareADProperty<Real>(
        getParam<std::string>("property_prefix") + "_gas_reservoir_rate")),
    _water_surface_rate(
        declareADProperty<Real>(getParam<std::string>("property_prefix") + "_water_surface_rate")),
    _oil_surface_rate(
        declareADProperty<Real>(getParam<std::string>("property_prefix") + "_oil_surface_rate")),
    _free_gas_surface_rate(declareADProperty<Real>(getParam<std::string>("property_prefix") +
                                                   "_free_gas_surface_rate")),
    _gas_surface_rate(
        declareADProperty<Real>(getParam<std::string>("property_prefix") + "_gas_surface_rate")),
    _water_reference_component_source(declareADProperty<Real>(
        getParam<std::string>("property_prefix") + "_water_reference_component_source")),
    _oil_reference_component_source(declareADProperty<Real>(
        getParam<std::string>("property_prefix") + "_oil_reference_component_source")),
    _free_gas_reference_component_source(declareADProperty<Real>(
        getParam<std::string>("property_prefix") + "_free_gas_reference_component_source")),
    _gas_reference_component_source(declareADProperty<Real>(
        getParam<std::string>("property_prefix") + "_gas_reference_component_source")),
    _effective_bottom_hole_pressure(declareADProperty<Real>(
        getParam<std::string>("property_prefix") + "_effective_bottom_hole_pressure")),
    _datum_bottom_hole_pressure(declareADProperty<Real>(
        getParam<std::string>("property_prefix") + "_datum_bottom_hole_pressure")),
    _datum_pressure_correction(declareADProperty<Real>(
        getParam<std::string>("property_prefix") + "_datum_pressure_correction")),
    _control_surface_rate_residual(declareADProperty<Real>(
        getParam<std::string>("property_prefix") + "_control_surface_rate_residual")),
    _control_surface_productivity(declareADProperty<Real>(
        getParam<std::string>("property_prefix") + "_control_surface_productivity"))
{
  const auto require_property_name = [this](const char * parameter) {
    if (getParam<MaterialPropertyName>(parameter).empty())
      paramError(parameter, "Supply the selected well-mobility property.");
  };
  if (_mobility_source == "mobility")
  {
    require_property_name("water_mobility_name");
    require_property_name("oil_mobility_name");
    require_property_name("gas_mobility_name");
  }
  else
  {
    require_property_name("water_relative_permeability_name");
    require_property_name("oil_relative_permeability_name");
    require_property_name("gas_relative_permeability_name");
    require_property_name("water_viscosity_name");
    require_property_name("oil_viscosity_name");
    require_property_name("gas_viscosity_name");
  }
  if (_pressure_source == "material")
  {
    if (getParam<MaterialPropertyName>("water_pressure_name").empty())
      paramError("water_pressure_name", "Supply a water pressure property.");
    if (getParam<MaterialPropertyName>("oil_pressure_name").empty())
      paramError("oil_pressure_name", "Supply an oil pressure property.");
    if (getParam<MaterialPropertyName>("gas_pressure_name").empty())
      paramError("gas_pressure_name", "Supply a gas pressure property.");
    if (isCoupled("water_pressure") || isCoupled("oil_pressure") || isCoupled("gas_pressure"))
      paramError("pressure_source", "Do not couple pressure variables when using material pressures.");
  }
  else
  {
    if (!isCoupled("water_pressure") || !isCoupled("oil_pressure") || !isCoupled("gas_pressure"))
      paramError("pressure_source", "Couple all three phase pressures when pressure_source=coupled.");
  }
  if (getParam<std::string>("property_prefix").empty())
    paramError("property_prefix", "The property prefix must be nonempty.");
  if (_control_mode == "bhp" && !isParamSetByUser("bottom_hole_pressure"))
    paramError("bottom_hole_pressure", "Supply bottom_hole_pressure for bhp control.");
  if (_control_mode == "scalar_bhp" && !isCoupledScalar("bottom_hole_pressure_variable"))
    paramError("bottom_hole_pressure_variable",
               "Couple a scalar BHP variable when control_mode=scalar_bhp.");
  if (_control_mode != "scalar_bhp" && isCoupledScalar("bottom_hole_pressure_variable"))
    paramError("bottom_hole_pressure_variable",
               "Use bottom_hole_pressure_variable only with control_mode=scalar_bhp.");
  if (_control_mode != "bhp" && _control_mode != "scalar_bhp" &&
      !isParamSetByUser("target_surface_rate"))
    paramError("target_surface_rate", "Supply target_surface_rate for a rate control.");
  if (_target_surface_rate < 0.0 && _injection_phase == "none")
    paramError("injection_phase", "Supply the injected phase for a negative surface-rate target.");
  if (_target_surface_rate >= 0.0 && _injection_phase != "none")
    paramError("injection_phase", "Use injection_phase=none for a nonnegative production target.");
  if (_injection_phase == "water" && _control_mode != "bhp")
    paramError("injection_phase", "Water surface-rate control is not yet implemented.");
  if (_injection_phase == "oil" && _control_mode != "oil_surface_rate" &&
      _control_mode != "scalar_bhp")
    paramError("injection_phase", "Oil injection requires oil_surface_rate control.");
  if (_injection_phase == "gas" && _control_mode != "gas_surface_rate" &&
      _control_mode != "scalar_bhp")
    paramError("injection_phase", "Gas injection requires gas_surface_rate control.");
  if ((_control_mode == "bhp" || _control_mode == "scalar_bhp") && _apply_bhp_limit)
    paramError("apply_bhp_limit", "A BHP limit applies only to a surface-rate control.");
  if (_apply_datum_correction)
  {
    if (_wellbore_density_source == "constant" && _wellbore_density <= 0.0)
      paramError("wellbore_density", "Supply a positive wellbore density for datum correction.");
    if (_wellbore_density_source == "material" && !_wellbore_density_property)
      paramError("wellbore_density_name",
                 "Supply a wellbore density property for material-sourced datum correction.");
  }
  else if (_wellbore_density_property || _wellbore_density > 0.0 ||
           isParamSetByUser("completion_depth") || isParamSetByUser("bhp_datum_depth"))
    paramError("apply_datum_correction",
               "Enable datum correction before supplying wellbore density or depth data.");
}

void
ADBlackOilPeacemanWellMaterial::computeQpProperties()
{
  const ADReal water_pressure = _pressure_source == "material"
                                    ? (*_water_pressure_property)[_qp]
                                    : (*_water_pressure_variable)[_qp];
  const ADReal oil_pressure = _pressure_source == "material"
                                  ? (*_oil_pressure_property)[_qp]
                                  : (*_oil_pressure_variable)[_qp];
  const ADReal gas_pressure = _pressure_source == "material"
                                  ? (*_gas_pressure_property)[_qp]
                                  : (*_gas_pressure_variable)[_qp];
  ADReal water_mobility;
  ADReal oil_mobility;
  ADReal gas_mobility;
  if (_mobility_source == "mobility")
  {
    water_mobility = (*_water_mobility)[_qp];
    oil_mobility = (*_oil_mobility)[_qp];
    gas_mobility = (*_gas_mobility)[_qp];
  }
  else
  {
    if (MetaPhysicL::raw_value((*_water_viscosity)[_qp]) <= 0.0 ||
        MetaPhysicL::raw_value((*_oil_viscosity)[_qp]) <= 0.0 ||
        MetaPhysicL::raw_value((*_gas_viscosity)[_qp]) <= 0.0)
      mooseError(name(), ": well viscosities must be positive.");
    water_mobility = (*_water_relative_permeability)[_qp] / (*_water_viscosity)[_qp];
    oil_mobility = (*_oil_relative_permeability)[_qp] / (*_oil_viscosity)[_qp];
    gas_mobility = (*_gas_relative_permeability)[_qp] / (*_gas_viscosity)[_qp];
  }
  if (MetaPhysicL::raw_value(water_mobility) < 0.0 ||
      MetaPhysicL::raw_value(oil_mobility) < 0.0 ||
      MetaPhysicL::raw_value(gas_mobility) < 0.0)
    mooseError(name(), ": well mobilities must be nonnegative.");
  const ADReal wellbore_density =
      _wellbore_density_source == "material" && _wellbore_density_property
          ? (*_wellbore_density_property)[_qp]
          : ADReal(_wellbore_density);
  if (_apply_datum_correction && MetaPhysicL::raw_value(wellbore_density) <= 0.0)
    mooseError(name(), ": datum correction requires positive wellbore density.");
  const ADReal datum_pressure_correction =
      _apply_datum_correction
          ? wellbore_density * _gravity_magnitude * (_completion_depth - _bhp_datum_depth)
          : ADReal(0.0);
  ADReal effective_bhp = (_control_mode == "scalar_bhp"
                              ? (*_bottom_hole_pressure_variable)[0]
                              : ADReal(_bottom_hole_pressure)) +
                         datum_pressure_correction;
  if (_control_mode == "oil_surface_rate")
  {
    const ADReal oil_surface_productivity = _well_index * oil_mobility / _oil_fvf[_qp];
    if (MetaPhysicL::raw_value(oil_surface_productivity) <= 0.0)
      mooseError(name(), ": oil surface-rate control requires positive oil productivity.");
    effective_bhp = oil_pressure - _target_surface_rate / oil_surface_productivity;
  }
  else if (_control_mode == "gas_surface_rate")
  {
    const ADReal gas_surface_productivity = _injection_phase == "gas"
                                                ? _well_index * gas_mobility / _gas_fvf[_qp]
                                                : _well_index *
                                                      (gas_mobility / _gas_fvf[_qp] +
                                                       _solution_gas_oil_ratio[_qp] *
                                                           oil_mobility / _oil_fvf[_qp]);
    if (MetaPhysicL::raw_value(gas_surface_productivity) <= 0.0)
      mooseError(name(), ": gas surface-rate control requires positive gas productivity.");
    const ADReal gas_surface_pressure_term =
        _injection_phase == "gas"
            ? _well_index * gas_mobility * gas_pressure / _gas_fvf[_qp]
            : _well_index *
                  (gas_mobility * gas_pressure / _gas_fvf[_qp] +
                   _solution_gas_oil_ratio[_qp] * oil_mobility * oil_pressure /
                       _oil_fvf[_qp]);
    effective_bhp = (gas_surface_pressure_term - _target_surface_rate) /
                    gas_surface_productivity;
  }
  ADReal effective_datum_bhp = effective_bhp - datum_pressure_correction;
  if (_apply_bhp_limit)
  {
    if (_bhp_limit_type == "minimum" && MetaPhysicL::raw_value(effective_datum_bhp) < _bhp_limit)
      effective_datum_bhp = _bhp_limit;
    if (_bhp_limit_type == "maximum" && MetaPhysicL::raw_value(effective_datum_bhp) > _bhp_limit)
      effective_datum_bhp = _bhp_limit;
    effective_bhp = effective_datum_bhp + datum_pressure_correction;
  }
  _effective_bottom_hole_pressure[_qp] = effective_bhp;
  _datum_bottom_hole_pressure[_qp] = effective_datum_bhp;
  _datum_pressure_correction[_qp] = datum_pressure_correction;

  _water_reservoir_rate[_qp] =
      _well_index * water_mobility * (water_pressure - effective_bhp);
  _oil_reservoir_rate[_qp] =
      _well_index * oil_mobility * (oil_pressure - effective_bhp);
  _gas_reservoir_rate[_qp] =
      _well_index * gas_mobility * (gas_pressure - effective_bhp);

  if (_injection_phase == "oil")
  {
    _water_reservoir_rate[_qp] = 0.0;
    _gas_reservoir_rate[_qp] = 0.0;
  }
  else if (_injection_phase == "gas")
  {
    _water_reservoir_rate[_qp] = 0.0;
    _oil_reservoir_rate[_qp] = 0.0;
  }

  _water_surface_rate[_qp] = _water_reservoir_rate[_qp] / _water_fvf[_qp];
  _oil_surface_rate[_qp] = _oil_reservoir_rate[_qp] / _oil_fvf[_qp];
  _free_gas_surface_rate[_qp] = _gas_reservoir_rate[_qp] / _gas_fvf[_qp];
  _gas_surface_rate[_qp] =
      _free_gas_surface_rate[_qp] + _solution_gas_oil_ratio[_qp] * _oil_surface_rate[_qp];
  if (_injection_phase == "gas")
    _control_surface_productivity[_qp] = _well_index * gas_mobility / _gas_fvf[_qp];
  else if (_control_mode == "oil_surface_rate" || _control_mode == "scalar_bhp")
    _control_surface_productivity[_qp] = _well_index * oil_mobility / _oil_fvf[_qp];
  else
    _control_surface_productivity[_qp] =
        _well_index * (gas_mobility / _gas_fvf[_qp] +
                       _solution_gas_oil_ratio[_qp] * oil_mobility / _oil_fvf[_qp]);
  if (_control_mode == "oil_surface_rate")
    _control_surface_rate_residual[_qp] = _oil_surface_rate[_qp] - _target_surface_rate;
  else if (_control_mode == "gas_surface_rate")
    _control_surface_rate_residual[_qp] = _gas_surface_rate[_qp] - _target_surface_rate;
  else
    _control_surface_rate_residual[_qp] = 0.0;

  _water_reference_component_source[_qp] =
      -_water_surface_density * _water_surface_rate[_qp] / _completion_reference_volume;
  _oil_reference_component_source[_qp] =
      -_oil_surface_density * _oil_surface_rate[_qp] / _completion_reference_volume;
  _free_gas_reference_component_source[_qp] =
      -_gas_surface_density * _free_gas_surface_rate[_qp] / _completion_reference_volume;
  _gas_reference_component_source[_qp] =
      -_gas_surface_density * _gas_surface_rate[_qp] / _completion_reference_volume;
}
