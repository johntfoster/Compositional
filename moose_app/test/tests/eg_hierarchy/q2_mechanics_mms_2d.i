!include ../../../input/includes/common/solver_defaults.i
!include ../../../input/includes/common/solid_effective_defaults.i

mesh_nx := 4
mesh_ny := 4
all_boundaries = 'left right bottom top'
solid_shear_modulus := 4.0
solid_lame_lambda := 6.0

!include ../../../input/includes/mesh/generated_2d_q2.i
!include ../../../input/includes/fields/solid_q2_2d.i

[Functions]
  [ux_exact]
    type = ParsedFunction
    expression = '0.015*sin(pi*x)'
  []
  [uy_exact]
    type = ParsedFunction
    expression = '0.012*sin(pi*y)'
  []
  [body_x]
    type = ParsedFunction
    expression = '-((-0.015*pi*pi*sin(pi*x))*(4.0*(1+1/(1+0.015*pi*cos(pi*x))^2)+6.0*(1-log((1+0.015*pi*cos(pi*x))*(1+0.012*pi*cos(pi*y))))/(1+0.015*pi*cos(pi*x))^2))'
  []
  [body_y]
    type = ParsedFunction
    expression = '-((-0.012*pi*pi*sin(pi*y))*(4.0*(1+1/(1+0.012*pi*cos(pi*y))^2)+6.0*(1-log((1+0.015*pi*cos(pi*x))*(1+0.012*pi*cos(pi*y))))/(1+0.012*pi*cos(pi*y))^2))'
  []
[]

[ICs]
  [ux_ic]
    type = FunctionIC
    variable = ux
    function = ux_exact
  []
  [uy_ic]
    type = FunctionIC
    variable = uy
    function = uy_exact
  []
[]

!include ../../../input/includes/materials/solid_kinematics_2d.i
!include ../../../input/includes/materials/solid_stress_effective.i
!include ../../../input/includes/operators/solid_momentum_2d.i

[Postprocessors]
  [ux_l2]
    type = ElementL2Error
    variable = ux
    function = ux_exact
    execute_on = TIMESTEP_END
  []
  [uy_l2]
    type = ElementL2Error
    variable = uy
    function = uy_exact
    execute_on = TIMESTEP_END
  []
  [ux_h1_semi]
    type = ElementH1SemiError
    variable = ux
    function = ux_exact
    execute_on = TIMESTEP_END
  []
  [uy_h1_semi]
    type = ElementH1SemiError
    variable = uy
    function = uy_exact
    execute_on = TIMESTEP_END
  []
[]

!include ../../../input/includes/executioner/transient_newton.i
!include ../../../input/includes/outputs/csv.i
