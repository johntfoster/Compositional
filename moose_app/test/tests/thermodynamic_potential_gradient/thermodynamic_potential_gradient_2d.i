[Mesh]
  [mesh]
    type = GeneratedMeshGenerator
    dim = 2
    nx = 1
    ny = 1
    elem_type = QUAD9
  []
[]

[Problem]
  solve = false
[]

[Variables]
  [state_a]
    family = LAGRANGE
    order = SECOND
  []
  [state_b]
    family = LAGRANGE
    order = SECOND
  []
[]

[Functions]
  [state_a]
    type = ParsedFunction
    expression = 'x+2*y'
  []
  [state_b]
    type = ParsedFunction
    expression = '3*x-y'
  []
  [expected_potential]
    type = ParsedFunction
    expression = '1.5*x+6.5*y'
  []
[]

[ICs]
  [state_a]
    type = FunctionIC
    variable = state_a
    function = state_a
  []
  [state_b]
    type = FunctionIC
    variable = state_b
    function = state_b
  []
[]

[Materials]
  [state_a_reconstruction]
    type = ADEGReconstructedScalarMaterial
    backbone = state_a
    field_name = test_state_a
  []
  [state_b_reconstruction]
    type = ADEGReconstructedScalarMaterial
    backbone = state_b
    field_name = test_state_b
  []
  [potential_derivatives]
    type = ADGenericConstantMaterial
    prop_names = 'test_dpsi_da test_dpsi_db'
    prop_values = '2 -0.5'
  []
  [explicit_gradient]
    type = ADGenericConstantVectorMaterial
    prop_names = test_explicit_gradient
    prop_values = '1 2 0'
  []
  [potential_gradient]
    type = ADThermodynamicPotentialGradientMaterial
    potential_derivative_names = 'test_dpsi_da test_dpsi_db'
    state_gradient_names = 'test_state_a_total_gradient test_state_b_total_gradient'
    direct_gradient_name = test_explicit_gradient
    potential_gradient_name = test_potential_gradient
  []
[]

[Postprocessors]
  [potential_gradient_l2]
    type = ADMaterialVectorL2Error
    property = test_potential_gradient
    gradient_function = expected_potential
  []
[]

[Executioner]
  type = Steady
[]

[Outputs]
  csv = true
[]
