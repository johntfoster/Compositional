mesh_nx := 8
saturation_order := FIRST
eg_epsilon := -1
eg_sigma := 12
all_boundaries = 'left right'

[Mesh]
  type = GeneratedMesh
  dim = 1
  nx = ${mesh_nx}
  xmin = 0
  xmax = 1
  elem_type = EDGE3
[]

[Variables]
  [saturation]
    family = LAGRANGE
    order = ${saturation_order}
  []
  [saturation_enrichment]
    family = MONOMIAL
    order = CONSTANT
  []
[]

[Functions]
  [saturation_exact]
    type = ParsedFunction
    expression = '0.5+0.2*sin(pi*x)'
  []
  [saturation_source]
    type = ParsedFunction
    expression = '0.2*pi*pi*sin(pi*x)'
  []
[]

[ICs]
  [saturation_ic]
    type = FunctionIC
    variable = saturation
    function = saturation_exact
  []
[]

[Materials]
  [saturation_reconstruction]
    type = ADEGReconstructedScalarMaterial
    backbone = saturation
    enrichment = saturation_enrichment
    field_name = saturation
  []
  [physical_capillary_diffusion]
    type = ADScalarDiffusionReferenceFluxMaterial
    backbone = saturation
    enrichment = saturation_enrichment
    diffusivity = 1
    mobility_name = saturation_physical_mobility
    reference_flux_name = saturation_physical_reference_flux
  []
[]

[Kernels]
  [saturation_backbone_balance]
    type = ADEnrichedGalerkinScalarBalance
    variable = saturation
    enrichment = saturation_enrichment
    time_coefficient = 0
    reference_flux_name = saturation_physical_reference_flux
    source_function = saturation_source
  []
  [saturation_enrichment_balance]
    type = ADEnrichedGalerkinScalarEnrichmentBalance
    variable = saturation_enrichment
    backbone = saturation
    time_coefficient = 0
    source_function = saturation_source
  []
[]

[DGKernels]
  [saturation_enrichment_flux]
    type = ADEnrichedGalerkinFluxDG
    variable = saturation_enrichment
    reference_flux_name = saturation_physical_reference_flux
    mobility_name = saturation_physical_mobility
    epsilon = ${eg_epsilon}
    sigma = ${eg_sigma}
  []
  [saturation_backbone_symmetry]
    type = ADEnrichedGalerkinSymmetryDG
    variable = saturation
    enrichment = saturation_enrichment
    mobility_name = saturation_physical_mobility
    epsilon = ${eg_epsilon}
  []
[]

[BCs]
  [saturation_backbone_dirichlet]
    type = FunctionDirichletBC
    variable = saturation
    boundary = ${all_boundaries}
    function = saturation_exact
  []
  [saturation_enrichment_weak_dirichlet]
    type = ADEnrichedGalerkinPenaltyBC
    variable = saturation_enrichment
    backbone = saturation
    boundary = ${all_boundaries}
    reference_flux_name = saturation_physical_reference_flux
    mobility_name = saturation_physical_mobility
    function = saturation_exact
    epsilon = ${eg_epsilon}
    sigma = ${eg_sigma}
  []
[]

[Postprocessors]
  [saturation_l2]
    type = ADMaterialScalarL2Error
    property = saturation_total
    function = saturation_exact
    execute_on = TIMESTEP_END
  []
  [saturation_gradient_l2]
    type = ADMaterialVectorL2Error
    property = saturation_total_gradient
    gradient_function = saturation_exact
    execute_on = TIMESTEP_END
  []
  [saturation_enrichment_l2]
    type = ElementL2Norm
    variable = saturation_enrichment
    execute_on = TIMESTEP_END
  []
[]

[Executioner]
  type = Transient
  scheme = bdf2
  dt = 1
  num_steps = 1
  nl_abs_tol = 1e-12
  nl_rel_tol = 1e-12
  solve_type = NEWTON
[]

[Outputs]
  csv = true
  console = false
[]
