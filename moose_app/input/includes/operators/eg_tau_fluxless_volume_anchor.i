[Kernels]
  [tau_backbone_residual]
    type = ADEnrichedGalerkinMaterialPropertyResidual
    variable = tau
    property = tau_evolution_residual
  []
  [tau_enrichment_residual]
    type = ADEnrichedGalerkinMaterialPropertyResidual
    variable = tau_enr
    property = tau_evolution_residual
    anchor_coefficient = ${eg_tau_anchor}
  []
[]
