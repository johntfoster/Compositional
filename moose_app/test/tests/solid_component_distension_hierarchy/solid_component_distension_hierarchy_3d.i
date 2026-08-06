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
  []
  [rho_bar]
  []
  [solid_storage]
  []
  [ux]
    order = SECOND
  []
  [uy]
    order = SECOND
  []
  [uz]
    order = SECOND
  []
[]

[Functions]
  [rho_exact]
    type = ParsedFunction
    expression = '2+0.1*t'
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
  [J_exact]
    type = ParsedFunction
    expression = '(1+0.1*t)*(1-0.04*t)*(1+0.03*t)'
  []
  [a_exact]
    type = ParsedFunction
    expression = '(1+0.1*t)*(1-0.04*t)*(1+0.03*t)*(2+0.1*t)/2'
  []
  [storage_exact]
    type = ParsedFunction
    expression = '0.7+0.03*t'
  []
  [solid_fraction_exact]
    type = ParsedFunction
    expression = '(0.7+0.03*t)/((1+0.1*t)*(1-0.04*t)*(1+0.03*t)*(2+0.1*t))'
  []
  [source_exact]
    type = ParsedFunction
    expression = '0.03/((1+0.1*t)*(1-0.04*t)*(1+0.03*t))'
  []
  [distension_time_forcing]
    type = ParsedFunction
    expression = '(((1+0.1*t)*(1-0.04*t)*(1+0.03*t)*(2+0.1*t)-(1+0.1*(t-0.1))*(1-0.04*(t-0.1))*(1+0.03*(t-0.1))*(2+0.1*(t-0.1)))/(0.1*(1+0.1*t)*(1-0.04*t)*(1+0.03*t)*(2+0.1*t)))-(((1+0.1*t)-(1+0.1*(t-0.1)))/(0.1*(1+0.1*t))+((1-0.04*t)-(1-0.04*(t-0.1)))/(0.1*(1-0.04*t))+((1+0.03*t)-(1+0.03*(t-0.1)))/(0.1*(1+0.03*t)))-((2+0.1*t)-(2+0.1*(t-0.1)))/(0.1*(2+0.1*t))'
  []
  [zero]
    type = ConstantFunction
    value = 0
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
  [storage_ic]
    type = FunctionIC
    variable = solid_storage
    function = storage_exact
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
  [matrix_source]
    type = ADGenericFunctionMaterial
    prop_names = matrix_current_component_source
    prop_values = source_exact
  []
  [matrix_mass_volume]
    type = ADSolidPhaseMassVolumeMaterial
    reference_component_storage = solid_storage
    solid_intrinsic_density = 2
    solid_intrinsic_density_variable = rho_bar
    solid_distension = a
    current_component_source_name = matrix_current_component_source
  []
[]

[Kernels]
  [distension]
    type = ADSolidDistensionEvolution
    variable = a
    intrinsic_density = rho_bar
    forcing = distension_time_forcing
  []
  [solid_component_balance]
    type = ADMaterialPropertyResidual
    variable = solid_storage
    property = solid_reference_component_balance_residual
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
  [storage_l2]
    type = ElementL2Error
    variable = solid_storage
    function = storage_exact
  []
  [J_l2]
    type = ADMaterialScalarL2Error
    property = solid_reference_J
    function = J_exact
  []
  [solid_fraction_l2]
    type = ADMaterialScalarL2Error
    property = solid_current_volume_fraction
    function = solid_fraction_exact
  []
  [component_balance_l2]
    type = ADMaterialScalarL2Error
    property = solid_reference_component_balance_residual
    function = zero
  []
  [distension_mass_relation_l2]
    type = ADMaterialScalarL2Error
    property = solid_distension_mass_relation_residual
    function = zero
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
