mesh_nx := 8
solve_dt := 1
solve_steps := 1

!include ../../../input/includes/mesh/generated_1d_q2.i
!include ../../../input/includes/fields/solid_q2_aux_1d.i

[Variables]
  [component_storage]
  []
[]

[AuxVariables]
  [neutral_potential]
    family = LAGRANGE
    order = FIRST
  []
  [neutral_potential_enr]
    family = MONOMIAL
    order = CONSTANT
  []
  [electric_potential]
    family = LAGRANGE
    order = FIRST
  []
  [electric_potential_enr]
    family = MONOMIAL
    order = CONSTANT
  []
  [temperature]
    family = LAGRANGE
    order = FIRST
  []
  [temperature_enr]
    family = MONOMIAL
    order = CONSTANT
  []
  [transport_force_x]
    family = MONOMIAL
    order = CONSTANT
  []
  [current_flux_x]
    family = MONOMIAL
    order = CONSTANT
  []
  [reference_flux_x]
    family = MONOMIAL
    order = CONSTANT
  []
  [charge_flux_x]
    family = MONOMIAL
    order = CONSTANT
  []
  [electric_work]
    family = MONOMIAL
    order = CONSTANT
  []
  [reference_component_source]
    family = MONOMIAL
    order = CONSTANT
  []
[]

[Functions]
  [zero]
    type = ParsedFunction
    expression = '0'
  []
  [ux_exact]
    type = ParsedFunction
    expression = '0.1*x^2'
  []
  [neutral_potential_backbone_exact]
    type = ParsedFunction
    expression = 'x'
  []
  [neutral_potential_enrichment_exact]
    type = ParsedFunction
    expression = '0.1'
  []
  [neutral_potential_exact]
    type = ParsedFunction
    expression = '0.1+x'
  []
  [electric_potential_backbone_exact]
    type = ParsedFunction
    expression = '2*x'
  []
  [electric_potential_enrichment_exact]
    type = ParsedFunction
    expression = '5'
  []
  [electric_potential_exact]
    type = ParsedFunction
    expression = '5+2*x'
  []
  [temperature_backbone_exact]
    type = ParsedFunction
    expression = '1+x'
  []
  [temperature_enrichment_exact]
    type = ParsedFunction
    expression = '0.5'
  []
  [temperature_exact]
    type = ParsedFunction
    expression = '1.5+x'
  []
  [mobility_exact]
    type = ParsedFunction
    expression = '0.5+0.2*(1.5+x)^2'
  []
  [transport_force_x_exact]
    type = ParsedFunction
    expression = '4.75'
  []
  [transport_force_antiderivative_exact]
    type = ParsedFunction
    expression = '4.75*x'
  []
  [current_flux_x_exact]
    type = ParsedFunction
    expression = '-4.75*(0.5+0.2*(1.5+x)^2)'
  []
  [charge_flux_x_exact]
    type = ParsedFunction
    expression = '-9.5*(0.5+0.2*(1.5+x)^2)'
  []
  [current_flux_antiderivative_exact]
    type = ParsedFunction
    expression = '-4.5125*x-1.425*x^2-(0.95/3)*x^3'
  []
  [charge_flux_antiderivative_exact]
    type = ParsedFunction
    expression = '-9.025*x-2.85*x^2-(1.9/3)*x^3'
  []
  [electric_work_exact]
    type = ParsedFunction
    expression = '19*(0.5+0.2*(1.5+x)^2)'
  []
  [reference_component_source_exact]
    type = ParsedFunction
    expression = '-2.85-1.9*x'
  []
  [current_component_source_exact]
    type = ParsedFunction
    expression = '(-2.85-1.9*x)/(1+0.2*x)'
  []
[]

[ICs]
  [component_storage_ic]
    type = FunctionIC
    variable = component_storage
    function = zero
  []
  [ux_ic]
    type = FunctionIC
    variable = ux
    function = ux_exact
  []
  [neutral_potential_ic]
    type = FunctionIC
    variable = neutral_potential
    function = neutral_potential_backbone_exact
  []
  [neutral_potential_enr_ic]
    type = FunctionIC
    variable = neutral_potential_enr
    function = neutral_potential_enrichment_exact
  []
  [electric_potential_ic]
    type = FunctionIC
    variable = electric_potential
    function = electric_potential_backbone_exact
  []
  [electric_potential_enr_ic]
    type = FunctionIC
    variable = electric_potential_enr
    function = electric_potential_enrichment_exact
  []
  [temperature_ic]
    type = FunctionIC
    variable = temperature
    function = temperature_backbone_exact
  []
  [temperature_enr_ic]
    type = FunctionIC
    variable = temperature_enr
    function = temperature_enrichment_exact
  []
[]

[UserObjects]
  [phases]
    type = PhaseRegistry
    phases = 'solid oil'
    reference_phase = solid
  []
[]

!include ../../../input/includes/materials/solid_kinematics_1d.i

[Materials]
  [neutral_potential_reconstructed]
    type = ADEGReconstructedScalarMaterial
    field_name = neutral_potential
    backbone = neutral_potential
    enrichment = neutral_potential_enr
  []
  [electric_potential_reconstructed]
    type = ADEGReconstructedScalarMaterial
    field_name = electric_potential
    backbone = electric_potential
    enrichment = electric_potential_enr
  []
  [temperature_reconstructed]
    type = ADEGReconstructedScalarMaterial
    field_name = temperature
    backbone = temperature
    enrichment = temperature_enr
  []
  [nonlinear_mobility]
    type = ADParsedMaterial
    material_property_names = 'temperature_total'
    property_name = charged_nonlinear_mobility
    expression = '0.5+0.2*temperature_total^2'
  []
  [scalar_constants]
    type = ADGenericConstantMaterial
    prop_names = 'oil_eta0'
    prop_values = '1'
  []
  [vector_constants]
    type = ADGenericConstantVectorMaterial
    prop_names = 'oil_reference_relative_mass_flux'
    prop_values = '0 0 0'
  []
  [charged_flux]
    type = ADChargedNonisothermalComponentFluxMaterial
    neutral_potential_gradient_name = neutral_potential_total_gradient
    electric_potential_gradient_name = electric_potential_total_gradient
    temperature_gradient_name = temperature_total_gradient
    mobility_name = charged_nonlinear_mobility
    charge_number = 2
    thermal_force_coefficient = -0.25
    current_component_flux_name = charged_current_component_flux
    current_charge_flux_name = charged_current_charge_flux
  []
  [component_flux]
    type = ADRegisteredPhaseComponentFluxMaterial
    phase_registry = phases
    phases = 'oil'
    component = 0
    phase_reference_relative_mass_flux_names = 'oil_reference_relative_mass_flux'
    phase_component_mass_fraction_names = 'oil_eta0'
    current_component_extra_flux_material_name = charged_current_component_flux
    current_component_source = current_component_source_exact
  []
[]

[AuxKernels]
  [ux_prescribed]
    type = FunctionAux
    variable = ux
    function = ux_exact
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [transport_force_x_aux]
    type = ADMaterialRealVectorValueAux
    variable = transport_force_x
    property = component_transport_force
    component = 0
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [current_flux_x_aux]
    type = ADMaterialRealVectorValueAux
    variable = current_flux_x
    property = charged_current_component_flux
    component = 0
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [reference_flux_x_aux]
    type = ADMaterialRealVectorValueAux
    variable = reference_flux_x
    property = reference_component_flux
    component = 0
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [charge_flux_x_aux]
    type = ADMaterialRealVectorValueAux
    variable = charge_flux_x
    property = charged_current_charge_flux
    component = 0
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [electric_work_aux]
    type = ADMaterialRealAux
    variable = electric_work
    property = electric_field_work
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [reference_component_source_aux]
    type = ADMaterialRealAux
    variable = reference_component_source
    property = reference_component_source
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]

[Kernels]
  [component_balance]
    type = ADReferenceFluidComponentBalance
    variable = component_storage
  []
[]

[BCs]
  [component_storage_exact]
    type = FunctionDirichletBC
    variable = component_storage
    boundary = 'left right'
    function = zero
  []
[]

[Postprocessors]
  [ux_l2]
    type = ElementL2Error
    variable = ux
    function = ux_exact
  []
  [neutral_potential_total_l2]
    type = ADMaterialScalarL2Error
    property = neutral_potential_total
    function = neutral_potential_exact
  []
  [neutral_potential_gradient_l2]
    type = ADMaterialVectorL2Error
    property = neutral_potential_total_gradient
    gradient_function = neutral_potential_exact
  []
  [electric_potential_total_l2]
    type = ADMaterialScalarL2Error
    property = electric_potential_total
    function = electric_potential_exact
  []
  [electric_potential_gradient_l2]
    type = ADMaterialVectorL2Error
    property = electric_potential_total_gradient
    gradient_function = electric_potential_exact
  []
  [temperature_total_l2]
    type = ADMaterialScalarL2Error
    property = temperature_total
    function = temperature_exact
  []
  [temperature_gradient_l2]
    type = ADMaterialVectorL2Error
    property = temperature_total_gradient
    gradient_function = temperature_exact
  []
  [mobility_l2]
    type = ADMaterialScalarL2Error
    property = charged_nonlinear_mobility
    function = mobility_exact
  []
  [component_balance_l2]
    type = ElementL2Error
    variable = component_storage
    function = zero
  []
  [transport_force_x_l2]
    type = ADMaterialVectorL2Error
    property = component_transport_force
    gradient_function = transport_force_antiderivative_exact
  []
  [current_flux_x_l2]
    type = ADMaterialVectorL2Error
    property = charged_current_component_flux
    gradient_function = current_flux_antiderivative_exact
  []
  [reference_flux_x_l2]
    type = ADMaterialVectorL2Error
    property = reference_component_flux
    gradient_function = current_flux_antiderivative_exact
  []
  [charge_flux_x_l2]
    type = ADMaterialVectorL2Error
    property = charged_current_charge_flux
    gradient_function = charge_flux_antiderivative_exact
  []
  [electric_work_l2]
    type = ADMaterialScalarL2Error
    property = electric_field_work
    function = electric_work_exact
  []
  [reference_component_source_l2]
    type = ADMaterialScalarL2Error
    property = reference_component_source
    function = reference_component_source_exact
  []
  [reference_component_source_integral]
    type = ElementIntegralVariablePostprocessor
    variable = reference_component_source
  []
  [left_reference_component_flux_x]
    type = ADSideIntegralMaterialProperty
    boundary = left
    property = reference_component_flux
    component = 0
  []
  [right_reference_component_flux_x]
    type = ADSideIntegralMaterialProperty
    boundary = right
    property = reference_component_flux
    component = 0
  []
  [net_outward_reference_component_flux]
    type = LinearCombinationPostprocessor
    pp_names = 'right_reference_component_flux_x left_reference_component_flux_x'
    pp_coefs = '1 -1'
  []
  [direct_reference_component_balance]
    type = LinearCombinationPostprocessor
    pp_names = 'net_outward_reference_component_flux reference_component_source_integral'
    pp_coefs = '1 -1'
  []
[]

!include ../../../input/includes/executioner/transient_newton.i
!include ../../../input/includes/outputs/csv.i
!include ../../../input/includes/common/solver_defaults.i
