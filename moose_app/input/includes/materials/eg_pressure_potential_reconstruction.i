[Materials]
  [pressure_potential_reconstructed]
    type = ADEGReconstructedScalarMaterial
    field_name = pressure_potential
    backbone = pressure_potential
    enrichment = pressure_potential_enr
  []
[]

[AuxKernels]
  [pressure_potential_total_aux]
    type = ADMaterialRealAux
    variable = pressure_potential_total
    property = pressure_potential_total
    execute_on = TIMESTEP_END
  []
[]
