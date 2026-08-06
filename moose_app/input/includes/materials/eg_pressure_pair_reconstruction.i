[Materials]
  [pressure0_reconstructed]
    type = ADEGReconstructedScalarMaterial
    field_name = pressure0
    backbone = pressure0
    enrichment = pressure0_enr
  []
  [pressure1_reconstructed]
    type = ADEGReconstructedScalarMaterial
    field_name = pressure1
    backbone = pressure1
    enrichment = pressure1_enr
  []
[]

[AuxKernels]
  [pressure0_total_aux]
    type = ADMaterialRealAux
    variable = pressure0_total
    property = pressure0_total
    execute_on = TIMESTEP_END
  []
  [pressure1_total_aux]
    type = ADMaterialRealAux
    variable = pressure1_total
    property = pressure1_total
    execute_on = TIMESTEP_END
  []
[]
