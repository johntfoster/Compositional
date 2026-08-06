[Mesh]
  type = GeneratedMesh
  dim = 1
[]

[Materials]
  [constants]
    type = ADGenericConstantMaterial
    prop_names = 'dpsi_da dpsi_db'
    prop_values = '1 1'
  []
  [gradients]
    type = ADGenericConstantVectorMaterial
    prop_names = grad_a
    prop_values = '1 0 0'
  []
  [bad_gradient]
    type = ADThermodynamicPotentialGradientMaterial
    potential_derivative_names = 'dpsi_da dpsi_db'
    state_gradient_names = grad_a
    potential_gradient_name = bad_gradient
  []
[]

[Executioner]
  type = Steady
[]
