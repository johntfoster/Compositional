[Mesh]
  type = GeneratedMesh
  dim = 2
  nx = 2
  ny = 2
  elem_type = QUAD9
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
  [solid_jacobian_exact]
    type = ParsedFunction
    expression = '(1+0.1*t)*(1-0.04*t)'
  []
  [distension_forcing]
    type = ParsedFunction
    expression = '0.2/(1+0.2*t)-0.1/(1+0.1*t)+0.04/(1-0.04*t)-0.5/(2+0.5*t)'
  []
  [nonpositive]
    type = ConstantFunction
    value = -1
  []
  [inverted_ux]
    type = ParsedFunction
    expression = '-2*x'
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
[]

[Materials]
  [solid_kinematics]
    type = ADSolidReferenceKinematics
    displacements = 'ux uy'
    jacobian_name = matrix_J
    jacobian_dot_name = matrix_J_dot
  []
[]

[Kernels]
  [distension]
    type = ADSolidDistensionEvolution
    variable = a
    intrinsic_density = rho_bar
    solid_jacobian_name = matrix_J
    solid_jacobian_rate_name = matrix_J_dot
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
[]

[BCs]
  [a_boundary]
    type = ADFunctionDirichletBC
    variable = a
    boundary = 'left right bottom top'
    function = a_exact
  []
  [rho_boundary]
    type = ADFunctionDirichletBC
    variable = rho_bar
    boundary = 'left right bottom top'
    function = rho_exact
  []
  [ux_boundary]
    type = ADFunctionDirichletBC
    variable = ux
    boundary = 'left right bottom top'
    function = ux_exact
  []
  [uy_boundary]
    type = ADFunctionDirichletBC
    variable = uy
    boundary = 'left right bottom top'
    function = uy_exact
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
  [solid_jacobian_l2]
    type = ADMaterialScalarL2Error
    property = matrix_J
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
