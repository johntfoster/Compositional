#include "ADPhaseMomentumDragTerm.h"

registerMooseObject("MulticomponentReactiveFlowApp", ADPhaseMomentumDragTerm);

InputParameters
ADPhaseMomentumDragTerm::validParams()
{
  InputParameters params = ADKernelValue::validParams();
  params.addClassDescription(
      "Atomic +J*(mu*phi^2/k)*(v_f-v_s) drag contribution. Pairwise or nonlinear "
      "interaction laws can instead be supplied with ADPhaseMomentumVectorSourceTerm.");
  params.addRequiredRangeCheckedParam<unsigned int>("component", "component<3",
                                                     "Momentum component.");
  params.addRequiredCoupledVar("phase_velocity", "All phase velocity components.");
  params.addRequiredCoupledVar("solid_displacements", "All skeleton displacement components.");
  params.addRequiredCoupledVar("phase_fraction", "Phase volume fraction.");
  params.addRangeCheckedParam<Real>("viscosity", 1.0, "viscosity>0", "Constant viscosity.");
  params.addRangeCheckedParam<Real>("permeability", 1.0, "permeability>0",
                                    "Constant permeability.");
  params.addParam<MaterialPropertyName>("viscosity_name", "", "Optional positive AD viscosity.");
  params.addParam<MaterialPropertyName>("permeability_name", "",
                                        "Optional positive AD permeability.");
  params.addParam<MaterialPropertyName>("solid_jacobian_name", "solid_reference_J", "J.");
  return params;
}

ADPhaseMomentumDragTerm::ADPhaseMomentumDragTerm(const InputParameters & parameters)
  : ADKernelValue(parameters),
    _component(getParam<unsigned int>("component")),
    _dim(_mesh.dimension()),
    _phase_fraction(adCoupledValue("phase_fraction")),
    _J(getADMaterialProperty<Real>("solid_jacobian_name")),
    _viscosity_property(getParam<MaterialPropertyName>("viscosity_name").empty()
                            ? nullptr
                            : &getADMaterialProperty<Real>("viscosity_name")),
    _permeability_property(getParam<MaterialPropertyName>("permeability_name").empty()
                               ? nullptr
                               : &getADMaterialProperty<Real>("permeability_name")),
    _viscosity(getParam<Real>("viscosity")),
    _permeability(getParam<Real>("permeability"))
{
  if (_component >= _dim)
    paramError("component", "component must be smaller than mesh dimension.");
  if (coupledComponents("phase_velocity") != _dim ||
      coupledComponents("solid_displacements") != _dim)
    paramError("phase_velocity", "Provide exactly dim phase velocities and displacements.");
  if (_viscosity_property && isParamSetByUser("viscosity"))
    paramError("viscosity_name", "Choose viscosity or viscosity_name.");
  if (_permeability_property && isParamSetByUser("permeability"))
    paramError("permeability_name", "Choose permeability or permeability_name.");
  for (const auto i : make_range(_dim))
  {
    _phase_velocities.push_back(&adCoupledValue("phase_velocity", i));
    _solid_velocities.push_back(&adCoupledDot("solid_displacements", i));
  }
}

ADReal
ADPhaseMomentumDragTerm::precomputeQpResidual()
{
  const ADReal viscosity =
      _viscosity_property ? (*_viscosity_property)[_qp] : ADReal(_viscosity);
  const ADReal permeability =
      _permeability_property ? (*_permeability_property)[_qp] : ADReal(_permeability);
  const ADReal relative_velocity =
      (*_phase_velocities[_component])[_qp] - (*_solid_velocities[_component])[_qp];
  return _J[_qp] * viscosity * _phase_fraction[_qp] * _phase_fraction[_qp] /
         permeability * relative_velocity;
}
