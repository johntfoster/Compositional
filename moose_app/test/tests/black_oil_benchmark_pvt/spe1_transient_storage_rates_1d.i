[Mesh]
  [line]
    type = GeneratedMeshGenerator
    dim = 1
    nx = 2
  []
[]

[Variables]
  [oil_pressure]
    scaling = 1000
  []
  [oil_pressure_enrichment]
    family = MONOMIAL
    order = CONSTANT
    initial_condition = 0
  []
  [solution_gas_oil_ratio]
  []
  [water_saturation]
  []
  [gas_saturation]
  []
[]

[AuxVariables]
  [porosity]
  []
  [gas_saturation_bound]
  []
[]

[Functions]
  [oil_pressure_exact]
    type = ParsedFunction
    expression = '4800+10*t'
  []
  [solution_gas_oil_ratio_exact]
    type = ParsedFunction
    expression = '1.27+0.000348*(4800+10*t-4014.7)'
  []
  [water_saturation_exact]
    type = ParsedFunction
    expression = '0.12+0.001*t'
  []
  [gas_saturation_exact]
    type = ParsedFunction
    expression = '0.1-0.0005*t'
  []
  [porosity_exact]
    type = ParsedFunction
    expression = '0.3'
  []
  [water_storage_rate_exact]
    type = ParsedFunction
    expression = '64.49*0.3*(0.001*((1+3.22e-6*(4800+10*t-4017.55)*(1+3.22e-6*(4800+10*t-4017.55)/2))/1.038)+(0.12+0.001*t)*(3.22e-6*(1+3.22e-6*(4800+10*t-4017.55))/1.038)*10)'
  []
  [oil_storage_rate_exact]
    type = ParsedFunction
    expression = '53.66*0.3*(-0.0005/(1.695+0.000132*(4800+10*t-4014.7))-(0.78-0.0005*t)*0.00132/(1.695+0.000132*(4800+10*t-4014.7))^2)'
  []
  [gas_storage_rate_exact]
    type = ParsedFunction
    expression = '0.0533*0.3*(-0.0005/(0.811-0.000162*(4800+10*t-4014.7))-(0.1-0.0005*t)*(-0.00162)/(0.811-0.000162*(4800+10*t-4014.7))^2+0.00348*(0.78-0.0005*t)/(1.695+0.000132*(4800+10*t-4014.7))+(1.27+0.000348*(4800+10*t-4014.7))*(-0.0005)/(1.695+0.000132*(4800+10*t-4014.7))-(1.27+0.000348*(4800+10*t-4014.7))*(0.78-0.0005*t)*0.00132/(1.695+0.000132*(4800+10*t-4014.7))^2)'
  []
[]

[ICs]
  [oil_pressure_ic]
    type = FunctionIC
    variable = oil_pressure
    function = oil_pressure_exact
  []
  [solution_gas_oil_ratio_ic]
    type = FunctionIC
    variable = solution_gas_oil_ratio
    function = solution_gas_oil_ratio_exact
  []
  [water_saturation_ic]
    type = FunctionIC
    variable = water_saturation
    function = water_saturation_exact
  []
  [gas_saturation_ic]
    type = FunctionIC
    variable = gas_saturation
    function = gas_saturation_exact
  []
  [porosity_ic]
    type = FunctionIC
    variable = porosity
    function = porosity_exact
  []
[]

[Materials]
  [oil_pressure_reconstruction]
    type = ADEGReconstructedScalarMaterial
    field_name = spe1_oil_pressure
    backbone = oil_pressure
    enrichment = oil_pressure_enrichment
  []
  [reference_kinematics]
    type = ADGenericConstantMaterial
    prop_names = 'solid_reference_J solid_reference_J_dot'
    prop_values = '1 0'
  []
  [spe1_pvt]
    type = ADBlackOilBenchmarkPVTMaterial
    compute_storage_rates = true
    oil_pressure_name = spe1_oil_pressure_total
    oil_pressure_rate_name = spe1_oil_pressure_total_dot
    solution_gas_oil_ratio = solution_gas_oil_ratio
    porosity = porosity
    water_saturation = water_saturation
    gas_saturation = gas_saturation
    reject_oversaturated_state = false
    water_reference_pressure = 4017.55
    water_reference_fvf = 1.038
    water_compressibility = 3.22e-6
    water_reference_viscosity = 0.318
    water_viscosibility = 0
    gas_pressure_points = '14.7 264.7 514.7 1014.7 2014.7 2514.7 3014.7 4014.7 5014.7 9014.7'
    gas_fvf_values = '166.666 12.093 6.274 3.197 1.614 1.294 1.080 0.811 0.649 0.386'
    gas_viscosity_values = '0.008 0.0096 0.0112 0.014 0.0189 0.0208 0.0228 0.0268 0.0309 0.047'
    oil_solution_gas_oil_ratio_points = '0.001 0.0905 0.18 0.371 0.636 0.775 0.93 1.27 1.618'
    oil_bubble_pressure_points = '14.7 264.7 514.7 1014.7 2014.7 2514.7 3014.7 4014.7 5014.7'
    oil_branch_offsets = '0 1 2 3 4 5 6 7 9 11'
    oil_pressure_points = '14.7 264.7 514.7 1014.7 2014.7 2514.7 3014.7 4014.7 9014.7 5014.7 9014.7'
    oil_fvf_values = '1.062 1.15 1.207 1.295 1.435 1.5 1.565 1.695 1.579 1.827 1.737'
    oil_viscosity_values = '1.04 0.975 0.91 0.83 0.695 0.641 0.594 0.51 0.74 0.449 0.631'
    saturated_oil_fvf_values = '1.062 1.15 1.207 1.295 1.435 1.5 1.565 1.695 1.827'
    saturated_oil_viscosity_values = '1.04 0.975 0.91 0.83 0.695 0.641 0.594 0.51 0.449'
    water_surface_density = 64.49
    oil_surface_density = 53.66
    gas_surface_density = 0.0533
  []
  [gas_phase_rate_split_residual]
    type = ADParsedMaterial
    material_property_names = 'benchmark_black_oil_gas_reference_component_storage_rate benchmark_black_oil_dissolved_gas_reference_component_storage_rate benchmark_black_oil_free_gas_reference_component_storage_rate'
    property_name = gas_phase_rate_split_residual
    expression = 'benchmark_black_oil_gas_reference_component_storage_rate-benchmark_black_oil_dissolved_gas_reference_component_storage_rate-benchmark_black_oil_free_gas_reference_component_storage_rate'
  []
  [water_phase_mass_coefficient_identity]
    type = ADParsedMaterial
    coupled_variables = water_saturation
    material_property_names = 'benchmark_black_oil_water_reference_phase_mass_coefficient benchmark_black_oil_water_reference_component_storage'
    property_name = water_phase_mass_coefficient_identity_residual
    expression = 'benchmark_black_oil_water_reference_phase_mass_coefficient*water_saturation-benchmark_black_oil_water_reference_component_storage'
  []
  [free_gas_phase_mass_coefficient_identity]
    type = ADParsedMaterial
    coupled_variables = gas_saturation
    material_property_names = 'benchmark_black_oil_free_gas_reference_phase_mass_coefficient benchmark_black_oil_free_gas_reference_component_storage'
    property_name = free_gas_phase_mass_coefficient_identity_residual
    expression = 'benchmark_black_oil_free_gas_reference_phase_mass_coefficient*gas_saturation-benchmark_black_oil_free_gas_reference_component_storage'
  []
[]

[Kernels]
  [water_balance]
    type = ADEnrichedGalerkinScalarBalance
    variable = water_saturation
    reference_component_storage_rate_name = benchmark_black_oil_water_reference_component_storage_rate
    source_function = water_storage_rate_exact
  []
  [oil_balance]
    type = ADEnrichedGalerkinScalarBalance
    variable = oil_pressure
    enrichment = oil_pressure_enrichment
    reference_component_storage_rate_name = benchmark_black_oil_oil_reference_component_storage_rate
    source_function = oil_storage_rate_exact
  []
  [oil_enrichment_balance]
    type = ADEnrichedGalerkinScalarEnrichmentBalance
    variable = oil_pressure_enrichment
    backbone = oil_pressure
    reference_component_storage_rate_name = benchmark_black_oil_oil_reference_component_storage_rate
    source_function = oil_storage_rate_exact
    anchor_coefficient = 1
  []
  [gas_balance]
    type = ADEnrichedGalerkinScalarBalance
    variable = solution_gas_oil_ratio
    reference_component_storage_rate_name = benchmark_black_oil_gas_reference_component_storage_rate
    source_function = gas_storage_rate_exact
  []
  [gas_appearance]
    type = ADMaterialPropertyResidual
    variable = gas_saturation
    property = benchmark_black_oil_undersaturation_gap
  []
[]

[Bounds]
  [nonnegative_gas_saturation]
    type = ConstantBounds
    variable = gas_saturation_bound
    bounded_variable = gas_saturation
    bound_type = lower
    bound_value = 0
  []
[]

[Postprocessors]
  [oil_pressure_l2]
    type = ElementL2Error
    variable = oil_pressure
    function = oil_pressure_exact
    execute_on = TIMESTEP_END
  []
  [oil_pressure_enrichment_l2]
    type = ElementL2Norm
    variable = oil_pressure_enrichment
    execute_on = TIMESTEP_END
  []
  [solution_gas_oil_ratio_l2]
    type = ElementL2Error
    variable = solution_gas_oil_ratio
    function = solution_gas_oil_ratio_exact
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
  [water_storage_rate_l2]
    type = ADMaterialScalarL2Error
    property = benchmark_black_oil_water_reference_component_storage_rate
    function = water_storage_rate_exact
    execute_on = TIMESTEP_END
  []
  [oil_storage_rate_l2]
    type = ADMaterialScalarL2Error
    property = benchmark_black_oil_oil_reference_component_storage_rate
    function = oil_storage_rate_exact
    execute_on = TIMESTEP_END
  []
  [gas_storage_rate_l2]
    type = ADMaterialScalarL2Error
    property = benchmark_black_oil_gas_reference_component_storage_rate
    function = gas_storage_rate_exact
    execute_on = TIMESTEP_END
  []
  [gas_phase_rate_split_l2]
    type = ADMaterialScalarL2Error
    property = gas_phase_rate_split_residual
    function = 0
    execute_on = TIMESTEP_END
  []
  [water_phase_mass_coefficient_identity_l2]
    type = ADMaterialScalarL2Error
    property = water_phase_mass_coefficient_identity_residual
    function = 0
    execute_on = TIMESTEP_END
  []
  [free_gas_phase_mass_coefficient_identity_l2]
    type = ADMaterialScalarL2Error
    property = free_gas_phase_mass_coefficient_identity_residual
    function = 0
    execute_on = TIMESTEP_END
  []
[]

[Executioner]
  type = Transient
  scheme = implicit-euler
  solve_type = NEWTON
  dt = 0.1
  num_steps = 1
  nl_abs_tol = 1e-12
  nl_rel_tol = 1e-12
  nl_max_its = 30
  petsc_options_iname = '-snes_type'
  petsc_options_value = 'vinewtonrsls'
[]

[Outputs]
  csv = true
[]
