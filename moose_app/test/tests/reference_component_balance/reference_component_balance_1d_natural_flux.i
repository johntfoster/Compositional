mesh_nx := 8
solve_dt := 1
solve_steps := 1

!include ../../../input/includes/mesh/generated_1d_q2.i
!include ../../../input/includes/fields/solid_q2_aux_1d.i

[Variables]
  [component_storage]
  []
[]

[ICs]
  [component_storage_ic]
    type = FunctionIC
    variable = component_storage
    function = exact_storage
  []
  [ux_ic]
    type = FunctionIC
    variable = ux
    function = zero
  []
[]

[Functions]
  [exact_storage]
    type = ParsedFunction
    expression = 'sin(pi*x)'
  []
  [source]
    type = ParsedFunction
    expression = 'pi*pi*sin(pi*x)'
  []
  [current_relative_mass_flux]
    type = ParsedVectorFunction
    expression_x = '-pi*cos(pi*x)'
    expression_y = '0'
    expression_z = '0'
  []
  [zero_vector]
    type = ParsedVectorFunction
    expression_x = '0'
    expression_y = '0'
    expression_z = '0'
  []
  [outward_reference_phase_flux]
    type = ParsedFunction
    expression = 'pi'
  []
  [zero]
    type = ParsedFunction
    expression = '0'
  []
  [one]
    type = ParsedFunction
    expression = '1'
  []
[]

!include ../../../input/includes/materials/solid_kinematics_1d.i

[Materials]
  [component]
    type = ADReferenceFluidComponentMaterial
    current_relative_mass_flux = current_relative_mass_flux
    current_component_extra_flux = zero_vector
    current_component_source = source
    component_mass_fraction = one
  []
[]

[Kernels]
  [component_balance]
    type = ADReferenceFluidComponentBalance
    variable = component_storage
  []
[]

[BCs]
  [natural_flux]
    type = ADReferenceFluidComponentFluxBC
    variable = component_storage
    boundary = 'left right'
    outward_reference_phase_flux = outward_reference_phase_flux
    component_mass_fraction = one
  []
[]

[Postprocessors]
  [component_l2]
    type = ElementL2Error
    variable = component_storage
    function = exact_storage
  []
[]

!include ../../../input/includes/executioner/transient_newton.i
!include ../../../input/includes/outputs/csv.i
