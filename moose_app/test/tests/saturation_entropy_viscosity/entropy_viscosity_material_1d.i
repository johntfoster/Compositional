[Mesh]
  type = GeneratedMesh
  dim = 1
  nx = 2
[]

[Variables]
  [saturation_backbone]
    family = LAGRANGE
    order = FIRST
  []
  [saturation_enrichment]
    family = MONOMIAL
    order = CONSTANT
  []
[]

[Functions]
  [saturation_exact]
    type = ParsedFunction
    expression = '0.25+0.5*x'
  []
  [entropy_residual_exact]
    type = ParsedFunction
    expression = '3'
  []
  [full_entropy_residual_exact]
    type = ParsedFunction
    expression = '(0.25+0.5*x)^2+2.25*(0.25+0.5*x)'
  []
  [stabilization_viscosity_exact]
    type = ParsedFunction
    expression = '0.075'
  []
  [stabilization_flux_potential]
    type = ParsedFunction
    expression = '-0.15*x'
  []
  [mobility_exact]
    type = ParsedFunction
    expression = '0.3'
  []
  [zero]
    type = ParsedFunction
    expression = '0'
  []
[]

[ICs]
  [saturation_backbone_ic]
    type = FunctionIC
    variable = saturation_backbone
    function = saturation_exact
  []
[]

[Materials]
  [saturation_reconstruction]
    type = ADEGReconstructedScalarMaterial
    backbone = saturation_backbone
    enrichment = saturation_enrichment
    field_name = saturation
  []
  [constants]
    type = ADGenericConstantMaterial
    prop_names = 'supplied_entropy_residual entropy_storage_coefficient entropy_storage_coefficient_rate entropy_source_1 entropy_source_2'
    prop_values = '3 3 2 0.5 0.25'
  []
  [velocity]
    type = ADGenericConstantVectorMaterial
    prop_names = 'saturation_transport_velocity'
    prop_values = '2 0 0'
  []
  [entropy_viscosity]
    type = ADEntropyViscosityReferenceFluxMaterial
    scalar_name = saturation_total
    scalar_gradient_name = saturation_total_gradient
    scalar_dot_name = saturation_total_dot
    transport_velocity_name = saturation_transport_velocity
    entropy_residual_name = supplied_entropy_residual
    mass_coefficient = 4
    entropy = power
    power = 2
    lambda_linear = 0.1
    lambda_entropy = 0.2
    entropy_deviation_norm = 2
    regularization = 1e-14
    property_prefix = saturation_ev
  []
  [full_storage_source_entropy_viscosity]
    type = ADEntropyViscosityReferenceFluxMaterial
    scalar_name = saturation_total
    scalar_gradient_name = saturation_total_gradient
    scalar_dot_name = saturation_total_dot
    transport_velocity_name = saturation_transport_velocity
    entropy_storage_coefficient_name = entropy_storage_coefficient
    entropy_storage_coefficient_rate_name = entropy_storage_coefficient_rate
    source_names = 'entropy_source_1 entropy_source_2'
    entropy = power
    power = 2
    lambda_linear = 0.1
    lambda_entropy = 0.2
    entropy_deviation_norm = 2
    regularization = 1e-14
    property_prefix = full_storage_source_ev
  []
[]

[Kernels]
  [coverage]
    type = ADReaction
    variable = saturation_backbone
    rate = 0
  []
  [enrichment_coverage]
    type = ADReaction
    variable = saturation_enrichment
    rate = 0
  []
[]

[Postprocessors]
  [entropy_residual_l2]
    type = ADMaterialScalarL2Error
    property = saturation_ev_entropy_residual
    function = entropy_residual_exact
    execute_on = INITIAL
  []
  [full_storage_source_entropy_residual_l2]
    type = ADMaterialScalarL2Error
    property = full_storage_source_ev_entropy_residual
    function = full_entropy_residual_exact
    execute_on = INITIAL
  []
  [stabilization_viscosity_l2]
    type = ADMaterialScalarL2Error
    property = saturation_ev_stabilization_viscosity
    function = stabilization_viscosity_exact
    execute_on = INITIAL
  []
  [stabilization_flux_l2]
    type = ADMaterialVectorL2Error
    property = saturation_ev_reference_flux
    gradient_function = stabilization_flux_potential
    execute_on = INITIAL
  []
  [mobility_xx_l2]
    type = ADMaterialRankTwoComponentL2Error
    property = saturation_ev_mobility
    row = 0
    column = 0
    function = mobility_exact
    execute_on = INITIAL
  []
  [mobility_xy_l2]
    type = ADMaterialRankTwoComponentL2Error
    property = saturation_ev_mobility
    row = 0
    column = 1
    function = zero
    execute_on = INITIAL
  []
[]

[Problem]
  solve = false
[]

[Executioner]
  type = Steady
[]

[Outputs]
  csv = true
  execute_on = INITIAL
[]
