[Mesh]
  type = GeneratedMesh
  dim = 1
  nx = 4
  elem_type = EDGE3
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
[]

[AuxVariables]
  [a_lower_bound]
    family = MONOMIAL
    order = CONSTANT
  []
  [rho_lower_bound]
    family = MONOMIAL
    order = CONSTANT
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
  [solid_jacobian_exact]
    type = ParsedFunction
    expression = '1+0.1*t'
  []
  [distension_forcing]
    type = ParsedFunction
    expression = '0.2/(1+0.2*t)-0.1/(1+0.1*t)-0.5/(2+0.5*t)'
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
[]

[Materials]
  [solid_kinematics]
    type = ADSolidReferenceKinematics
    displacements = ux
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
[]

[Bounds]
  [a_positive]
    type = CoefficientBounds
    variable = a_lower_bound
    bounded_variable = a
    bound_type = lower
    bound_value = 1e-8
  []
  [rho_positive]
    type = CoefficientBounds
    variable = rho_lower_bound
    bounded_variable = rho_bar
    bound_type = lower
    bound_value = 1e-8
  []
[]

[BCs]
  [a_boundary]
    type = ADFunctionDirichletBC
    variable = a
    boundary = 'left right'
    function = a_exact
  []
  [rho_boundary]
    type = ADFunctionDirichletBC
    variable = rho_bar
    boundary = 'left right'
    function = rho_exact
  []
  [ux_boundary]
    type = ADFunctionDirichletBC
    variable = ux
    boundary = 'left right'
    function = ux_exact
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
  petsc_options_iname = '-snes_type'
  petsc_options_value = 'vinewtonrsls'
[]

[Outputs]
  csv = true
[]
