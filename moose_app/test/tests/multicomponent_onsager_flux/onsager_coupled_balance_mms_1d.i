mesh_nx := 3
all_boundaries = 'left right'
eg_epsilon := -1
eg_sigma := 12

!include ../../../input/includes/mesh/generated_1d_q2.i

[Variables]
  [mu0]
    family = LAGRANGE
    order = SECOND
  []
  [mu0_enr]
    family = MONOMIAL
    order = CONSTANT
  []
  [mu1]
    family = LAGRANGE
    order = SECOND
  []
  [mu1_enr]
    family = MONOMIAL
    order = CONSTANT
  []
[]

[Functions]
  [mu0_exact]
    type = ParsedFunction
    expression = '1+x^2'
  []
  [mu1_exact]
    type = ParsedFunction
    expression = '2+0.5*x^2'
  []
  [flux0_exact]
    type = ParsedFunction
    expression = '-2.15*x^2'
  []
  [flux1_exact]
    type = ParsedFunction
    expression = '-1.05*x^2'
  []
  [reference_flux_exact]
    type = ParsedFunction
    expression = '3.2*x^2'
  []
[]

[Materials]
  [mu0_reconstruction]
    type = ADEGReconstructedScalarMaterial
    backbone = mu0
    enrichment = mu0_enr
    field_name = mu0
  []
  [mu1_reconstruction]
    type = ADEGReconstructedScalarMaterial
    backbone = mu1
    enrichment = mu1_enr
    field_name = mu1
  []
  [temperature_and_sources]
    type = ADGenericConstantMaterial
    prop_names = 'temperature source0 source1'
    prop_values = '300 -4.3 -2.1'
  []
  [D00]
    type = ADGenericConstantRankTwoTensor
    tensor_name = D00
    tensor_values = '2 0 0  0 1 0  0 0 1'
  []
  [D01]
    type = ADGenericConstantRankTwoTensor
    tensor_name = D01
    tensor_values = '0.3 0 0  0 0 0  0 0 0'
  []
  [D10]
    type = ADGenericConstantRankTwoTensor
    tensor_name = D10
    tensor_values = '0.3 0 0  0 0 0  0 0 0'
  []
  [D11]
    type = ADGenericConstantRankTwoTensor
    tensor_name = D11
    tensor_values = '1.5 0 0  0 1 0  0 0 1'
  []
  [onsager]
    type = ADMulticomponentOnsagerFluxMaterial
    transport_force_names = 'mu0_total_gradient mu1_total_gradient'
    mobility_tensor_property_names = 'D00 D01 D10 D11'
    component_flux_names = 'flux0 flux1'
    reference_component_flux_name = reference_flux
    temperature_name = temperature
  []
[]

[Kernels]
  [mu0_backbone_balance]
    type = ADEnrichedGalerkinScalarBalance
    variable = mu0
    enrichment = mu0_enr
    time_coefficient = 0
    reference_flux_name = flux0
    source_name = source0
  []
  [mu0_enrichment_balance]
    type = ADEnrichedGalerkinScalarEnrichmentBalance
    variable = mu0_enr
    backbone = mu0
    time_coefficient = 0
    source_name = source0
  []
  [mu1_backbone_balance]
    type = ADEnrichedGalerkinScalarBalance
    variable = mu1
    enrichment = mu1_enr
    time_coefficient = 0
    reference_flux_name = flux1
    source_name = source1
  []
  [mu1_enrichment_balance]
    type = ADEnrichedGalerkinScalarEnrichmentBalance
    variable = mu1_enr
    backbone = mu1
    time_coefficient = 0
    source_name = source1
  []
[]

[DGKernels]
  [mu0_diagonal_flux]
    type = ADEnrichedGalerkinFluxDG
    variable = mu0_enr
    reference_flux_name = flux0
    mobility_name = D00
    epsilon = ${eg_epsilon}
    sigma = ${eg_sigma}
  []
  [mu0_cross_flux]
    type = ADEnrichedGalerkinCrossFluxDG
    variable = mu0_enr
    column_enrichment = mu1_enr
    cross_mobility_name = D01
    epsilon = ${eg_epsilon}
    sigma = ${eg_sigma}
  []
  [mu0_diagonal_symmetry]
    type = ADEnrichedGalerkinSymmetryDG
    variable = mu0
    enrichment = mu0_enr
    mobility_name = D00
    epsilon = ${eg_epsilon}
  []
  [mu0_cross_symmetry]
    type = ADEnrichedGalerkinCrossSymmetryDG
    variable = mu0
    column_enrichment = mu1_enr
    cross_mobility_name = D01
    epsilon = ${eg_epsilon}
  []
  [mu1_diagonal_flux]
    type = ADEnrichedGalerkinFluxDG
    variable = mu1_enr
    reference_flux_name = flux1
    mobility_name = D11
    epsilon = ${eg_epsilon}
    sigma = ${eg_sigma}
  []
  [mu1_cross_flux]
    type = ADEnrichedGalerkinCrossFluxDG
    variable = mu1_enr
    column_enrichment = mu0_enr
    cross_mobility_name = D10
    epsilon = ${eg_epsilon}
    sigma = ${eg_sigma}
  []
  [mu1_diagonal_symmetry]
    type = ADEnrichedGalerkinSymmetryDG
    variable = mu1
    enrichment = mu1_enr
    mobility_name = D11
    epsilon = ${eg_epsilon}
  []
  [mu1_cross_symmetry]
    type = ADEnrichedGalerkinCrossSymmetryDG
    variable = mu1
    column_enrichment = mu0_enr
    cross_mobility_name = D10
    epsilon = ${eg_epsilon}
  []
[]

[BCs]
  [mu0_backbone]
    type = FunctionDirichletBC
    variable = mu0
    boundary = ${all_boundaries}
    function = mu0_exact
  []
  [mu1_backbone]
    type = FunctionDirichletBC
    variable = mu1
    boundary = ${all_boundaries}
    function = mu1_exact
  []
  [mu0_diagonal_penalty]
    type = ADEnrichedGalerkinPenaltyBC
    variable = mu0_enr
    backbone = mu0
    boundary = ${all_boundaries}
    reference_flux_name = flux0
    mobility_name = D00
    function = mu0_exact
    epsilon = ${eg_epsilon}
    sigma = ${eg_sigma}
  []
  [mu0_cross_penalty]
    type = ADEnrichedGalerkinCrossPenaltyBC
    variable = mu0_enr
    column_backbone = mu1
    column_enrichment = mu1_enr
    boundary = ${all_boundaries}
    cross_mobility_name = D01
    function = mu1_exact
    epsilon = ${eg_epsilon}
    sigma = ${eg_sigma}
  []
  [mu1_diagonal_penalty]
    type = ADEnrichedGalerkinPenaltyBC
    variable = mu1_enr
    backbone = mu1
    boundary = ${all_boundaries}
    reference_flux_name = flux1
    mobility_name = D11
    function = mu1_exact
    epsilon = ${eg_epsilon}
    sigma = ${eg_sigma}
  []
  [mu1_cross_penalty]
    type = ADEnrichedGalerkinCrossPenaltyBC
    variable = mu1_enr
    column_backbone = mu0
    column_enrichment = mu0_enr
    boundary = ${all_boundaries}
    cross_mobility_name = D10
    function = mu0_exact
    epsilon = ${eg_epsilon}
    sigma = ${eg_sigma}
  []
[]

[Postprocessors]
  [mu0_total_l2]
    type = ADMaterialScalarL2Error
    property = mu0_total
    function = mu0_exact
  []
  [mu1_total_l2]
    type = ADMaterialScalarL2Error
    property = mu1_total
    function = mu1_exact
  []
  [mu0_gradient_l2]
    type = ADMaterialVectorL2Error
    property = mu0_total_gradient
    gradient_function = mu0_exact
  []
  [mu1_gradient_l2]
    type = ADMaterialVectorL2Error
    property = mu1_total_gradient
    gradient_function = mu1_exact
  []
  [mu0_enrichment_l2]
    type = ElementL2Norm
    variable = mu0_enr
  []
  [mu1_enrichment_l2]
    type = ElementL2Norm
    variable = mu1_enr
  []
  [flux0_l2]
    type = ADMaterialVectorL2Error
    property = flux0
    gradient_function = flux0_exact
  []
  [flux1_l2]
    type = ADMaterialVectorL2Error
    property = flux1
    gradient_function = flux1_exact
  []
  [reference_flux_l2]
    type = ADMaterialVectorL2Error
    property = reference_flux
    gradient_function = reference_flux_exact
  []
[]

[Executioner]
  type = Transient
  solve_type = NEWTON
  dt = 1
  num_steps = 1
  nl_abs_tol = 1e-12
  nl_rel_tol = 1e-12
[]

[Outputs]
  csv = true
[]
