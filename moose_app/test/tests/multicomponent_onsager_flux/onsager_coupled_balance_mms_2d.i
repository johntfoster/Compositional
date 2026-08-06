mesh_nx := 2
mesh_ny := 2
all_boundaries = 'left right bottom top'
eg_epsilon := -1
eg_sigma := 16

!include ../../../input/includes/mesh/generated_2d_q2.i

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

[AuxVariables]
  [flux0_x]
    family = MONOMIAL
    order = FIRST
  []
  [flux0_y]
    family = MONOMIAL
    order = FIRST
  []
  [flux1_x]
    family = MONOMIAL
    order = FIRST
  []
  [flux1_y]
    family = MONOMIAL
    order = FIRST
  []
  [reference_flux_x]
    family = MONOMIAL
    order = FIRST
  []
  [reference_flux_y]
    family = MONOMIAL
    order = FIRST
  []
[]

[Functions]
  [mu0_exact]
    type = ParsedFunction
    expression = '1+x^2+0.5*y^2+0.4*x*y'
  []
  [mu1_exact]
    type = ParsedFunction
    expression = '2+0.25*x^2+1.5*y^2-0.2*x*y'
  []
  [zero]
    type = ConstantFunction
    value = 0
  []
  [flux0_x_exact]
    type = ParsedFunction
    expression = '-4.21*x-1.24*y'
  []
  [flux0_y_exact]
    type = ParsedFunction
    expression = '-0.935*x-2.19*y'
  []
  [flux1_x_exact]
    type = ParsedFunction
    expression = '-1.25*x-0.24*y'
  []
  [flux1_y_exact]
    type = ParsedFunction
    expression = '-0.135*x-3.51*y'
  []
  [reference_flux_x_exact]
    type = ParsedFunction
    expression = '5.46*x+1.48*y'
  []
  [reference_flux_y_exact]
    type = ParsedFunction
    expression = '1.07*x+5.70*y'
  []
[]

[ICs]
  [mu0_ic]
    type = ConstantIC
    variable = mu0
    value = 0
  []
  [mu1_ic]
    type = ConstantIC
    variable = mu1
    value = 0
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
    prop_values = '300 -6.4 -4.76'
  []
  [D00]
    type = ADGenericConstantRankTwoTensor
    tensor_name = D00
    tensor_values = '2 0.2 0  0.2 1.5 0  0 0 1'
  []
  [D01]
    type = ADGenericConstantRankTwoTensor
    tensor_name = D01
    # MOOSE RankTwoTensor input is column-major.
    tensor_values = '0.3 -0.05 0  0.1 0.2 0  0 0 0'
  []
  [D10]
    type = ADGenericConstantRankTwoTensor
    tensor_name = D10
    tensor_values = '0.3 0.1 0  -0.05 0.2 0  0 0 0'
  []
  [D11]
    type = ADGenericConstantRankTwoTensor
    tensor_name = D11
    tensor_values = '1.4 0.15 0  0.15 1.1 0  0 0 1'
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

[AuxKernels]
  [flux0_x]
    type = ADMaterialRealVectorValueAux
    variable = flux0_x
    property = flux0
    component = 0
  []
  [flux0_y]
    type = ADMaterialRealVectorValueAux
    variable = flux0_y
    property = flux0
    component = 1
  []
  [flux1_x]
    type = ADMaterialRealVectorValueAux
    variable = flux1_x
    property = flux1
    component = 0
  []
  [flux1_y]
    type = ADMaterialRealVectorValueAux
    variable = flux1_y
    property = flux1
    component = 1
  []
  [reference_flux_x]
    type = ADMaterialRealVectorValueAux
    variable = reference_flux_x
    property = reference_flux
    component = 0
  []
  [reference_flux_y]
    type = ADMaterialRealVectorValueAux
    variable = reference_flux_y
    property = reference_flux
    component = 1
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
  [flux0_x_l2]
    type = ElementL2Error
    variable = flux0_x
    function = flux0_x_exact
  []
  [flux0_y_l2]
    type = ElementL2Error
    variable = flux0_y
    function = flux0_y_exact
  []
  [flux1_x_l2]
    type = ElementL2Error
    variable = flux1_x
    function = flux1_x_exact
  []
  [flux1_y_l2]
    type = ElementL2Error
    variable = flux1_y
    function = flux1_y_exact
  []
  [reference_flux_x_l2]
    type = ElementL2Error
    variable = reference_flux_x
    function = reference_flux_x_exact
  []
  [reference_flux_y_l2]
    type = ElementL2Error
    variable = reference_flux_y
    function = reference_flux_y_exact
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
