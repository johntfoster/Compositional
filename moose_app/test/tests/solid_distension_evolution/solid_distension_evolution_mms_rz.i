[Mesh]
  coord_type = RZ
  [annulus]
    type = GeneratedMeshGenerator
    dim = 2
    nx = 2
    ny = 2
    xmin = 1
    xmax = 2
    ymin = 0
    ymax = 1
    elem_type = QUAD9
  []
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
  [ur]
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
  [ur_exact]
    type = ParsedFunction
    expression = '0.1*t*x'
  []
  [uz_exact]
    type = ParsedFunction
    expression = '-0.05*t*y'
  []
  [solid_jacobian_exact]
    type = ParsedFunction
    expression = '(1+0.1*t)^2*(1-0.05*t)'
  []
  [distension_forcing]
    type = ParsedFunction
    expression = '0.2/(1+0.2*t)-0.2/(1+0.1*t)+0.05/(1-0.05*t)-0.5/(2+0.5*t)'
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
  [ur_ic]
    type = FunctionIC
    variable = ur
    function = ur_exact
  []
  [uz_ic]
    type = FunctionIC
    variable = uz
    function = uz_exact
  []
[]

[Materials]
  [solid_kinematics]
    type = ADAxisymmetricSolidReferenceKinematics
    radial_displacement = ur
    axial_displacement = uz
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
  [ur_reaction]
    type = ADReaction
    variable = ur
  []
  [ur_target]
    type = ADBodyForce
    variable = ur
    function = ur_exact
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
    boundary = 'left right bottom top'
    function = a_exact
  []
  [rho_boundary]
    type = ADFunctionDirichletBC
    variable = rho_bar
    boundary = 'left right bottom top'
    function = rho_exact
  []
  [ur_boundary]
    type = ADFunctionDirichletBC
    variable = ur
    boundary = 'left right bottom top'
    function = ur_exact
  []
  [uz_boundary]
    type = ADFunctionDirichletBC
    variable = uz
    boundary = 'left right bottom top'
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
  [ur_l2]
    type = ElementL2Error
    variable = ur
    function = ur_exact
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
