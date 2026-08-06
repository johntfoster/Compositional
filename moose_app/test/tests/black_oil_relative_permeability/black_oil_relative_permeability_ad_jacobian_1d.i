[Mesh]
  type = GeneratedMesh
  dim = 1
  nx = 1
  elem_type = EDGE2
[]

[Variables]
  [water_saturation]
  []
[]

[AuxVariables]
  [gas_saturation]
  []
[]

[Functions]
  [water_saturation_initial]
    type = ParsedFunction
    expression = '0.18'
  []
  [water_saturation_exact]
    type = ParsedFunction
    expression = '0.2'
  []
  [gas_saturation_exact]
    type = ParsedFunction
    expression = '0.3'
  []
[]

[ICs]
  [water_saturation_ic]
    type = FunctionIC
    variable = water_saturation
    function = water_saturation_initial
  []
  [gas_saturation_ic]
    type = FunctionIC
    variable = gas_saturation
    function = gas_saturation_exact
  []
[]

[Materials]
  [black_oil_relative_permeability]
    type = ADBlackOilRelativePermeabilityMaterial
    water_saturation = water_saturation
    gas_saturation = gas_saturation
    water_saturation_points = '0.15 0.4 1'
    water_relative_permeability_values = '0 0.1 1'
    oil_water_relative_permeability_values = '1 0.5 0'
    gas_saturation_points = '0 0.3 0.85'
    gas_relative_permeability_values = '0 0.24 0.96'
    oil_gas_relative_permeability_values = '1 0.02 0'
  []
  [water_relative_permeability_residual]
    type = ADParsedMaterial
    material_property_names = black_oil_water_relative_permeability
    property_name = water_relative_permeability_residual
    expression = 'black_oil_water_relative_permeability-0.02'
  []
[]

[Kernels]
  [water_saturation_from_table]
    type = ADMaterialPropertyResidual
    variable = water_saturation
    property = water_relative_permeability_residual
  []
[]

[Postprocessors]
  [water_saturation_l2]
    type = ElementL2Error
    variable = water_saturation
    function = water_saturation_exact
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
