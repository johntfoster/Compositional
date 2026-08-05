[Materials]
  [equivalent_pressure_reconstructed]
    type = ADEGReconstructedScalarMaterial
    field_name = equivalent_pressure
    backbone = equivalent_pressure
    enrichment = equivalent_pressure_enr
  []
[]

[AuxKernels]
  [equivalent_pressure_total_aux]
    type = ADMaterialRealAux
    variable = equivalent_pressure_total
    property = equivalent_pressure_total
    execute_on = TIMESTEP_END
  []
[]
