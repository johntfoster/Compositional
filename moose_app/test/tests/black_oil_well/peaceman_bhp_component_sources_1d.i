[Mesh]
  [line]
    type = GeneratedMeshGenerator
    dim = 1
    nx = 2
  []
[]

[Functions]
  [water_reservoir_rate_exact]
    type = ParsedFunction
    expression = '20'
  []
  [oil_reservoir_rate_exact]
    type = ParsedFunction
    expression = '80'
  []
  [gas_reservoir_rate_exact]
    type = ParsedFunction
    expression = '180'
  []
  [water_surface_rate_exact]
    type = ParsedFunction
    expression = '10'
  []
  [oil_surface_rate_exact]
    type = ParsedFunction
    expression = '20'
  []
  [gas_surface_rate_exact]
    type = ParsedFunction
    expression = '460'
  []
  [water_source_exact]
    type = ParsedFunction
    expression = '-1000'
  []
  [oil_source_exact]
    type = ParsedFunction
    expression = '-1600'
  []
  [gas_source_exact]
    type = ParsedFunction
    expression = '-55.2'
  []
  [effective_bhp_exact]
    type = ParsedFunction
    expression = '90'
  []
  [zero]
    type = ParsedFunction
    expression = '0'
  []
  [limited_water_reservoir_rate_exact]
    type = ParsedFunction
    expression = '40'
  []
  [limited_oil_reservoir_rate_exact]
    type = ParsedFunction
    expression = '120'
  []
  [limited_gas_reservoir_rate_exact]
    type = ParsedFunction
    expression = '240'
  []
  [limited_water_surface_rate_exact]
    type = ParsedFunction
    expression = '20'
  []
  [limited_oil_surface_rate_exact]
    type = ParsedFunction
    expression = '30'
  []
  [limited_gas_surface_rate_exact]
    type = ParsedFunction
    expression = '630'
  []
  [limited_water_source_exact]
    type = ParsedFunction
    expression = '-2000'
  []
  [limited_oil_source_exact]
    type = ParsedFunction
    expression = '-2400'
  []
  [limited_gas_source_exact]
    type = ParsedFunction
    expression = '-75.6'
  []
  [limited_effective_bhp_exact]
    type = ParsedFunction
    expression = '80'
  []
  [limited_control_residual_exact]
    type = ParsedFunction
    expression = '-10'
  []
  [gas_rate_water_reservoir_rate_exact]
    type = ParsedFunction
    expression = '0'
  []
  [gas_rate_oil_reservoir_rate_exact]
    type = ParsedFunction
    expression = '0'
  []
  [gas_rate_gas_reservoir_rate_exact]
    type = ParsedFunction
    expression = '-30'
  []
  [gas_rate_water_surface_rate_exact]
    type = ParsedFunction
    expression = '0'
  []
  [gas_rate_oil_surface_rate_exact]
    type = ParsedFunction
    expression = '0'
  []
  [gas_rate_gas_surface_rate_exact]
    type = ParsedFunction
    expression = '-60'
  []
  [gas_rate_water_source_exact]
    type = ParsedFunction
    expression = '0'
  []
  [gas_rate_oil_source_exact]
    type = ParsedFunction
    expression = '0'
  []
  [gas_rate_gas_source_exact]
    type = ParsedFunction
    expression = '7.2'
  []
  [gas_rate_effective_bhp_exact]
    type = ParsedFunction
    expression = '125'
  []
  [limited_gas_rate_water_reservoir_rate_exact]
    type = ParsedFunction
    expression = '0'
  []
  [limited_gas_rate_oil_reservoir_rate_exact]
    type = ParsedFunction
    expression = '0'
  []
  [limited_gas_rate_gas_reservoir_rate_exact]
    type = ParsedFunction
    expression = '-18'
  []
  [limited_gas_rate_water_surface_rate_exact]
    type = ParsedFunction
    expression = '0'
  []
  [limited_gas_rate_oil_surface_rate_exact]
    type = ParsedFunction
    expression = '0'
  []
  [limited_gas_rate_gas_surface_rate_exact]
    type = ParsedFunction
    expression = '-36'
  []
  [limited_gas_rate_water_source_exact]
    type = ParsedFunction
    expression = '0'
  []
  [limited_gas_rate_oil_source_exact]
    type = ParsedFunction
    expression = '0'
  []
  [limited_gas_rate_gas_source_exact]
    type = ParsedFunction
    expression = '4.32'
  []
  [limited_gas_rate_effective_bhp_exact]
    type = ParsedFunction
    expression = '123'
  []
  [limited_gas_rate_control_residual_exact]
    type = ParsedFunction
    expression = '24'
  []
[]

[Materials]
  [well_state]
    type = ADGenericConstantMaterial
    prop_names = 'water_pressure oil_pressure gas_pressure water_mobility oil_mobility gas_mobility water_relative_permeability oil_relative_permeability gas_relative_permeability water_viscosity oil_viscosity gas_viscosity water_fvf oil_fvf gas_fvf solution_gas_oil_ratio'
    prop_values = '100 110 120 1 2 3 1 2 3 1 1 1 2 4 0.5 5'
  []
  [well]
    type = ADBlackOilPeacemanWellMaterial
    water_pressure_name = water_pressure
    oil_pressure_name = oil_pressure
    gas_pressure_name = gas_pressure
    water_mobility_name = water_mobility
    oil_mobility_name = oil_mobility
    gas_mobility_name = gas_mobility
    water_fvf_name = water_fvf
    oil_fvf_name = oil_fvf
    gas_fvf_name = gas_fvf
    solution_gas_oil_ratio_name = solution_gas_oil_ratio
    well_index = 2
    bottom_hole_pressure = 90
    completion_reference_volume = 10
    water_surface_density = 1000
    oil_surface_density = 800
    gas_surface_density = 1.2
  []
[]

[Postprocessors]
  [water_reservoir_rate_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_well_water_reservoir_rate
    function = water_reservoir_rate_exact
    execute_on = INITIAL
  []
  [oil_reservoir_rate_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_well_oil_reservoir_rate
    function = oil_reservoir_rate_exact
    execute_on = INITIAL
  []
  [gas_reservoir_rate_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_well_gas_reservoir_rate
    function = gas_reservoir_rate_exact
    execute_on = INITIAL
  []
  [water_surface_rate_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_well_water_surface_rate
    function = water_surface_rate_exact
    execute_on = INITIAL
  []
  [oil_surface_rate_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_well_oil_surface_rate
    function = oil_surface_rate_exact
    execute_on = INITIAL
  []
  [gas_surface_rate_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_well_gas_surface_rate
    function = gas_surface_rate_exact
    execute_on = INITIAL
  []
  [water_source_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_well_water_reference_component_source
    function = water_source_exact
    execute_on = INITIAL
  []
  [oil_source_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_well_oil_reference_component_source
    function = oil_source_exact
    execute_on = INITIAL
  []
  [gas_source_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_well_gas_reference_component_source
    function = gas_source_exact
    execute_on = INITIAL
  []
  [effective_bhp_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_well_effective_bottom_hole_pressure
    function = effective_bhp_exact
    execute_on = INITIAL
  []
  [control_surface_rate_residual_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_well_control_surface_rate_residual
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
[]
