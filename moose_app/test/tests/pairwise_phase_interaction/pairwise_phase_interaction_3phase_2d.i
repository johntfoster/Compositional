[Mesh]
  type = GeneratedMesh
  dim = 2
  nx = 1
  ny = 1
[]

[Problem]
  solve = false
[]

[Functions]
  [force0_exact]
    type = ParsedFunction
    expression = '-4*x-2*y'
  []
  [force1_exact]
    type = ParsedFunction
    expression = '3*x+11*y'
  []
  [force2_exact]
    type = ParsedFunction
    expression = 'x-9*y'
  []
  [zero]
    type = ConstantFunction
    value = 0
  []
  [dissipation_exact]
    type = ConstantFunction
    value = 40
  []
  [entropy_exact]
    type = ConstantFunction
    value = 0.0969
  []
  [minimum_eigenvalue_exact]
    type = ConstantFunction
    value = 1
  []
[]

[Materials]
  [phase_data]
    type = ADGenericConstantMaterial
    prop_names = 'theta0 theta1 theta2'
    prop_values = '300 400 500'
  []
  [phase_velocities]
    type = ADGenericConstantVectorMaterial
    prop_names = 'v0 v1 v2'
    prop_values = '2 1 0  0 -1 0  -1 2 0'
  []
  [resistance01]
    type = ADGenericConstantRankTwoTensor
    tensor_name = resistance01
    tensor_values = '2 0 0  0 1 0  0 0 3'
  []
  [resistance12]
    type = ADGenericConstantRankTwoTensor
    tensor_name = resistance12
    tensor_values = '1 0 0  0 3 0  0 0 2'
  []
  [interaction]
    type = ADPairwisePhaseInteractionMaterial
    phase_velocity_names = 'v0 v1 v2'
    phase_temperature_names = 'theta0 theta1 theta2'
    pair_first = '0 1'
    pair_second = '1 2'
    pair_resistance_tensor_names = 'resistance01 resistance12'
    heating_fraction_to_first = '0.25 0.6'
    phase_force_names = 'b0 b1 b2'
    phase_mechanical_energy_supply_names = 'e0_mech e1_mech e2_mech'
    resistance_tensors_are_constant = true
  []
[]

[Postprocessors]
  [force0_l2]
    type = ADMaterialVectorL2Error
    property = b0
    gradient_function = force0_exact
  []
  [force1_l2]
    type = ADMaterialVectorL2Error
    property = b1
    gradient_function = force1_exact
  []
  [force2_l2]
    type = ADMaterialVectorL2Error
    property = b2
    gradient_function = force2_exact
  []
  [momentum_cancellation_l2]
    type = ADMaterialVectorL2Error
    property = pairwise_interaction_momentum_cancellation
    gradient_function = zero
  []
  [energy_cancellation_l2]
    type = ADMaterialScalarL2Error
    property = pairwise_interaction_energy_cancellation
    function = zero
  []
  [dissipation_l2]
    type = ADMaterialScalarL2Error
    property = pairwise_interaction_total_drag_dissipation
    function = dissipation_exact
  []
  [entropy_l2]
    type = ADMaterialScalarL2Error
    property = pairwise_interaction_entropy_production
    function = entropy_exact
  []
  [minimum_eigenvalue_l2]
    type = ADMaterialScalarL2Error
    property = pairwise_interaction_minimum_resistance_eigenvalue
    function = minimum_eigenvalue_exact
  []
[]

[Executioner]
  type = Steady
[]

[Outputs]
  csv = true
[]
