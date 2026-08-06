[Mesh]
  type = GeneratedMesh
  dim = 1
  nx = 1
  elem_type = EDGE2
[]

[Variables]
  [pressure]
  []
  [porosity]
  []
  [water_saturation]
  []
  [gas_saturation]
  []
[]

[Functions]
  [pressure_exact]
    type = ParsedFunction
    expression = '150+10*t'
  []
  [porosity_exact]
    type = ParsedFunction
    expression = '0.2+0.01*t'
  []
  [water_saturation_exact]
    type = ParsedFunction
    expression = '0.2+0.02*t'
  []
  [gas_saturation_exact]
    type = ParsedFunction
    expression = '0.3-0.01*t'
  []
  [water_storage_rate_exact]
    type = ParsedFunction
    expression = '5.626557493770025'
  []
  [oil_storage_rate_exact]
    type = ParsedFunction
    expression = '0.7520661157024799'
  []
  [gas_storage_rate_exact]
    type = ParsedFunction
    expression = '0.33250645661157036'
  []
[]

[ICs]
  [pressure_ic]
    type = FunctionIC
    variable = pressure
    function = pressure_exact
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

[Materials]
  [unit_jacobian]
    type = ADGenericConstantMaterial
    prop_names = 'solid_reference_J solid_reference_J_dot'
    prop_values = '1 0'
  []
  [black_oil_pvt]
    type = ADBlackOilPVTMaterial
    compute_storage_rates = true
    pressure = pressure
    porosity = porosity
    water_saturation = water_saturation
    gas_saturation = gas_saturation
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
  [pressure_null]
    type = NullKernel
    variable = pressure
  []
  [porosity_null]
    type = NullKernel
    variable = porosity
  []
  [water_saturation_null]
    type = NullKernel
    variable = water_saturation
  []
  [gas_saturation_null]
    type = NullKernel
    variable = gas_saturation
  []
[]

[BCs]
  [pressure_exact]
    type = FunctionDirichletBC
    variable = pressure
    boundary = 'left right'
    function = pressure_exact
  []
  [porosity_exact]
    type = FunctionDirichletBC
    variable = porosity
    boundary = 'left right'
    function = porosity_exact
  []
  [water_saturation_exact]
    type = FunctionDirichletBC
    variable = water_saturation
    boundary = 'left right'
    function = water_saturation_exact
  []
  [gas_saturation_exact]
    type = FunctionDirichletBC
    variable = gas_saturation
    boundary = 'left right'
    function = gas_saturation_exact
  []
[]

[Postprocessors]
  [water_storage_rate_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_water_reference_component_storage_rate
    function = water_storage_rate_exact
    execute_on = TIMESTEP_END
  []
  [oil_storage_rate_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_oil_reference_component_storage_rate
    function = oil_storage_rate_exact
    execute_on = TIMESTEP_END
  []
  [gas_storage_rate_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_gas_reference_component_storage_rate
    function = gas_storage_rate_exact
    execute_on = TIMESTEP_END
  []
[]

[Executioner]
  type = Transient
  scheme = implicit-euler
  solve_type = NEWTON
  start_time = 0
  dt = 1
  num_steps = 1
  nl_abs_tol = 1e-12
[]

[Outputs]
  csv = true
[]
