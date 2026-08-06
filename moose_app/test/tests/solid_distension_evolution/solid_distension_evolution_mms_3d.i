[Mesh]
  type = GeneratedMesh
  dim = 3
  nx = 2
  ny = 2
  nz = 2
  elem_type = TET10
[]

[Variables]
  [a]
    family = LAGRANGE
    order = FIRST
  []
  [rho_bar]
    family = LAGRANGE
    order = FIRST
  []
  [ux]
    family = LAGRANGE
    order = SECOND
  []
  [uy]
    family = LAGRANGE
    order = SECOND
  []
  [uz]
    family = LAGRANGE
    order = SECOND
  []
[]

[Functions]
  [a_exact]
    type = ParsedFunction
    expression = '1+0.2*t'
  []
  [rho_exact]
    type = ParsedFunction
    expression = '2+0.5*t'
  []
  [ux_exact]
    type = ParsedFunction
    expression = '0.1*t*x'
  []
  [uy_exact]
    type = ParsedFunction
    expression = '-0.04*t*y'
  []
  [uz_exact]
    type = ParsedFunction
    expression = '0.03*t*z'
  []
  [solid_jacobian_exact]
    type = ParsedFunction
    expression = '(1+0.1*t)*(1-0.04*t)*(1+0.03*t)'
  []
  [distension_forcing]
    type = ParsedFunction
    expression = '0.2/(1+0.2*t)-0.1/(1+0.1*t)+0.04/(1-0.04*t)-0.03/(1+0.03*t)-0.5/(2+0.5*t)'
  []
[]

[ICs]
  [a_ic]
    type = FunctionIC
    variable = a
    function = a_exact
  []
  [rho_ic]
    type = FunctionIC
    variable = rho_bar
    function = rho_exact
  []
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

[Materials]
  [solid_kinematics]
    type = ADSolidReferenceKinematics
    displacements = 'ux uy uz'
  []
[]

[Kernels]
  [distension]
    type = ADSolidDistensionEvolution
    variable = a
    intrinsic_density = rho_bar
    forcing = distension_forcing
  []
  [rho_reaction]
    type = ADReaction
    variable = rho_bar
  []
  [rho_target]
    type = ADBodyForce
    variable = rho_bar
    function = rho_exact
  []
  [ux_reaction]
    type = ADReaction
    variable = ux
  []
  [ux_target]
    type = ADBodyForce
    variable = ux
    function = ux_exact
  []
  [uy_reaction]
    type = ADReaction
    variable = uy
  []
  [uy_target]
    type = ADBodyForce
    variable = uy
    function = uy_exact
  []
  [uz_reaction]
    type = ADReaction
    variable = uz
  []
  [uz_target]
    type = ADBodyForce
    variable = uz
    function = uz_exact
  []
[]

[BCs]
  [a_boundary]
    type = ADFunctionDirichletBC
    variable = a
    boundary = 'left right bottom top front back'
    function = a_exact
  []
  [rho_boundary]
    type = ADFunctionDirichletBC
    variable = rho_bar
    boundary = 'left right bottom top front back'
    function = rho_exact
  []
  [ux_boundary]
    type = ADFunctionDirichletBC
    variable = ux
    boundary = 'left right bottom top front back'
    function = ux_exact
  []
  [uy_boundary]
    type = ADFunctionDirichletBC
    variable = uy
    boundary = 'left right bottom top front back'
    function = uy_exact
  []
  [uz_boundary]
    type = ADFunctionDirichletBC
    variable = uz
    boundary = 'left right bottom top front back'
    function = uz_exact
  []
[]

[Postprocessors]
  [a_l2]
    type = ElementL2Error
    variable = a
    function = a_exact
  []
  [rho_l2]
    type = ElementL2Error
    variable = rho_bar
    function = rho_exact
  []
  [ux_l2]
    type = ElementL2Error
    variable = ux
    function = ux_exact
  []
  [uy_l2]
    type = ElementL2Error
    variable = uy
    function = uy_exact
  []
  [uz_l2]
    type = ElementL2Error
    variable = uz
    function = uz_exact
  []
  [solid_jacobian_l2]
    type = ADMaterialScalarL2Error
    property = solid_reference_J
    function = solid_jacobian_exact
  []
[]

[Executioner]
  type = Transient
  solve_type = NEWTON
  scheme = implicit-euler
  dt = 0.1
  end_time = 0.2
  nl_abs_tol = 1e-12
  nl_rel_tol = 1e-12
[]

[Outputs]
  csv = true
[]
