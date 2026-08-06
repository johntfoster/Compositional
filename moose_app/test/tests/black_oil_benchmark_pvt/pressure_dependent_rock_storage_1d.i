!include spe1_initial_pvt_1d.i

[Functions]
  [rock_oil_storage_exact]
    type = ParsedFunction
    expression = '18.814938586447532'
  []
[]

[Materials]
  [spe1_pvt]
    use_pressure_dependent_rock_porosity = true
    rock_reference_pressure = 4000
    rock_compressibility = 0.001
  []
[]

[Postprocessors]
  [rock_oil_storage_l2]
    type = ADMaterialScalarL2Error
    property = benchmark_black_oil_oil_reference_component_storage
    function = rock_oil_storage_exact
    execute_on = INITIAL
  []
[]

[Outputs]
  file_base = pressure_dependent_rock_storage_1d
[]
