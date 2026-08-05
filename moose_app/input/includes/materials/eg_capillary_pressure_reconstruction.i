[Materials]
  [capillary_pressure_reconstructed]
    type = ADEGReconstructedScalarMaterial
    field_name = capillary_pressure
    backbone = capillary_pressure
    enrichment = capillary_pressure_enr
  []
[]

[AuxKernels]
  [capillary_pressure_total_aux]
    type = ADMaterialRealAux
    variable = capillary_pressure_total
    property = capillary_pressure_total
    execute_on = TIMESTEP_END
  []
[]
