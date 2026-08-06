!include spe1_cartesian_grid_3d.i

[AuxVariables]
  [oil_pressure_initial]
    family = MONOMIAL
    order = CONSTANT
  []
  [solution_gas_oil_ratio_initial]
    family = MONOMIAL
    order = CONSTANT
  []
  [water_saturation_initial]
    family = MONOMIAL
    order = CONSTANT
  []
  [gas_saturation_initial]
    family = MONOMIAL
    order = CONSTANT
  []
[]

[Functions]
  [layer_1_pressure]
    type = ParsedFunction
    expression = '32972876.15288512'
  []
  [layer_2_pressure]
    type = ParsedFunction
    expression = '33019779.87273818'
  []
  [layer_3_pressure]
    type = ParsedFunction
    expression = '33094835.007206395'
  []
  [initial_solution_gas_oil_ratio]
    type = ParsedFunction
    expression = '226.19666048237477'
  []
  [initial_water_saturation]
    type = ParsedFunction
    expression = '0.12'
  []
  [initial_gas_saturation]
    type = ParsedFunction
    expression = '0'
  []
[]

[ICs]
  [layer_1_pressure_ic]
    type = FunctionIC
    variable = oil_pressure_initial
    block = 1
    function = layer_1_pressure
  []
  [layer_2_pressure_ic]
    type = FunctionIC
    variable = oil_pressure_initial
    block = 2
    function = layer_2_pressure
  []
  [layer_3_pressure_ic]
    type = FunctionIC
    variable = oil_pressure_initial
    block = 3
    function = layer_3_pressure
  []
  [solution_gas_oil_ratio_ic]
    type = FunctionIC
    variable = solution_gas_oil_ratio_initial
    function = initial_solution_gas_oil_ratio
  []
  [water_saturation_ic]
    type = FunctionIC
    variable = water_saturation_initial
    function = initial_water_saturation
  []
  [gas_saturation_ic]
    type = FunctionIC
    variable = gas_saturation_initial
    function = initial_gas_saturation
  []
[]

[Postprocessors]
  [layer_1_pressure_l2]
    type = ElementL2Error
    block = 1
    variable = oil_pressure_initial
    function = layer_1_pressure
  []
  [layer_2_pressure_l2]
    type = ElementL2Error
    block = 2
    variable = oil_pressure_initial
    function = layer_2_pressure
  []
  [layer_3_pressure_l2]
    type = ElementL2Error
    block = 3
    variable = oil_pressure_initial
    function = layer_3_pressure
  []
  [solution_gas_oil_ratio_l2]
    type = ElementL2Error
    variable = solution_gas_oil_ratio_initial
    function = initial_solution_gas_oil_ratio
  []
  [water_saturation_l2]
    type = ElementL2Error
    variable = water_saturation_initial
    function = initial_water_saturation
  []
  [gas_saturation_l2]
    type = ElementL2Error
    variable = gas_saturation_initial
    function = initial_gas_saturation
  []
[]
