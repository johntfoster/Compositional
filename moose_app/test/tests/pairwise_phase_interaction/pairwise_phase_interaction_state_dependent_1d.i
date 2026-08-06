[Mesh]
  type = GeneratedMesh
  dim = 1
  nx = 2
[]

[Variables]
  [v0]
  []
  [v1]
  []
  [resistance_state]
  []
  [theta0]
  []
  [theta1]
  []
[]

[ICs]
  [v0_ic]
    type = ConstantIC
    variable = v0
    value = 1.5
  []
  [v1_ic]
    type = ConstantIC
    variable = v1
    value = 0.1
  []
  [resistance_state_ic]
    type = ConstantIC
    variable = resistance_state
    value = 0.4
  []
  [theta0_ic]
    type = ConstantIC
    variable = theta0
    value = 295
  []
  [theta1_ic]
    type = ConstantIC
    variable = theta1
    value = 395
  []
[]

[Functions]
  [v0_exact]
    type = ConstantFunction
    value = 2
  []
  [v1_exact]
    type = ConstantFunction
    value = 0
  []
  [resistance_state_exact]
    type = ConstantFunction
    value = 0.5
  []
  [theta0_exact]
    type = ConstantFunction
    value = 300
  []
  [theta1_exact]
    type = ConstantFunction
    value = 400
  []
  [momentum_source]
    type = ConstantFunction
    value = 4.5
  []
  [zero]
    type = ConstantFunction
    value = 0
  []
  [dissipation_exact]
    type = ConstantFunction
    value = 9
  []
  [entropy_exact]
    type = ConstantFunction
    value = 0.024375
  []
  [minimum_eigenvalue_exact]
    type = ConstantFunction
    value = 2.25
  []
[]

[Materials]
  [temperature0]
    type = ADParsedMaterial
    property_name = temperature0
    coupled_variables = theta0
    expression = theta0
  []
  [temperature1]
    type = ADParsedMaterial
    property_name = temperature1
    coupled_variables = theta1
    expression = theta1
  []
  [resistance]
    type = ADParsedMaterial
    property_name = resistance00
    coupled_variables = resistance_state
    expression = '2+resistance_state^2'
  []
  [interaction]
    type = ADPairwisePhaseInteractionMaterial
    phase_velocity_components = 'v0 v1'
    phase_temperature_names = 'temperature0 temperature1'
    pair_first = 0
    pair_second = 1
    pair_resistance_component_names = resistance00
    heating_fraction_to_first = 0.25
    phase_force_names = 'b0 b1'
    phase_mechanical_energy_supply_names = 'e0_mech e1_mech'
  []
  [reference_jacobian]
    type = ADGenericConstantMaterial
    prop_names = solid_reference_J
    prop_values = 1
  []
  [v1_residual]
    type = ADParsedMaterial
    property_name = v1_residual
    coupled_variables = v1
    expression = v1
  []
  [resistance_state_residual]
    type = ADParsedMaterial
    property_name = resistance_state_residual
    coupled_variables = resistance_state
    expression = 'resistance_state-0.5'
  []
  [theta0_restoring]
    type = ADParsedMaterial
    property_name = theta0_restoring
    coupled_variables = theta0
    expression = 'theta0-300+2.25'
  []
  [theta1_restoring]
    type = ADParsedMaterial
    property_name = theta1_restoring
    coupled_variables = theta1
    expression = 'theta1-400+6.75'
  []
[]

[Kernels]
  [v0_pair_force]
    type = ADPhaseMomentumVectorSourceTerm
    variable = v0
    component = 0
    source_name = b0
    solid_jacobian_name = solid_reference_J
  []
  [v0_external_force]
    type = ADPhaseMomentumFunctionSourceTerm
    variable = v0
    source = momentum_source
    solid_jacobian_name = solid_reference_J
  []
  [v1_equation]
    type = ADMaterialPropertyResidual
    variable = v1
    property = v1_residual
  []
  [resistance_state_equation]
    type = ADMaterialPropertyResidual
    variable = resistance_state
    property = resistance_state_residual
  []
  [theta0_restoring_equation]
    type = ADMaterialPropertyResidual
    variable = theta0
    property = theta0_restoring
  []
  [theta0_pair_heating]
    type = ADReferenceEnergySourceTerm
    variable = theta0
    source_name = e0_mech
    solid_jacobian_name = solid_reference_J
  []
  [theta1_restoring_equation]
    type = ADMaterialPropertyResidual
    variable = theta1
    property = theta1_restoring
  []
  [theta1_pair_heating]
    type = ADReferenceEnergySourceTerm
    variable = theta1
    source_name = e1_mech
    solid_jacobian_name = solid_reference_J
  []
[]

[Postprocessors]
  [v0_l2]
    type = ElementL2Error
    variable = v0
    function = v0_exact
  []
  [v1_l2]
    type = ElementL2Error
    variable = v1
    function = v1_exact
  []
  [resistance_state_l2]
    type = ElementL2Error
    variable = resistance_state
    function = resistance_state_exact
  []
  [theta0_l2]
    type = ElementL2Error
    variable = theta0
    function = theta0_exact
  []
  [theta1_l2]
    type = ElementL2Error
    variable = theta1
    function = theta1_exact
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
  solve_type = NEWTON
  nl_abs_tol = 1e-12
  nl_rel_tol = 1e-12
[]

[Outputs]
  csv = true
[]
