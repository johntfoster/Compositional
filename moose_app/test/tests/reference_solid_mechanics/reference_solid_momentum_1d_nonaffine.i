mesh_nx := 16
solid_shear_modulus := 3
solid_lame_lambda := 5
solid_biot := 0.25

!include ../../../input/includes/mesh/generated_1d_q2.i
!include ../../../input/includes/fields/solid_q2_1d.i
!include ../../../input/includes/fields/eg_equivalent_pressure_aux.i


[Functions]
  [exact_ux]
    type = ParsedFunction
    expression = '0.05*x*(1-x)'
  []
  [pressure_exact]
    type = ParsedFunction
    expression = '1+0.2*x'
  []
  [body_x]
    type = ParsedFunction
    expression = '-(3*(-0.1+(-0.1)/(1+0.05*(1-2*x))^2)+5*(-0.1)*(1-log(1+0.05*(1-2*x)))/(1+0.05*(1-2*x))^2-0.25*0.2)'
  []
[]

[ICs]
  [ux_ic]
    type = FunctionIC
    variable = ux
    function = exact_ux
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

!include ../../../input/includes/materials/solid_kinematics_1d.i
!include ../../../input/includes/materials/eg_equivalent_pressure_reconstruction.i
!include ../../../input/includes/materials/solid_stress_eg_equivalent_pressure.i

[Kernels]
  [solid_x]
    type = ADReferenceSolidMomentum
    variable = ux
    component = 0
    reference_body_force = body_x
  []
[]

[BCs]
  [ux_bc]
    type = FunctionDirichletBC
    variable = ux
    boundary = 'left right'
    function = exact_ux
  []
[]

[Postprocessors]
  [ux_l2]
    type = ElementL2Error
    variable = ux
    function = exact_ux
  []
[]

!include ../../../input/includes/executioner/steady_newton.i
!include ../../../input/includes/outputs/csv.i
