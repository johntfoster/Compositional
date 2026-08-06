mesh_nx := 4
mesh_ny := 4
mesh_nz := 4
solid_shear_modulus := 5
solid_lame_lambda := 7
solid_biot := 0.35

!include ../../../input/includes/mesh/generated_3d_q2.i
!include ../../../input/includes/fields/solid_q2_3d.i
!include ../../../input/includes/fields/eg_equivalent_pressure_aux.i


[Functions]
  [exact_ux]
    type = ParsedFunction
    expression = '0.03*x*(1-x)'
  []
  [exact_uy]
    type = ParsedFunction
    expression = '0.025*y*(1-y)'
  []
  [exact_uz]
    type = ParsedFunction
    expression = '0.02*z*(1-z)'
  []
  [pressure_exact]
    type = ParsedFunction
    expression = '1+0.2*x+0.1*y+0.05*z'
  []
  [body_x]
    type = ParsedFunction
    expression = '-(5*(-0.06+(-0.06)/(1+0.03*(1-2*x))^2)+7*(-0.06)*(1-log((1+0.03*(1-2*x))*(1+0.025*(1-2*y))*(1+0.02*(1-2*z))))/(1+0.03*(1-2*x))^2-0.35*0.2*(1+0.025*(1-2*y))*(1+0.02*(1-2*z)))'
  []
  [body_y]
    type = ParsedFunction
    expression = '-(5*(-0.05+(-0.05)/(1+0.025*(1-2*y))^2)+7*(-0.05)*(1-log((1+0.03*(1-2*x))*(1+0.025*(1-2*y))*(1+0.02*(1-2*z))))/(1+0.025*(1-2*y))^2-0.35*0.1*(1+0.03*(1-2*x))*(1+0.02*(1-2*z)))'
  []
  [body_z]
    type = ParsedFunction
    expression = '-(5*(-0.04+(-0.04)/(1+0.02*(1-2*z))^2)+7*(-0.04)*(1-log((1+0.03*(1-2*x))*(1+0.025*(1-2*y))*(1+0.02*(1-2*z))))/(1+0.02*(1-2*z))^2-0.35*0.05*(1+0.03*(1-2*x))*(1+0.025*(1-2*y)))'
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
    reference_body_force = body_x
  []
  [solid_y]
    type = ADReferenceSolidMomentum
    variable = uy
    component = 1
    reference_body_force = body_y
  []
  [solid_z]
    type = ADReferenceSolidMomentum
    variable = uz
    component = 2
    reference_body_force = body_z
  []
[]

[BCs]
  [ux_bc]
    type = FunctionDirichletBC
    variable = ux
    boundary = 'left right bottom top back front'
    function = exact_ux
  []
  [uy_bc]
    type = FunctionDirichletBC
    variable = uy
    boundary = 'left right bottom top back front'
    function = exact_uy
  []
  [uz_bc]
    type = FunctionDirichletBC
    variable = uz
    boundary = 'left right bottom top back front'
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
