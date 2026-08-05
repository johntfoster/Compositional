[Materials]
  [p_reconstructed]
    type = ADEGReconstructedScalarMaterial
    field_name = p
    backbone = p
    enrichment = p_enr
  []
  [tau_reconstructed]
    type = ADEGReconstructedScalarMaterial
    field_name = tau
    backbone = tau
    enrichment = tau_enr
  []
[]

[AuxKernels]
  [p_total_aux]
    type = ADMaterialRealAux
    variable = p_total
    property = p_total
    execute_on = TIMESTEP_END
  []
  [tau_total_aux]
    type = ADMaterialRealAux
    variable = tau_total
    property = tau_total
    execute_on = TIMESTEP_END
  []
[]
