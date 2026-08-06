mesh_nx := 2

!include ../../../input/includes/mesh/generated_1d_q2.i
!include ../../../input/includes/fields/solid_q2_aux_1d.i
!include ../../../input/includes/fields/eg_pressure_legacy.i

[Variables]
  [water_saturation]
    family = LAGRANGE
    order = FIRST
  []
  [gas_saturation]
    family = LAGRANGE
    order = FIRST
  []
[]

[AuxVariables]
  [porosity]
  []
[]

[Functions]
  [pressure_initial]
    type = ParsedFunction
    expression = '150'
  []
  [pressure_exact]
    type = ParsedFunction
    expression = '150+10*t'
  []
  [ux_exact]
    type = ParsedFunction
    expression = '0'
  []
  [one]
    type = ParsedFunction
    expression = '1'
  []
  [water_saturation_initial]
    type = ParsedFunction
    expression = '0.2'
  []
  [water_saturation_exact]
    type = ParsedFunction
    expression = '0.2+0.02*t'
  []
  [gas_saturation_initial]
    type = ParsedFunction
    expression = '0.3'
  []
  [gas_saturation_exact]
    type = ParsedFunction
    expression = '0.3-0.01*t'
  []
  [porosity_exact]
    type = ParsedFunction
    expression = '0.2'
  []
  [water_component_source]
    type = ParsedFunction
    expression = '200*(0.02/(1.05+0.01*t)-(0.2+0.02*t)*0.01/(1.05+0.01*t)^2)'
  []
  [oil_component_source]
    type = ParsedFunction
    expression = '160*(-0.01/(1.3+0.02*t)-(0.5-0.01*t)*0.02/(1.3+0.02*t)^2)'
  []
  [gas_component_source]
    type = ParsedFunction
    expression = '0.24*(-0.01/(0.015+0.001*t)-(0.3-0.01*t)*0.001/(0.015+0.001*t)^2+5*(0.5-0.01*t)/(1.3+0.02*t)-(75+5*t)*0.01/(1.3+0.02*t)-(75+5*t)*(0.5-0.01*t)*0.02/(1.3+0.02*t)^2)'
  []
[]

[ICs]
  [pressure_ic]
    type = FunctionIC
    variable = pressure
    function = pressure_initial
  []
  [water_saturation_ic]
    type = FunctionIC
    variable = water_saturation
    function = water_saturation_initial
  []
  [gas_saturation_ic]
    type = FunctionIC
    variable = gas_saturation
    function = gas_saturation_initial
  []
  [porosity_ic]
    type = FunctionIC
    variable = porosity
    function = porosity_exact
  []
[]

!include ../../../input/includes/materials/solid_kinematics_1d.i
!include ../../../input/includes/materials/eg_pressure_legacy_reconstruction.i

[Materials]
  [water_saturation_reconstruction]
    type = ADEGReconstructedScalarMaterial
    backbone = water_saturation
    field_name = water_saturation
  []
  [gas_saturation_reconstruction]
    type = ADEGReconstructedScalarMaterial
    backbone = gas_saturation
    field_name = gas_saturation
  []
  [black_oil_pvt]
    type = ADBlackOilPVTMaterial
    compute_storage_rates = true
    pressure_name = pressure_total
    pressure_rate_name = pressure_total_dot
    porosity = porosity
    water_saturation_name = water_saturation_total
    water_saturation_rate_name = water_saturation_total_dot
    gas_saturation_name = gas_saturation_total
    gas_saturation_rate_name = gas_saturation_total_dot
    pressure_points = '100 200'
    water_formation_volume_factor_values = '1 1.1'
    oil_formation_volume_factor_values = '1.2 1.4'
    gas_formation_volume_factor_values = '0.01 0.02'
    solution_gas_oil_ratio_values = '50 100'
    water_surface_density = 1000
    oil_surface_density = 800
    gas_surface_density = 1.2
  []
[]

[Kernels]
  [water_component_balance]
    type = ADEnrichedGalerkinScalarBalance
    variable = water_saturation
    reference_component_storage_rate_name = black_oil_water_reference_component_storage_rate
    source_function = water_component_source
  []
  [oil_component_balance]
    type = ADEnrichedGalerkinScalarBalance
    variable = pressure
    enrichment = pressure_enr
    reference_component_storage_rate_name = black_oil_oil_reference_component_storage_rate
    source_function = oil_component_source
  []
  [oil_component_enrichment_balance]
    type = ADEnrichedGalerkinScalarEnrichmentBalance
    variable = pressure_enr
    backbone = pressure
    reference_component_storage_rate_name = black_oil_oil_reference_component_storage_rate
    source_function = oil_component_source
    anchor_coefficient = 1
  []
  [gas_component_balance]
    type = ADEnrichedGalerkinScalarBalance
    variable = gas_saturation
    reference_component_storage_rate_name = black_oil_gas_reference_component_storage_rate
    source_function = gas_component_source
  []
[]

[AuxKernels]
  [ux_prescribed]
    type = FunctionAux
    variable = ux
    function = ux_exact
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
[]

[Postprocessors]
  [water_component_storage_rate_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_water_reference_component_storage_rate
    function = water_component_source
    execute_on = FINAL
  []
  [oil_component_storage_rate_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_oil_reference_component_storage_rate
    function = oil_component_source
    execute_on = FINAL
  []
  [gas_component_storage_rate_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_gas_reference_component_storage_rate
    function = gas_component_source
    execute_on = FINAL
  []
  [pressure_l2]
    type = ADMaterialScalarL2Error
    property = pressure_total
    function = pressure_exact
    execute_on = TIMESTEP_END
  []
  [pressure_enrichment_l2]
    type = ElementL2Norm
    variable = pressure_enr
    execute_on = TIMESTEP_END
  []
  [solid_reference_jacobian_l2]
    type = ADMaterialScalarL2Error
    property = solid_reference_J
    function = one
    execute_on = TIMESTEP_END
  []
  [water_saturation_l2]
    type = ElementL2Error
    variable = water_saturation
    function = water_saturation_exact
    execute_on = TIMESTEP_END
  []
  [gas_saturation_l2]
    type = ElementL2Error
    variable = gas_saturation
    function = gas_saturation_exact
    execute_on = TIMESTEP_END
  []
[]

[Executioner]
  type = Transient
  scheme = implicit-euler
  solve_type = NEWTON
  start_time = 0
  dt = 0.1
  num_steps = 1
  nl_abs_tol = 1e-12
  nl_rel_tol = 1e-12
  nl_max_its = 20
[]

[Outputs]
  csv = true
[]
