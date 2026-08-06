[Mesh]
  type = GeneratedMesh
  dim = 1
  nx = 2
  elem_type = EDGE2
[]

[Variables]
  [water_rate]
  []
  [gas_rate]
  []
[]

[ICs]
  [water_rate]
    type = ConstantIC
    variable = water_rate
    value = 0.1
  []
  [gas_rate]
    type = ConstantIC
    variable = gas_rate
    value = -0.2
  []
[]

[Functions]
  [water_rate_exact]
    type = ConstantFunction
    value = 0.2
  []
  [gas_rate_exact]
    type = ConstantFunction
    value = -0.1
  []
[]

[Materials]
  [water_rate_property]
    type = ADParsedMaterial
    property_name = test_water_rate
    coupled_variables = water_rate
    expression = water_rate
  []
  [gas_rate_property]
    type = ADParsedMaterial
    property_name = test_gas_rate
    coupled_variables = gas_rate
    expression = gas_rate
  []
  [T00]
    type = ADParsedMaterial
    property_name = test_T00
    coupled_variables = water_rate
    expression = '2+water_rate'
  []
  [T01]
    type = ADParsedMaterial
    property_name = test_T01
    coupled_variables = gas_rate
    expression = '0.5+0.1*gas_rate'
  []
  [T11]
    type = ADParsedMaterial
    property_name = test_T11
    coupled_variables = gas_rate
    expression = '3+gas_rate'
  []
  [saturation_onsager]
    type = ADSaturationOnsagerForceMaterial
    independent_phase_names = 'water gas'
    saturation_rate_names = 'test_water_rate test_gas_rate'
    resistance_property_names = 'test_T00 test_T01 test_T01 test_T11'
    property_prefix = test_saturation_onsager
  []
  [water_residual]
    type = ADParsedMaterial
    property_name = test_water_residual
    material_property_names = test_saturation_onsager_water_force_difference
    expression = 'test_saturation_onsager_water_force_difference-0.391'
  []
  [gas_residual]
    type = ADParsedMaterial
    property_name = test_gas_residual
    material_property_names = test_saturation_onsager_gas_force_difference
    expression = 'test_saturation_onsager_gas_force_difference+0.192'
  []
[]

[Kernels]
  [water_equation]
    type = ADMaterialPropertyResidual
    variable = water_rate
    property = test_water_residual
  []
  [gas_equation]
    type = ADMaterialPropertyResidual
    variable = gas_rate
    property = test_gas_residual
  []
[]

[Postprocessors]
  [water_rate_l2]
    type = ElementL2Error
    variable = water_rate
    function = water_rate_exact
  []
  [gas_rate_l2]
    type = ElementL2Error
    variable = gas_rate
    function = gas_rate_exact
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
