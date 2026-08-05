[Materials]
  [pressure_reconstructed]
    type = ADEGReconstructedScalarMaterial
    field_name = pressure
    backbone = pressure
    enrichment = pressure_enr
  []
[]

[AuxKernels]
  [pressure_total_aux]
    type = ADMaterialRealAux
    variable = pressure_total
    property = pressure_total
    execute_on = TIMESTEP_END
  []
[]
