[Mesh]
  type = GeneratedMesh
  dim = 1
  nx = 1
  elem_type = EDGE2
[]

[AuxVariables]
  [water_saturation]
  []
  [gas_saturation]
  []
[]

[Functions]
  [water_saturation_exact]
    type = ParsedFunction
    expression = '0.2'
  []
  [gas_saturation_exact]
    type = ParsedFunction
    expression = '0.3'
  []
  [water_relative_permeability_exact]
    type = ParsedFunction
    expression = '0.02'
  []
  [gas_relative_permeability_exact]
    type = ParsedFunction
    expression = '0.24'
  []
  [oil_water_relative_permeability_exact]
    type = ParsedFunction
    expression = '5/12'
  []
  [oil_gas_relative_permeability_exact]
    type = ParsedFunction
    expression = '0.02'
  []
  [oil_relative_permeability_exact]
    type = ParsedFunction
    expression = '23/300'
  []
[]

[ICs]
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
[]

[Postprocessors]
  [water_relative_permeability_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_water_relative_permeability
    function = water_relative_permeability_exact
    execute_on = INITIAL
  []
  [oil_relative_permeability_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_oil_relative_permeability
    function = oil_relative_permeability_exact
    execute_on = INITIAL
  []
  [gas_relative_permeability_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_gas_relative_permeability
    function = gas_relative_permeability_exact
    execute_on = INITIAL
  []
  [oil_water_relative_permeability_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_oil_water_relative_permeability
    function = oil_water_relative_permeability_exact
    execute_on = INITIAL
  []
  [oil_gas_relative_permeability_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_oil_gas_relative_permeability
    function = oil_gas_relative_permeability_exact
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
