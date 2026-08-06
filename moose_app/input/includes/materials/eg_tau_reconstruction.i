[Materials]
  [tau_reconstructed]
    type = ADEGReconstructedScalarMaterial
    field_name = tau
    backbone = tau
    enrichment = tau_enr
  []
[]

[AuxKernels]
  [tau_total_aux]
    type = ADMaterialRealAux
    variable = tau_total
    property = tau_total
    execute_on = TIMESTEP_END
  []
[]
