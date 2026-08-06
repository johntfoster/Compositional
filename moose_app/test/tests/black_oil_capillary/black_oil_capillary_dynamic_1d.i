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
  [water_saturation]
  []
  [gas_saturation]
  []
[]

[AuxVariables]
  [oil_pressure]
  []
[]

[Functions]
  [oil_pressure_exact]
    type = ParsedFunction
    expression = '100'
  []
  [water_saturation_exact]
    type = ParsedFunction
    expression = '0.2+0.1*t'
  []
  [gas_saturation_exact]
    type = ParsedFunction
    expression = '0.4-0.05*t'
  []
  [water_pressure_exact]
    type = ParsedFunction
    expression = '82.2+t'
  []
  [gas_pressure_exact]
    type = ParsedFunction
    expression = '108.85-0.5*t'
  []
[]

[ICs]
  [water_pressure_ic]
    type = FunctionIC
    variable = water_pressure
    function = water_pressure_exact
  []
  [gas_pressure_ic]
    type = FunctionIC
    variable = gas_pressure
    function = gas_pressure_exact
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
  [black_oil_capillary]
    type = ADBlackOilCapillaryPressureMaterial
    oil_pressure = oil_pressure
    water_pressure = water_pressure
    gas_pressure = gas_pressure
    water_saturation_name = water_saturation_total
    water_saturation_rate_name = water_saturation_total_dot
    gas_saturation_name = gas_saturation_total
    gas_saturation_rate_name = gas_saturation_total_dot
    water_saturation_points = '0 1'
    water_oil_capillary_pressure_values = '20 10'
    gas_saturation_points = '0 1'
    gas_oil_capillary_pressure_values = '5 15'
    water_oil_dynamic_coefficient = 2
    gas_oil_dynamic_coefficient = 3
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
