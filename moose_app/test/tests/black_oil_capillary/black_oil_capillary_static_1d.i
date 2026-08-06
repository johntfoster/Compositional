[Mesh]
  type = GeneratedMesh
  dim = 1
  nx = 1
  elem_type = EDGE2
[]

[Variables]
  [water_pressure]
  []
  [gas_pressure]
  []
[]

[AuxVariables]
  [oil_pressure]
  []
  [water_saturation]
  []
  [gas_saturation]
  []
[]

[Functions]
  [oil_pressure_exact]
    type = ParsedFunction
    expression = '100'
  []
  [water_pressure_initial]
    type = ParsedFunction
    expression = '90'
  []
  [water_pressure_exact]
    type = ParsedFunction
    expression = '82.5'
  []
  [gas_pressure_initial]
    type = ParsedFunction
    expression = '105'
  []
  [gas_pressure_exact]
    type = ParsedFunction
    expression = '109'
  []
  [water_saturation_exact]
    type = ParsedFunction
    expression = '0.25'
  []
  [gas_saturation_exact]
    type = ParsedFunction
    expression = '0.4'
  []
[]

[ICs]
  [water_pressure_ic]
    type = FunctionIC
    variable = water_pressure
    function = water_pressure_initial
  []
  [gas_pressure_ic]
    type = FunctionIC
    variable = gas_pressure
    function = gas_pressure_initial
  []
  [oil_pressure_ic]
    type = FunctionIC
    variable = oil_pressure
    function = oil_pressure_exact
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
  [black_oil_capillary]
    type = ADBlackOilCapillaryPressureMaterial
    oil_pressure = oil_pressure
    water_pressure = water_pressure
    gas_pressure = gas_pressure
    water_saturation = water_saturation
    gas_saturation = gas_saturation
    water_saturation_points = '0 1'
    water_oil_capillary_pressure_values = '20 10'
    gas_saturation_points = '0 1'
    gas_oil_capillary_pressure_values = '5 15'
  []
[]

[Kernels]
  [water_pressure_closure]
    type = ADMaterialPropertyResidual
    variable = water_pressure
    property = black_oil_water_pressure_closure_residual
  []
  [gas_pressure_closure]
    type = ADMaterialPropertyResidual
    variable = gas_pressure
    property = black_oil_gas_pressure_closure_residual
  []
[]

[Postprocessors]
  [water_pressure_l2]
    type = ElementL2Error
    variable = water_pressure
    function = water_pressure_exact
    execute_on = TIMESTEP_END
  []
  [gas_pressure_l2]
    type = ElementL2Error
    variable = gas_pressure
    function = gas_pressure_exact
    execute_on = TIMESTEP_END
  []
[]

[Executioner]
  type = Steady
  solve_type = NEWTON
  nl_abs_tol = 1e-12
[]

[Outputs]
  csv = true
[]
