mesh_nx := 6
mesh_ny := 6
solve_dt := 1
solve_steps := 1

!include ../../../input/includes/mesh/generated_2d_q2.i
!include ../../../input/includes/fields/solid_q2_aux_2d.i

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
  [uy_ic]
    type = FunctionIC
    variable = uy
    function = zero
  []
[]

[Functions]
  [exact_storage]
    type = ParsedFunction
    expression = 'sin(pi*x)*sin(pi*y)'
  []
  [source]
    type = ParsedFunction
    expression = '2*pi*pi*sin(pi*x)*sin(pi*y)'
  []
  [component_extra_flux]
    type = ParsedVectorFunction
    expression_x = '-pi*cos(pi*x)*sin(pi*y)'
    expression_y = '-pi*sin(pi*x)*cos(pi*y)'
    expression_z = '0'
  []
  [zero_vector]
    type = ParsedVectorFunction
    expression_x = '0'
    expression_y = '0'
    expression_z = '0'
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

!include ../../../input/includes/materials/solid_kinematics_2d.i

[Materials]
  [component]
    type = ADReferenceFluidComponentMaterial
    current_relative_mass_flux = zero_vector
    current_component_extra_flux = component_extra_flux
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
  [exact]
    type = FunctionDirichletBC
    variable = component_storage
    boundary = 'left right bottom top'
    function = exact_storage
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
