[Kernels]
  [p_backbone_balance]
    type = ADEnrichedGalerkinScalarBalance
    variable = p
    enrichment = p_enr
    reference_component_storage_rate_name = summed_reference_component_storage_rate
    reference_flux_name = summed_reference_component_flux
    source_name = summed_reference_component_source
  []
  [p_enrichment_balance]
    type = ADEnrichedGalerkinScalarEnrichmentBalance
    variable = p_enr
    backbone = p
    reference_component_storage_rate_name = summed_reference_component_storage_rate
    source_name = summed_reference_component_source
  []
[]

[DGKernels]
  [p_enrichment_flux]
    type = ADEnrichedGalerkinFluxDG
    variable = p_enr
    reference_flux_name = summed_reference_component_flux
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
    reference_flux_name = summed_reference_component_flux
    mobility_name = p_mobility
    function = p_exact
    epsilon = ${eg_epsilon}
    sigma = ${eg_sigma}
  []
[]
