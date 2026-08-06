[Mesh]
  type = GeneratedMesh
  dim = 1
  nx = 1
  elem_type = EDGE2
[]

[Problem]
  solve = false
[]

[AuxVariables]
  [water_saturation]
  []
  [gas_saturation]
  []
[]

[Functions]
  [water_saturation]
    type = ParsedFunction
    expression = '0.30'
  []
  [gas_saturation]
    type = ParsedFunction
    expression = '0.10'
  []
  [water_kr]
    type = ParsedFunction
    expression = '0.07'
  []
  [gas_kr]
    type = ParsedFunction
    expression = '0.022'
  []
  [oil_water_kr]
    type = ParsedFunction
    expression = '0.4'
  []
  [oil_gas_kr]
    type = ParsedFunction
    expression = '0.33'
  []
  [oil_kr]
    type = ParsedFunction
    expression = '0.07344'
  []
[]

[ICs]
  [water_saturation]
    type = FunctionIC
    variable = water_saturation
    function = water_saturation
  []
  [gas_saturation]
    type = FunctionIC
    variable = gas_saturation
    function = gas_saturation
  []
[]

[Materials]
  [stone_ii]
    type = ADBlackOilStoneIIRelativePermeabilityMaterial
    water_saturation = water_saturation
    gas_saturation = gas_saturation
    water_saturation_points = '0.22 0.30 0.40 0.50 0.60 0.80 0.90 1.00'
    water_relative_permeability_values = '0 0.07 0.15 0.24 0.33 0.65 0.83 1.00'
    oil_water_relative_permeability_values = '1.0 0.4 0.125 0.0649 0.0048 0 0 0'
    gas_saturation_points = '0 0.04 0.10 0.20 0.30 0.40 0.50 0.60 0.70 0.78'
    gas_relative_permeability_values = '0 0 0.022 0.1 0.24 0.34 0.42 0.5 0.8125 1.0'
    oil_gas_relative_permeability_values = '1.0 0.6 0.33 0.1 0.02 0 0 0 0 0'
    property_prefix = spe2_stone_ii
  []
[]

[Postprocessors]
  [water_kr_l2]
    type = ADMaterialScalarL2Error
    property = spe2_stone_ii_water_relative_permeability
    function = water_kr
  []
  [gas_kr_l2]
    type = ADMaterialScalarL2Error
    property = spe2_stone_ii_gas_relative_permeability
    function = gas_kr
  []
  [oil_water_kr_l2]
    type = ADMaterialScalarL2Error
    property = spe2_stone_ii_oil_water_relative_permeability
    function = oil_water_kr
  []
  [oil_gas_kr_l2]
    type = ADMaterialScalarL2Error
    property = spe2_stone_ii_oil_gas_relative_permeability
    function = oil_gas_kr
  []
  [oil_kr_l2]
    type = ADMaterialScalarL2Error
    property = spe2_stone_ii_oil_relative_permeability
    function = oil_kr
  []
  [unclamped_oil_kr_l2]
    type = ADMaterialScalarL2Error
    property = spe2_stone_ii_unclamped_oil_relative_permeability
    function = oil_kr
  []
[]

[Executioner]
  type = Steady
[]

[Outputs]
  csv = true
[]
