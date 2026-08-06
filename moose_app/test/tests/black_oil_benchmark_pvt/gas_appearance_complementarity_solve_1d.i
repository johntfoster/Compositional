mesh_nx := 2

!include ../../../input/includes/mesh/generated_1d_q2.i

[Variables]
  [solution_gas_oil_ratio]
    family = LAGRANGE
    order = SECOND
  []
[]

[AuxVariables]
  [oil_pressure]
  []
  [porosity]
  []
  [water_saturation]
  []
  [gas_saturation]
  []
[]

[Functions]
  [solution_gas_oil_ratio_initial]
    type = ParsedFunction
    expression = '1.2'
  []
  [solution_gas_oil_ratio_exact]
    type = ParsedFunction
    expression = '1.5'
  []
  [solution_gas_oil_ratio_history_exact]
    type = ParsedFunction
    expression = '1.2'
  []
  [oil_pressure_exact]
    type = ParsedFunction
    expression = '4500'
  []
  [oil_pressure_history]
    type = ParsedFunction
    expression = 'if(t < 1, 4500 - 300*t, 4200 + 600*(t - 1))'
  []
  [porosity_exact]
    type = ParsedFunction
    expression = '0.3'
  []
  [water_saturation_exact]
    type = ParsedFunction
    expression = '0.2'
  []
  [gas_saturation_exact]
    type = ParsedFunction
    expression = '0.1'
  []
[]

[ICs]
  [solution_gas_oil_ratio_ic]
    type = FunctionIC
    variable = solution_gas_oil_ratio
    function = solution_gas_oil_ratio_initial
  []
  [oil_pressure_ic]
    type = FunctionIC
    variable = oil_pressure
    function = oil_pressure_exact
  []
  [porosity_ic]
    type = FunctionIC
    variable = porosity
    function = porosity_exact
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
[]

[AuxKernels]
  [oil_pressure_history]
    type = FunctionAux
    variable = oil_pressure
    function = oil_pressure_exact
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
[]

[Materials]
  [unit_jacobian]
    type = ADGenericConstantMaterial
    prop_names = solid_reference_J
    prop_values = '1'
  []
  [benchmark_pvt]
    type = ADBlackOilBenchmarkPVTMaterial
    oil_pressure = oil_pressure
    solution_gas_oil_ratio = solution_gas_oil_ratio
    porosity = porosity
    water_saturation = water_saturation
    gas_saturation = gas_saturation
    reject_oversaturated_state = false
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
[]

[Kernels]
  [gas_appearance]
    type = ADMaterialPropertyResidual
    variable = solution_gas_oil_ratio
    property = benchmark_black_oil_gas_appearance_complementarity_residual
  []
[]

[Postprocessors]
  [solution_gas_oil_ratio_l2]
    type = ElementL2Error
    variable = solution_gas_oil_ratio
    function = solution_gas_oil_ratio_exact
    execute_on = TIMESTEP_END
  []
[]

[Executioner]
  type = Steady
  solve_type = NEWTON
  nl_abs_tol = 1e-12
  nl_rel_tol = 1e-12
[]

[Outputs]
  csv = true
[]
