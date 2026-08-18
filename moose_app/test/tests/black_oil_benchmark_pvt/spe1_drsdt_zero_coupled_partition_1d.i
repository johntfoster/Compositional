[Mesh]
  [line]
    type = GeneratedMeshGenerator
    dim = 1
    nx = 1
  []
[]

[Variables]
  [solution_gas_oil_ratio]
    family = LAGRANGE
    order = FIRST
  []
  [gas_saturation]
    family = LAGRANGE
    order = FIRST
  []
  [gas_phase_transformation_rate]
    family = LAGRANGE
    order = FIRST
  []
[]

[Functions]
  [solution_gas_oil_ratio_initial]
    type = ParsedFunction
    expression = '1.5'
  []
  [gas_saturation_initial]
    type = ParsedFunction
    expression = '0.1'
  []
  [zero]
    type = ParsedFunction
    expression = '0'
  []
[]

[ICs]
  [solution_gas_oil_ratio_ic]
    type = FunctionIC
    variable = solution_gas_oil_ratio
    function = solution_gas_oil_ratio_initial
  []
  [gas_saturation_ic]
    type = FunctionIC
    variable = gas_saturation
    function = gas_saturation_initial
  []
  [gas_phase_transformation_rate_ic]
    type = FunctionIC
    variable = gas_phase_transformation_rate
    function = zero
  []
[]

[Materials]
  [reference_kinematics]
    type = ADGenericConstantMaterial
    prop_names = 'solid_reference_J solid_reference_J_dot oil_pressure_for_pvt oil_pressure_for_pvt_dot porosity_for_pvt porosity_for_pvt_dot water_saturation_for_pvt water_saturation_for_pvt_dot'
    prop_values = '1 0 4200 0 0.3 0 0.2 0'
  []
  [benchmark_pvt]
    type = ADBlackOilBenchmarkPVTMaterial
    compute_storage_rates = true
    oil_pressure_name = oil_pressure_for_pvt
    oil_pressure_rate_name = oil_pressure_for_pvt_dot
    solution_gas_oil_ratio = solution_gas_oil_ratio
    porosity_name = porosity_for_pvt
    porosity_rate_name = porosity_for_pvt_dot
    water_saturation_name = water_saturation_for_pvt
    water_saturation_rate_name = water_saturation_for_pvt_dot
    gas_saturation = gas_saturation
    reject_oversaturated_state = false
    equilibrate_solution_gas_with_free_gas = false
    enforce_nonincreasing_solution_gas = true
    maximum_solution_gas_oil_ratio = 2
    solution_gas_transition_width = 0
    out_of_range_policy = clamp
    water_reference_pressure = 4000
    water_reference_fvf = 1
    water_compressibility = 0
    water_reference_viscosity = 1
    water_viscosibility = 0
    gas_pressure_points = '4000 5000'
    gas_fvf_values = '1 0.8'
    gas_viscosity_values = '0.02 0.03'
    oil_solution_gas_oil_ratio_points = '1 2'
    oil_bubble_pressure_points = '4000 5000'
    oil_branch_offsets = '0 1 2'
    oil_pressure_points = '4000 5000'
    oil_fvf_values = '1.2 1.4'
    oil_viscosity_values = '1 0.8'
    saturated_oil_fvf_values = '1.2 1.4'
    saturated_oil_viscosity_values = '1 0.8'
    water_surface_density = 1000
    oil_surface_density = 800
    gas_surface_density = 1
  []
  [free_gas_phase_balance]
    type = ADParsedMaterial
    coupled_variables = gas_phase_transformation_rate
    material_property_names = benchmark_black_oil_free_gas_reference_component_storage_rate
    property_name = free_gas_phase_balance_residual
    expression = 'benchmark_black_oil_free_gas_reference_component_storage_rate-gas_phase_transformation_rate'
  []
[]

[Kernels]
  [total_gas_balance]
    type = ADMaterialPropertyResidual
    variable = solution_gas_oil_ratio
    property = benchmark_black_oil_gas_reference_component_storage_rate
  []
  [free_gas_phase_balance]
    type = ADMaterialPropertyResidual
    variable = gas_saturation
    property = free_gas_phase_balance_residual
  []
  [solution_gas_history]
    type = ADMaterialPropertyResidual
    variable = gas_phase_transformation_rate
    property = benchmark_black_oil_solution_gas_constraint_residual
  []
[]

[Postprocessors]
  [solution_gas_oil_ratio_average]
    type = ElementAverageValue
    variable = solution_gas_oil_ratio
    execute_on = TIMESTEP_END
  []
  [gas_saturation_average]
    type = ElementAverageValue
    variable = gas_saturation
    execute_on = TIMESTEP_END
  []
  [gas_phase_transformation_rate_average]
    type = ElementAverageValue
    variable = gas_phase_transformation_rate
    execute_on = TIMESTEP_END
  []
  [solution_gas_history_l2]
    type = ADMaterialScalarL2Error
    property = benchmark_black_oil_solution_gas_constraint_residual
    function = zero
    execute_on = TIMESTEP_END
  []
  [total_gas_balance_l2]
    type = ADMaterialScalarL2Error
    property = benchmark_black_oil_gas_reference_component_storage_rate
    function = zero
    execute_on = TIMESTEP_END
  []
  [free_gas_phase_balance_l2]
    type = ADMaterialScalarL2Error
    property = free_gas_phase_balance_residual
    function = zero
    execute_on = TIMESTEP_END
  []
[]

[Executioner]
  type = Transient
  solve_type = NEWTON
  dt = 1
  num_steps = 2
  nl_abs_tol = 1e-12
  nl_rel_tol = 1e-12
  petsc_options_iname = '-pc_type -pc_factor_mat_solver_type'
  petsc_options_value = 'lu superlu_dist'
[]

[Outputs]
  csv = true
[]
