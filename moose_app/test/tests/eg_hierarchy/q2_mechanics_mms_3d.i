!include ../../../input/includes/common/solver_defaults.i
!include ../../../input/includes/common/solid_effective_defaults.i

mesh_nx := 1
mesh_ny := 1
mesh_nz := 1
all_boundaries = 'left right bottom top back front'
solid_shear_modulus := 5.0
solid_lame_lambda := 7.0

!include ../../../input/includes/mesh/generated_3d_q2.i
!include ../../../input/includes/fields/solid_q2_3d.i

[Functions]
  [ux_exact]
    type = ParsedFunction
    expression = '0.012*sin(pi*x)'
  []
  [uy_exact]
    type = ParsedFunction
    expression = '0.010*sin(pi*y)'
  []
  [uz_exact]
    type = ParsedFunction
    expression = '0.008*sin(pi*z)'
  []
  [body_x]
    type = ParsedFunction
    expression = '-((-0.012*pi*pi*sin(pi*x))*(5.0*(1+1/(1+0.012*pi*cos(pi*x))^2)+7.0*(1-log((1+0.012*pi*cos(pi*x))*(1+0.010*pi*cos(pi*y))*(1+0.008*pi*cos(pi*z))))/(1+0.012*pi*cos(pi*x))^2))'
  []
  [body_y]
    type = ParsedFunction
    expression = '-((-0.010*pi*pi*sin(pi*y))*(5.0*(1+1/(1+0.010*pi*cos(pi*y))^2)+7.0*(1-log((1+0.012*pi*cos(pi*x))*(1+0.010*pi*cos(pi*y))*(1+0.008*pi*cos(pi*z))))/(1+0.010*pi*cos(pi*y))^2))'
  []
  [body_z]
    type = ParsedFunction
    expression = '-((-0.008*pi*pi*sin(pi*z))*(5.0*(1+1/(1+0.008*pi*cos(pi*z))^2)+7.0*(1-log((1+0.012*pi*cos(pi*x))*(1+0.010*pi*cos(pi*y))*(1+0.008*pi*cos(pi*z))))/(1+0.008*pi*cos(pi*z))^2))'
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
  [uz_ic]
    type = FunctionIC
    variable = uz
    function = uz_exact
  []
[]

!include ../../../input/includes/materials/solid_kinematics_3d.i
!include ../../../input/includes/materials/solid_stress_effective.i
!include ../../../input/includes/operators/solid_momentum_3d.i

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
  [uz_l2]
    type = ElementL2Error
    variable = uz
    function = uz_exact
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
  [uz_h1_semi]
    type = ElementH1SemiError
    variable = uz
    function = uz_exact
    execute_on = TIMESTEP_END
  []
[]

!include ../../../input/includes/executioner/transient_newton.i
!include ../../../input/includes/outputs/csv.i
