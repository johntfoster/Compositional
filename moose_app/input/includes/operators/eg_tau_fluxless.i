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

[BCs]
  [tau_backbone_dirichlet]
    type = FunctionDirichletBC
    variable = tau
    boundary = ${all_boundaries}
    function = tau_exact
  []
[]
