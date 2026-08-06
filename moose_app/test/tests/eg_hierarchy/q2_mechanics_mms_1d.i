!include ../../../input/includes/common/solver_defaults.i
!include ../../../input/includes/common/solid_effective_defaults.i

mesh_nx := 8
all_boundaries = 'left right'
solid_shear_modulus := 3.0
solid_lame_lambda := 5.0

!include ../../../input/includes/mesh/generated_1d_q2.i
!include ../../../input/includes/fields/solid_q2_1d.i

[Functions]
  [ux_exact]
    type = ParsedFunction
    expression = '0.02*sin(pi*x)'
  []
  [body_x]
    type = ParsedFunction
    expression = '-((-0.02*pi*pi*sin(pi*x))*(3.0*(1+1/(1+0.02*pi*cos(pi*x))^2)+5.0*(1-log(1+0.02*pi*cos(pi*x)))/(1+0.02*pi*cos(pi*x))^2))'
  []
[]

[ICs]
  [ux_ic]
    type = FunctionIC
    variable = ux
    function = ux_exact
  []
[]

!include ../../../input/includes/materials/solid_kinematics_1d.i
!include ../../../input/includes/materials/solid_stress_effective.i
!include ../../../input/includes/operators/solid_momentum_1d.i

[Postprocessors]
  [ux_l2]
    type = ElementL2Error
    variable = ux
    function = ux_exact
    execute_on = TIMESTEP_END
  []
  [ux_h1_semi]
    type = ElementH1SemiError
    variable = ux
    function = ux_exact
    execute_on = TIMESTEP_END
  []
[]

!include ../../../input/includes/executioner/transient_newton.i
!include ../../../input/includes/outputs/csv.i
