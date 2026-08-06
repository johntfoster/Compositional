[Mesh]
  type = GeneratedMesh
  dim = 1
  nx = 2
  elem_type = EDGE2
[]

[Variables]
  [theta_f]
    family = LAGRANGE
    order = FIRST
  []
  [theta_s]
    family = LAGRANGE
    order = FIRST
  []
  [theta_f_enrichment]
    family = MONOMIAL
    order = CONSTANT
  []
  [theta_s_enrichment]
    family = MONOMIAL
    order = CONSTANT
  []
[]

[ICs]
  [theta_f]
    type = ConstantIC
    variable = theta_f
    value = 295
  []
  [theta_s]
    type = ConstantIC
    variable = theta_s
    value = 325
  []
  [theta_f_enrichment]
    type = ConstantIC
    variable = theta_f_enrichment
    value = 0.5
  []
  [theta_s_enrichment]
    type = ConstantIC
    variable = theta_s_enrichment
    value = -0.5
  []
[]

[BCs]
  [theta_f_left]
    type = ADDirichletBC
    variable = theta_f
    boundary = left
    value = 300
  []
  [theta_f_right]
    type = ADDirichletBC
    variable = theta_f
    boundary = right
    value = 300
  []
  [theta_s_left]
    type = ADDirichletBC
    variable = theta_s
    boundary = left
    value = 330
  []
  [theta_s_right]
    type = ADDirichletBC
    variable = theta_s
    boundary = right
    value = 330
  []
[]

[Functions]
  [theta_f_exact]
    type = ConstantFunction
    value = 300
  []
  [theta_s_exact]
    type = ConstantFunction
    value = 330
  []
  [zero]
    type = ConstantFunction
    value = 0
  []
  [fluid_source_exact]
    type = ConstantFunction
    value = 120
  []
  [solid_source_exact]
    type = ConstantFunction
    value = -120
  []
[]

[Materials]
  [theta_f_reconstruction]
    type = ADEGReconstructedScalarMaterial
    backbone = theta_f
    enrichment = theta_f_enrichment
    field_name = theta_f
  []
  [theta_s_reconstruction]
    type = ADEGReconstructedScalarMaterial
    backbone = theta_s
    enrichment = theta_s_enrichment
    field_name = theta_s
  []
  [heat_transfer_coefficient]
    type = ADParsedMaterial
    property_name = h_fs
    material_property_names = theta_f_total
    expression = '1+0.01*theta_f_total'
  []
  [heat_exchange]
    type = ADInterSubsystemHeatExchangeMaterial
    fluid_temperature_name = theta_f_total
    solid_temperature_name = theta_s_total
    heat_transfer_coefficient_name = h_fs
    fluid_heat_source_name = fluid_exchange_source
    solid_heat_source_name = solid_exchange_source
    exchange_cancellation_name = exchange_cancellation
    entropy_production_name = exchange_entropy_production
  []
  [reference_jacobian]
    type = ADGenericConstantMaterial
    prop_names = solid_reference_J
    prop_values = 1
  []
  [theta_f_restoring_residual]
    type = ADParsedMaterial
    property_name = theta_f_restoring_residual
    material_property_names = theta_f_total
    expression = '10*(theta_f_total-300)+120'
  []
  [theta_s_restoring_residual]
    type = ADParsedMaterial
    property_name = theta_s_restoring_residual
    material_property_names = theta_s_total
    expression = '10*(theta_s_total-330)-120'
  []
  [theta_f_enrichment_residual]
    type = ADParsedMaterial
    property_name = theta_f_enrichment_residual
    coupled_variables = theta_f_enrichment
    expression = theta_f_enrichment
  []
  [theta_s_enrichment_residual]
    type = ADParsedMaterial
    property_name = theta_s_enrichment_residual
    coupled_variables = theta_s_enrichment
    expression = theta_s_enrichment
  []
[]

[Kernels]
  [theta_f_restoring]
    type = ADMaterialPropertyResidual
    variable = theta_f
    property = theta_f_restoring_residual
  []
  [theta_f_exchange]
    type = ADReferenceEnergySourceTerm
    variable = theta_f
    source_name = fluid_exchange_source
    multiply_by_jacobian = true
    solid_jacobian_name = solid_reference_J
  []
  [theta_s_restoring]
    type = ADMaterialPropertyResidual
    variable = theta_s
    property = theta_s_restoring_residual
  []
  [theta_s_exchange]
    type = ADReferenceEnergySourceTerm
    variable = theta_s
    source_name = solid_exchange_source
    multiply_by_jacobian = true
    solid_jacobian_name = solid_reference_J
  []
  [theta_f_enrichment_equation]
    type = ADMaterialPropertyResidual
    variable = theta_f_enrichment
    property = theta_f_enrichment_residual
  []
  [theta_s_enrichment_equation]
    type = ADMaterialPropertyResidual
    variable = theta_s_enrichment
    property = theta_s_enrichment_residual
  []
[]

[Postprocessors]
  [theta_f_l2]
    type = ElementL2Error
    variable = theta_f
    function = theta_f_exact
  []
  [theta_s_l2]
    type = ElementL2Error
    variable = theta_s
    function = theta_s_exact
  []
  [theta_f_enrichment_l2]
    type = ElementL2Error
    variable = theta_f_enrichment
    function = zero
  []
  [theta_s_enrichment_l2]
    type = ElementL2Error
    variable = theta_s_enrichment
    function = zero
  []
  [fluid_source_l2]
    type = ADMaterialScalarL2Error
    property = fluid_exchange_source
    function = fluid_source_exact
  []
  [solid_source_l2]
    type = ADMaterialScalarL2Error
    property = solid_exchange_source
    function = solid_source_exact
  []
  [cancellation_l2]
    type = ADMaterialScalarL2Error
    property = exchange_cancellation
    function = zero
  []
[]

[Executioner]
  type = Steady
  solve_type = NEWTON
  nl_abs_tol = 1e-13
  nl_rel_tol = 1e-13
[]

[Outputs]
  csv = true
[]
