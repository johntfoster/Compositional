!include ../../../examples/spe1_case1_mesh.i

[Functions]
  [zero]
    type = ParsedFunction
    expression = '0'
  []
  [layer_1_permeability]
    type = ParsedFunction
    expression = '4.9346165e-13'
  []
  [layer_2_permeability]
    type = ParsedFunction
    expression = '4.9346165e-14'
  []
  [layer_3_permeability]
    type = ParsedFunction
    expression = '1.9738466e-13'
  []
  [porosity]
    type = ParsedFunction
    expression = '0.3'
  []
  [rock_reference_pressure]
    type = ParsedFunction
    expression = '101352.9322095696'
  []
  [rock_compressibility]
    type = ParsedFunction
    expression = '4.3511321319065047e-10'
  []
[]

[Postprocessors]
  [layer_1_permeability_l2]
    type = ADMaterialScalarL2Error
    block = '1 11'
    property = spe1_intrinsic_permeability
    function = layer_1_permeability
  []
  [layer_2_permeability_l2]
    type = ADMaterialScalarL2Error
    block = 2
    property = spe1_intrinsic_permeability
    function = layer_2_permeability
  []
  [layer_3_permeability_l2]
    type = ADMaterialScalarL2Error
    block = '3 13'
    property = spe1_intrinsic_permeability
    function = layer_3_permeability
  []
  [porosity_l2]
    type = ADMaterialScalarL2Error
    property = spe1_porosity
    function = porosity
  []
  [rock_reference_pressure_l2]
    type = ADMaterialScalarL2Error
    property = spe1_rock_reference_pressure
    function = rock_reference_pressure
  []
  [rock_compressibility_l2]
    type = ADMaterialScalarL2Error
    property = spe1_rock_compressibility
    function = rock_compressibility
  []
  [injector_completion_volume]
    type = VolumePostprocessor
    block = 11
  []
  [producer_completion_volume]
    type = VolumePostprocessor
    block = 13
  []
[]

[Outputs]
  csv = true
[]
