[Kernels]
  [p_backbone_balance]
    type = ADEnrichedGalerkinScalarBalance
    variable = p
    enrichment = p_enr
    time_coefficient = 0
    reference_flux_name = p_reference_flux
    source_function = pressure_source
  []
  [p_enrichment_balance]
    type = ADEnrichedGalerkinScalarEnrichmentBalance
    variable = p_enr
    backbone = p
    time_coefficient = 0
    source_function = pressure_source
  []
[]

[DGKernels]
  [p_enrichment_flux]
    type = ADEnrichedGalerkinFluxDG
    variable = p_enr
    reference_flux_name = p_reference_flux
    mobility_name = p_mobility
    epsilon = ${eg_epsilon}
    sigma = ${eg_sigma}
  []
  [p_backbone_symmetry]
    type = ADEnrichedGalerkinSymmetryDG
    variable = p
    enrichment = p_enr
    mobility_name = p_mobility
    epsilon = ${eg_epsilon}
  []
[]

[BCs]
  [p_backbone_dirichlet]
    type = FunctionDirichletBC
    variable = p
    boundary = ${all_boundaries}
    function = p_exact
  []
  [p_enrichment_weak_dirichlet]
    type = ADEnrichedGalerkinPenaltyBC
    variable = p_enr
    backbone = p
    boundary = ${all_boundaries}
    reference_flux_name = p_reference_flux
    mobility_name = p_mobility
    function = p_exact
    epsilon = ${eg_epsilon}
    sigma = ${eg_sigma}
  []
[]
