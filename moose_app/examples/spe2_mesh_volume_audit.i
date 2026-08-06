# Exact RZ physical-volume audit for the SPE2 Q2 finite-element mesh.
!include ../input/includes/mesh/spe2_rz_q2_quad9.i

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
  file_base = spe2_mesh_volume_audit
[]
