mesh_nx := 2
mesh_ny := 2
mesh_nz := 2
solve_dt := 1
solve_steps := 1

!include ../../../input/includes/mesh/generated_3d_q2.i
!include ../../../input/includes/fields/solid_q2_aux_3d.i

[Variables]
  [component_storage]
  []
[]

[AuxVariables]
  [neutral_potential]
  []
  [electric_potential]
  []
  [temperature]
  []
  [transport_force_x]
    family = MONOMIAL
    order = CONSTANT
  []
  [transport_force_y]
    family = MONOMIAL
    order = CONSTANT
  []
  [transport_force_z]
    family = MONOMIAL
    order = CONSTANT
  []
  [current_flux_x]
    family = MONOMIAL
    order = CONSTANT
  []
  [current_flux_y]
    family = MONOMIAL
    order = CONSTANT
  []
  [current_flux_z]
    family = MONOMIAL
    order = CONSTANT
  []
  [reference_flux_x]
    family = MONOMIAL
    order = CONSTANT
  []
  [reference_flux_y]
    family = MONOMIAL
    order = CONSTANT
  []
  [reference_flux_z]
    family = MONOMIAL
    order = CONSTANT
  []
  [charge_flux_x]
    family = MONOMIAL
    order = CONSTANT
  []
  [charge_flux_y]
    family = MONOMIAL
    order = CONSTANT
  []
  [charge_flux_z]
    family = MONOMIAL
    order = CONSTANT
  []
  [electric_work]
    family = MONOMIAL
    order = CONSTANT
  []
[]

[Functions]
  [zero]
    type = ParsedFunction
    expression = '0'
  []
  [neutral_potential_exact]
    type = ParsedFunction
    expression = 'x+2*y+3*z'
  []
  [electric_potential_exact]
    type = ParsedFunction
    expression = '7+2*x-y+0.5*z'
  []
  [temperature_exact]
    type = ParsedFunction
    expression = 'x+2*y-3*z'
  []
  [transport_force_x_exact]
    type = ParsedFunction
    expression = '8.5'
  []
  [transport_force_y_exact]
    type = ParsedFunction
    expression = '-3'
  []
  [transport_force_z_exact]
    type = ParsedFunction
    expression = '6.5'
  []
  [current_flux_x_exact]
    type = ParsedFunction
    expression = '-0.85'
  []
  [current_flux_y_exact]
    type = ParsedFunction
    expression = '0.3'
  []
  [current_flux_z_exact]
    type = ParsedFunction
    expression = '-0.65'
  []
  [charge_flux_x_exact]
    type = ParsedFunction
    expression = '-3.4'
  []
  [charge_flux_y_exact]
    type = ParsedFunction
    expression = '1.2'
  []
  [charge_flux_z_exact]
    type = ParsedFunction
    expression = '-2.6'
  []
  [electric_work_exact]
    type = ParsedFunction
    expression = '9.3'
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
    function = zero
  []
  [uy_ic]
    type = FunctionIC
    variable = uy
    function = zero
  []
  [uz_ic]
    type = FunctionIC
    variable = uz
    function = zero
  []
  [neutral_potential_ic]
    type = FunctionIC
    variable = neutral_potential
    function = neutral_potential_exact
  []
  [electric_potential_ic]
    type = FunctionIC
    variable = electric_potential
    function = electric_potential_exact
  []
  [temperature_ic]
    type = FunctionIC
    variable = temperature
    function = temperature_exact
  []
[]

[UserObjects]
  [phases]
    type = PhaseRegistry
    phases = 'solid oil'
    reference_phase = solid
  []
[]

!include ../../../input/includes/materials/solid_kinematics_3d.i

[Materials]
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
    neutral_potential = neutral_potential
    electric_potential = electric_potential
    temperature = temperature
    mobility = 0.1
    charge_number = 4
    thermal_force_coefficient = -0.5
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
    current_component_source = zero
  []
[]

[AuxKernels]
  [transport_force_x_aux]
    type = ADMaterialRealVectorValueAux
    variable = transport_force_x
    property = component_transport_force
    component = 0
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [transport_force_y_aux]
    type = ADMaterialRealVectorValueAux
    variable = transport_force_y
    property = component_transport_force
    component = 1
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [transport_force_z_aux]
    type = ADMaterialRealVectorValueAux
    variable = transport_force_z
    property = component_transport_force
    component = 2
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [current_flux_x_aux]
    type = ADMaterialRealVectorValueAux
    variable = current_flux_x
    property = charged_current_component_flux
    component = 0
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [current_flux_y_aux]
    type = ADMaterialRealVectorValueAux
    variable = current_flux_y
    property = charged_current_component_flux
    component = 1
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [current_flux_z_aux]
    type = ADMaterialRealVectorValueAux
    variable = current_flux_z
    property = charged_current_component_flux
    component = 2
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [reference_flux_x_aux]
    type = ADMaterialRealVectorValueAux
    variable = reference_flux_x
    property = reference_component_flux
    component = 0
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [reference_flux_y_aux]
    type = ADMaterialRealVectorValueAux
    variable = reference_flux_y
    property = reference_component_flux
    component = 1
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [reference_flux_z_aux]
    type = ADMaterialRealVectorValueAux
    variable = reference_flux_z
    property = reference_component_flux
    component = 2
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [charge_flux_x_aux]
    type = ADMaterialRealVectorValueAux
    variable = charge_flux_x
    property = charged_current_charge_flux
    component = 0
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [charge_flux_y_aux]
    type = ADMaterialRealVectorValueAux
    variable = charge_flux_y
    property = charged_current_charge_flux
    component = 1
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [charge_flux_z_aux]
    type = ADMaterialRealVectorValueAux
    variable = charge_flux_z
    property = charged_current_charge_flux
    component = 2
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [electric_work_aux]
    type = ADMaterialRealAux
    variable = electric_work
    property = electric_field_work
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
    boundary = 'left right bottom top back front'
    function = zero
  []
[]

[Postprocessors]
  [component_l2]
    type = ElementL2Error
    variable = component_storage
    function = zero
  []
  [transport_force_x_l2]
    type = ElementL2Error
    variable = transport_force_x
    function = transport_force_x_exact
  []
  [transport_force_y_l2]
    type = ElementL2Error
    variable = transport_force_y
    function = transport_force_y_exact
  []
  [transport_force_z_l2]
    type = ElementL2Error
    variable = transport_force_z
    function = transport_force_z_exact
  []
  [current_flux_x_l2]
    type = ElementL2Error
    variable = current_flux_x
    function = current_flux_x_exact
  []
  [current_flux_y_l2]
    type = ElementL2Error
    variable = current_flux_y
    function = current_flux_y_exact
  []
  [current_flux_z_l2]
    type = ElementL2Error
    variable = current_flux_z
    function = current_flux_z_exact
  []
  [reference_flux_x_l2]
    type = ElementL2Error
    variable = reference_flux_x
    function = current_flux_x_exact
  []
  [reference_flux_y_l2]
    type = ElementL2Error
    variable = reference_flux_y
    function = current_flux_y_exact
  []
  [reference_flux_z_l2]
    type = ElementL2Error
    variable = reference_flux_z
    function = current_flux_z_exact
  []
  [charge_flux_x_l2]
    type = ElementL2Error
    variable = charge_flux_x
    function = charge_flux_x_exact
  []
  [charge_flux_y_l2]
    type = ElementL2Error
    variable = charge_flux_y
    function = charge_flux_y_exact
  []
  [charge_flux_z_l2]
    type = ElementL2Error
    variable = charge_flux_z
    function = charge_flux_z_exact
  []
  [electric_work_l2]
    type = ElementL2Error
    variable = electric_work
    function = electric_work_exact
  []
[]

!include ../../../input/includes/executioner/transient_newton.i
!include ../../../input/includes/outputs/csv.i
