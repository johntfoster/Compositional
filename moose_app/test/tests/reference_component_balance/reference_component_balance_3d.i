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
  [uz_ic]
    type = FunctionIC
    variable = uz
    function = zero
  []
[]

[Functions]
  [exact_storage]
    type = ParsedFunction
    expression = 'sin(pi*x)*sin(pi*y)*sin(pi*z)'
  []
  [source]
    type = ParsedFunction
    expression = '3*pi*pi*sin(pi*x)*sin(pi*y)*sin(pi*z)'
  []
  [component_extra_flux]
    type = ParsedVectorFunction
    expression_x = '-pi*cos(pi*x)*sin(pi*y)*sin(pi*z)'
    expression_y = '-pi*sin(pi*x)*cos(pi*y)*sin(pi*z)'
    expression_z = '-pi*sin(pi*x)*sin(pi*y)*cos(pi*z)'
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

!include ../../../input/includes/materials/solid_kinematics_3d.i

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
    boundary = 'left right bottom top back front'
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
