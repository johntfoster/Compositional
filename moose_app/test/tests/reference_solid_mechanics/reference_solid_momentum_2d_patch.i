mesh_nx := 2
mesh_ny := 2
solid_shear_modulus := 4
solid_lame_lambda := 6
solid_biot := 0.4

!include ../../../input/includes/mesh/generated_2d_q2.i
!include ../../../input/includes/fields/solid_q2_2d.i
!include ../../../input/includes/fields/eg_equivalent_pressure_aux.i


[Functions]
  [exact_ux]
    type = ParsedFunction
    expression = '0.02*x + 0.01*y'
  []
  [exact_uy]
    type = ParsedFunction
    expression = '-0.015*x + 0.03*y'
  []
  [pressure_exact]
    type = ParsedFunction
    expression = '1.5'
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

!include ../../../input/includes/materials/solid_kinematics_2d.i
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
[]

[BCs]
  [ux_bc]
    type = FunctionDirichletBC
    variable = ux
    boundary = 'left right bottom top'
    function = exact_ux
  []
  [uy_bc]
    type = FunctionDirichletBC
    variable = uy
    boundary = 'left right bottom top'
    function = exact_uy
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
[]

!include ../../../input/includes/executioner/steady_newton.i
!include ../../../input/includes/outputs/csv.i
