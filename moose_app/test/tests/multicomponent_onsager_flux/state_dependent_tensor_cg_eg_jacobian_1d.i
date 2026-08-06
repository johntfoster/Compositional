[Mesh]
  type = GeneratedMesh
  dim = 1
  nx = 2
  elem_type = EDGE2
[]

[Variables]
  [state]
    family = LAGRANGE
    order = FIRST
  []
  [state_enrichment]
    family = MONOMIAL
    order = CONSTANT
  []
[]

[ICs]
  [state]
    type = ConstantIC
    variable = state
    value = 0.8
  []
  [state_enrichment]
    type = ConstantIC
    variable = state_enrichment
    value = 0.1
  []
[]

[BCs]
  [state_left]
    type = ADDirichletBC
    variable = state
    boundary = left
    value = 1
  []
  [state_right]
    type = ADDirichletBC
    variable = state
    boundary = right
    value = 1
  []
[]

[Functions]
  [state_exact]
    type = ConstantFunction
    value = 1
  []
  [zero]
    type = ConstantFunction
    value = 0
  []
  [flux0_exact]
    type = ParsedFunction
    expression = '-2.05*x'
  []
  [flux1_exact]
    type = ParsedFunction
    expression = '0.5*x'
  []
  [reference_flux_exact]
    type = ParsedFunction
    expression = '1.55*x'
  []
[]

[Materials]
  [reconstructed_state]
    type = ADEGReconstructedScalarMaterial
    backbone = state
    enrichment = state_enrichment
    field_name = state
  []
  [forces]
    type = ADGenericConstantVectorMaterial
    prop_names = 'force0 force1'
    prop_values = '1 0 0  -0.5 0 0'
  []
  [temperature]
    type = ADGenericConstantMaterial
    prop_names = temperature
    prop_values = 300
  []
  [D00]
    type = ADParsedMaterial
    property_name = D00
    material_property_names = state_total
    expression = '2+0.2*state_total^2'
  []
  [D01]
    type = ADGenericConstantMaterial
    prop_names = D01
    prop_values = 0.3
  []
  [D10]
    type = ADGenericConstantMaterial
    prop_names = D10
    prop_values = 0.3
  []
  [D11]
    type = ADParsedMaterial
    property_name = D11
    material_property_names = state_total
    expression = '1.5+0.1*state_total^2'
  []
  [onsager]
    type = ADMulticomponentOnsagerFluxMaterial
    transport_force_names = 'force0 force1'
    mobility_tensor_component_property_names = 'D00 D01 D10 D11'
    component_flux_names = 'flux0 flux1'
    reference_component_flux_name = reference_flux
    temperature_name = temperature
  []
  [enrichment_residual]
    type = ADParsedMaterial
    property_name = enrichment_residual
    coupled_variables = state_enrichment
    expression = state_enrichment
  []
  [state_restoring_residual]
    type = ADParsedMaterial
    property_name = state_restoring_residual
    material_property_names = state_total
    expression = 'state_total-1'
  []
[]

[Kernels]
  [state_restoring]
    type = ADMaterialPropertyResidual
    variable = state
    property = state_restoring_residual
  []
  [state_flux]
    type = ADReferenceComponentFluxTerm
    variable = state
    reference_flux_name = flux0
  []
  [state_enrichment_equation]
    type = ADMaterialPropertyResidual
    variable = state_enrichment
    property = enrichment_residual
  []
[]

[Postprocessors]
  [state_l2]
    type = ElementL2Error
    variable = state
    function = state_exact
  []
  [state_enrichment_l2]
    type = ElementL2Error
    variable = state_enrichment
    function = zero
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
  type = Steady
  solve_type = NEWTON
  nl_abs_tol = 1e-13
  nl_rel_tol = 1e-13
[]

[Outputs]
  csv = true
[]
