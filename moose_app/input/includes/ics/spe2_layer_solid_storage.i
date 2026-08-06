# SPE2 Table 2 porosity at 3600 psia, represented by the conserved normalized
# solid-reference constituent J(1-phi). At the loaded reference state J=1.
[ICs]
  [spe2_layer_1_solid_storage]
    type = ConstantIC
    variable = matrix_reference_component_storage
    block = 1
    value = 0.913
  []
  [spe2_layer_2_solid_storage]
    type = ConstantIC
    variable = matrix_reference_component_storage
    block = 2
    value = 0.903
  []
  [spe2_layer_3_solid_storage]
    type = ConstantIC
    variable = matrix_reference_component_storage
    block = 3
    value = 0.889
  []
  [spe2_layer_4_solid_storage]
    type = ConstantIC
    variable = matrix_reference_component_storage
    block = 4
    value = 0.84
  []
  [spe2_layer_5_solid_storage]
    type = ConstantIC
    variable = matrix_reference_component_storage
    block = 5
    value = 0.87
  []
  [spe2_layer_6_solid_storage]
    type = ConstantIC
    variable = matrix_reference_component_storage
    block = 6
    value = 0.83
  []
  [spe2_layer_7_solid_storage]
    type = ConstantIC
    variable = matrix_reference_component_storage
    block = '7 107'
    value = 0.83
  []
  [spe2_layer_8_solid_storage]
    type = ConstantIC
    variable = matrix_reference_component_storage
    block = '8 108'
    value = 0.92
  []
  [spe2_layer_9_solid_storage]
    type = ConstantIC
    variable = matrix_reference_component_storage
    block = 9
    value = 0.86
  []
  [spe2_layer_10_solid_storage]
    type = ConstantIC
    variable = matrix_reference_component_storage
    block = 10
    value = 0.87
  []
  [spe2_layer_11_solid_storage]
    type = ConstantIC
    variable = matrix_reference_component_storage
    block = 11
    value = 0.88
  []
  [spe2_layer_12_solid_storage]
    type = ConstantIC
    variable = matrix_reference_component_storage
    block = 12
    value = 0.895
  []
  [spe2_layer_13_solid_storage]
    type = ConstantIC
    variable = matrix_reference_component_storage
    block = 13
    value = 0.88
  []
  [spe2_layer_14_solid_storage]
    type = ConstantIC
    variable = matrix_reference_component_storage
    block = 14
    value = 0.884
  []
  [spe2_layer_15_solid_storage]
    type = ConstantIC
    variable = matrix_reference_component_storage
    block = 15
    value = 0.843
  []
[]
