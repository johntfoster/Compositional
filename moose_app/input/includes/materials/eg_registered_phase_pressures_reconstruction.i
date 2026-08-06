[Materials]
  [pressure_oil_reconstructed]
    type = ADEGReconstructedScalarMaterial
    field_name = pressure_oil
    backbone = pressure_oil
    enrichment = pressure_oil_enr
  []
  [pressure_gas_reconstructed]
    type = ADEGReconstructedScalarMaterial
    field_name = pressure_gas
    backbone = pressure_gas
    enrichment = pressure_gas_enr
  []
  [pressure_water_reconstructed]
    type = ADEGReconstructedScalarMaterial
    field_name = pressure_water
    backbone = pressure_water
    enrichment = pressure_water_enr
  []
[]

[AuxKernels]
  [pressure_oil_total_aux]
    type = ADMaterialRealAux
    variable = pressure_oil_total
    property = pressure_oil_total
    execute_on = TIMESTEP_END
  []
  [pressure_gas_total_aux]
    type = ADMaterialRealAux
    variable = pressure_gas_total
    property = pressure_gas_total
    execute_on = TIMESTEP_END
  []
  [pressure_water_total_aux]
    type = ADMaterialRealAux
    variable = pressure_water_total
    property = pressure_water_total
    execute_on = TIMESTEP_END
  []
[]
