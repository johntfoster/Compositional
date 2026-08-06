[Mesh]
  type = GeneratedMesh
  dim = 2
  nx = 2
  ny = 2
  elem_type = QUAD9
[]

[Variables]
  [v0x]
  []
  [v0y]
  []
  [v1x]
  []
  [v1y]
  []
  [resistance_state]
  []
  [theta0]
  []
  [theta1]
  []
[]

[Functions]
  [v0x_exact]
    type = ParsedFunction
    expression = '1+0.1*x+0.05*y'
  []
  [v0y_exact]
    type = ParsedFunction
    expression = '-0.2+0.03*x'
  []
  [v1x_exact]
    type = ParsedFunction
    expression = '-0.1+0.02*y'
  []
  [v1y_exact]
    type = ParsedFunction
    expression = '0.4-0.04*x+0.02*y'
  []
  [resistance_state_exact]
    type = ParsedFunction
    expression = '0.3+0.05*x+0.02*y'
  []
  [theta0_exact]
    type = ParsedFunction
    expression = '300+2*x+y'
  []
  [theta1_exact]
    type = ParsedFunction
    expression = '350+x+3*y'
  []
  [b0x_exact]
    type = ParsedFunction
    expression = '-(250*x^3+275*x^2*y+5925*x^2+100*x*y^2+4320*x*y+255550*x+12*y^3+780*y^2+71000*y+2170000)/1000000'
  []
  [b0y_exact]
    type = ParsedFunction
    expression = '-(260*x^2+59*x*y+25310*x-18*y^2-5570*y-143500)/200000'
  []
  [b1x_exact]
    type = ParsedFunction
    expression = '-b0'
    symbol_names = b0
    symbol_values = b0x_exact
  []
  [b1y_exact]
    type = ParsedFunction
    expression = '-b0'
    symbol_names = b0
    symbol_values = b0y_exact
  []
  [dissipation_exact]
    type = ParsedFunction
    expression = '(2500*x^4+3500*x^3*y+95850*x^3+1825*x^2*y^2+90690*x^2*y+4015100*x^2+420*x*y^3+30540*x*y^2+1486100*x*y+37195000*x+36*y^4+3840*y^3+359900*y^2+17426000*y+281750000)/100000000'
  []
  [heat0_exact]
    type = ParsedFunction
    expression = '0.3*D'
    symbol_names = D
    symbol_values = dissipation_exact
  []
  [heat1_exact]
    type = ParsedFunction
    expression = '0.7*D'
    symbol_names = D
    symbol_values = dissipation_exact
  []
  [entropy_exact]
    type = ParsedFunction
    expression = '(17*x+16*y+3150)*(2500*x^4+3500*x^3*y+95850*x^3+1825*x^2*y^2+90690*x^2*y+4015100*x^2+420*x*y^3+30540*x*y^2+1486100*x*y+37195000*x+36*y^4+3840*y^3+359900*y^2+17426000*y+281750000)/(1000000000*(x+3*y+350)*(2*x+y+300))'
  []
  [zero]
    type = ConstantFunction
    value = 0
  []
[]

[ICs]
  [v0x_ic]
    type = FunctionIC
    variable = v0x
    function = v0x_exact
  []
  [v0y_ic]
    type = FunctionIC
    variable = v0y
    function = v0y_exact
  []
  [v1x_ic]
    type = FunctionIC
    variable = v1x
    function = v1x_exact
  []
  [v1y_ic]
    type = FunctionIC
    variable = v1y
    function = v1y_exact
  []
  [resistance_state_ic]
    type = FunctionIC
    variable = resistance_state
    function = resistance_state_exact
  []
  [theta0_ic]
    type = FunctionIC
    variable = theta0
    function = theta0_exact
  []
  [theta1_ic]
    type = FunctionIC
    variable = theta1
    function = theta1_exact
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
  [R00]
    type = ADParsedMaterial
    property_name = R00
    coupled_variables = resistance_state
    expression = '2+resistance_state^2'
  []
  [R01]
    type = ADParsedMaterial
    property_name = R01
    coupled_variables = resistance_state
    expression = '0.2+0.05*resistance_state'
  []
  [R10]
    type = ADParsedMaterial
    property_name = R10
    coupled_variables = resistance_state
    expression = '0.2+0.05*resistance_state'
  []
  [R11]
    type = ADParsedMaterial
    property_name = R11
    coupled_variables = resistance_state
    expression = '1.5+0.3*resistance_state'
  []
  [interaction]
    type = ADPairwisePhaseInteractionMaterial
    phase_velocity_components = 'v0x v0y v1x v1y'
    phase_temperature_names = 'temperature0 temperature1'
    pair_first = 0
    pair_second = 1
    pair_resistance_component_names = 'R00 R01 R10 R11'
    heating_fraction_to_first = 0.3
    phase_force_names = 'b0 b1'
    phase_mechanical_energy_supply_names = 'heat0 heat1'
  []
  [reference_jacobian]
    type = ADGenericConstantMaterial
    prop_names = solid_reference_J
    prop_values = 1
  []
  [exact_heating]
    type = ADGenericFunctionMaterial
    prop_names = 'heat0_exact_property heat1_exact_property'
    prop_values = 'heat0_exact heat1_exact'
  []
[]

[Kernels]
  [v0x_reaction]
    type = ADReaction
    variable = v0x
  []
  [v0x_target]
    type = ADBodyForce
    variable = v0x
    function = v0x_exact
  []
  [v0x_pair]
    type = ADPhaseMomentumVectorSourceTerm
    variable = v0x
    component = 0
    source_name = b0
  []
  [v0x_pair_mms]
    type = ADPhaseMomentumFunctionSourceTerm
    variable = v0x
    source = b0x_exact
    scale = -1
  []
  [v0y_reaction]
    type = ADReaction
    variable = v0y
  []
  [v0y_target]
    type = ADBodyForce
    variable = v0y
    function = v0y_exact
  []
  [v0y_pair]
    type = ADPhaseMomentumVectorSourceTerm
    variable = v0y
    component = 1
    source_name = b0
  []
  [v0y_pair_mms]
    type = ADPhaseMomentumFunctionSourceTerm
    variable = v0y
    source = b0y_exact
    scale = -1
  []
  [v1x_reaction]
    type = ADReaction
    variable = v1x
  []
  [v1x_target]
    type = ADBodyForce
    variable = v1x
    function = v1x_exact
  []
  [v1x_pair]
    type = ADPhaseMomentumVectorSourceTerm
    variable = v1x
    component = 0
    source_name = b1
  []
  [v1x_pair_mms]
    type = ADPhaseMomentumFunctionSourceTerm
    variable = v1x
    source = b1x_exact
    scale = -1
  []
  [v1y_reaction]
    type = ADReaction
    variable = v1y
  []
  [v1y_target]
    type = ADBodyForce
    variable = v1y
    function = v1y_exact
  []
  [v1y_pair]
    type = ADPhaseMomentumVectorSourceTerm
    variable = v1y
    component = 1
    source_name = b1
  []
  [v1y_pair_mms]
    type = ADPhaseMomentumFunctionSourceTerm
    variable = v1y
    source = b1y_exact
    scale = -1
  []
  [resistance_state_reaction]
    type = ADReaction
    variable = resistance_state
  []
  [resistance_state_target]
    type = ADBodyForce
    variable = resistance_state
    function = resistance_state_exact
  []
  [theta0_reaction]
    type = ADReaction
    variable = theta0
  []
  [theta0_target]
    type = ADBodyForce
    variable = theta0
    function = theta0_exact
  []
  [theta0_pair]
    type = ADReferenceEnergySourceTerm
    variable = theta0
    source_name = heat0
  []
  [theta0_pair_mms]
    type = ADReferenceEnergySourceTerm
    variable = theta0
    source_name = heat0_exact_property
    scale = -1
  []
  [theta1_reaction]
    type = ADReaction
    variable = theta1
  []
  [theta1_target]
    type = ADBodyForce
    variable = theta1
    function = theta1_exact
  []
  [theta1_pair]
    type = ADReferenceEnergySourceTerm
    variable = theta1
    source_name = heat1
  []
  [theta1_pair_mms]
    type = ADReferenceEnergySourceTerm
    variable = theta1
    source_name = heat1_exact_property
    scale = -1
  []
[]

[Postprocessors]
  [v0x_l2]
    type = ElementL2Error
    variable = v0x
    function = v0x_exact
  []
  [v0y_l2]
    type = ElementL2Error
    variable = v0y
    function = v0y_exact
  []
  [v1x_l2]
    type = ElementL2Error
    variable = v1x
    function = v1x_exact
  []
  [v1y_l2]
    type = ElementL2Error
    variable = v1y
    function = v1y_exact
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
[]

[Executioner]
  type = Steady
  solve_type = NEWTON
  nl_abs_tol = 1e-11
  nl_rel_tol = 1e-11
[]

[Outputs]
  csv = true
[]
