# Regression audit for the published SPE2 radial and vertical mesh dimensions.
!include ../../../input/includes/mesh/spe2_rz_q2_quad9.i

[Problem]
  solve = false
[]

[Functions]
  [one]
    type = ConstantFunction
    value = 1
  []
[]

[Postprocessors]
  [num_elements]
    type = NumElements
    execute_on = INITIAL
  []
  [num_nodes]
    type = NumNodes
    execute_on = INITIAL
  []
  [physical_annular_volume]
    type = FunctionElementIntegral
    function = one
    execute_on = INITIAL
  []
  [completion_7_volume]
    type = FunctionElementIntegral
    function = one
    block = 107
    execute_on = INITIAL
  []
  [completion_8_volume]
    type = FunctionElementIntegral
    function = one
    block = 108
    execute_on = INITIAL
  []
[]

[Executioner]
  type = Steady
[]

[Outputs]
  csv = true
[]
