mesh_nx := 2
mesh_ny := 2
mesh_nz := 2
solid_shear_modulus := 5
solid_lame_lambda := 7
solid_biot := 0.2

!include ../../../input/includes/mesh/generated_3d_q2.i
!include ../../../input/includes/fields/solid_q2_3d.i
!include ../../../input/includes/fields/eg_equivalent_pressure_aux.i


[Functions]
  [exact_ux]
    type = ParsedFunction
    expression = '0.01*x + 0.02*y'
  []
  [exact_uy]
    type = ParsedFunction
    expression = '-0.01*x + 0.015*y + 0.005*z'
  []
  [exact_uz]
    type = ParsedFunction
    expression = '0.02*z'
  []
  [pressure_exact]
    type = ParsedFunction
    expression = '0.75'
  []
[]

[ICs]
  [ux_ic]
    type = FunctionIC
    variable = ux
    function = exact_ux
  []
  [uy_ic]
    type = FunctionIC
    variable = uy
    function = exact_uy
  []
  [uz_ic]
    type = FunctionIC
    variable = uz
    function = exact_uz
  []
  [pressure_ic]
    type = FunctionIC
    variable = equivalent_pressure
    function = pressure_exact
  []
  [pressure_enr_ic]
    type = ConstantIC
    variable = equivalent_pressure_enr
    value = 0
  []
[]

!include ../../../input/includes/materials/solid_kinematics_3d.i
!include ../../../input/includes/materials/eg_equivalent_pressure_reconstruction.i
!include ../../../input/includes/materials/solid_stress_eg_equivalent_pressure.i

[Kernels]
  [solid_x]
    type = ADReferenceSolidMomentum
    variable = ux
    component = 0
  []
  [solid_y]
    type = ADReferenceSolidMomentum
    variable = uy
    component = 1
  []
  [solid_z]
    type = ADReferenceSolidMomentum
    variable = uz
    component = 2
  []
[]

[BCs]
  [ux_bc]
    type = FunctionDirichletBC
    variable = ux
    boundary = 'left right bottom top front back'
    function = exact_ux
  []
  [uy_bc]
    type = FunctionDirichletBC
    variable = uy
    boundary = 'left right bottom top front back'
    function = exact_uy
  []
  [uz_bc]
    type = FunctionDirichletBC
    variable = uz
    boundary = 'left right bottom top front back'
    function = exact_uz
  []
[]

[Postprocessors]
  [ux_l2]
    type = ElementL2Error
    variable = ux
    function = exact_ux
  []
  [uy_l2]
    type = ElementL2Error
    variable = uy
    function = exact_uy
  []
  [uz_l2]
    type = ElementL2Error
    variable = uz
    function = exact_uz
  []
[]

!include ../../../input/includes/executioner/steady_newton.i
!include ../../../input/includes/outputs/csv.i
