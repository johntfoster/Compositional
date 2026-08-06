[Mesh]
  type = GeneratedMesh
  dim = 3
  nx = 1
  ny = 1
  nz = 1
  # Production 3-D policy: quadratic simplex geometry (CG variables below).
  elem_type = TET10
[]

[Variables]
  [v0x]
  []
  [v0y]
  []
  [v0z]
  []
  [v1x]
  []
  [v1y]
  []
  [v1z]
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
    expression = '1+0.05*x+0.02*y'
  []
  [v0y_exact]
    type = ParsedFunction
    expression = '-0.2+0.03*x+0.01*z'
  []
  [v0z_exact]
    type = ParsedFunction
    expression = '0.3+0.02*y'
  []
  [v1x_exact]
    type = ParsedFunction
    expression = '-0.1+0.01*y+0.02*z'
  []
  [v1y_exact]
    type = ParsedFunction
    expression = '0.4-0.02*x+0.01*y'
  []
  [v1z_exact]
    type = ParsedFunction
    expression = '-0.2+0.01*x-0.01*z'
  []
  [resistance_state_exact]
    type = ParsedFunction
    expression = '0.25+0.03*x+0.02*y+0.01*z'
  []
  [theta0_exact]
    type = ParsedFunction
    expression = '300+2*x+y+z'
  []
  [theta1_exact]
    type = ParsedFunction
    expression = '360+x+2*y+3*z'
  []
  [b0x_exact]
    type = ParsedFunction
    expression = '-(45*x^3+69*x^2*y+12*x^2*z+1740*x^2+32*x*y^2+2*x*y*z+1970*x*y-7*x*z^2+610*x*z+124125*x+4*y^3-4*y^2*z+540*y^2-7*y*z^2+290*y*z+31625*y-2*z^3+10*z^2-34250*z+2233750)/1000000'
  []
  [b0y_exact]
    type = ParsedFunction
    expression = '-(15*x^2+7*x*y+8*x*z+3905*x-2*y^2+y*z-765*y+z^2+655*z-39000)/50000'
  []
  [b0z_exact]
    type = ParsedFunction
    expression = '(3*x^2-4*x*y-2*x*z+425*x-4*y^2-4*y*z-2520*y-z^2-1255*z-61950)/100000'
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
  [b1z_exact]
    type = ParsedFunction
    expression = '-b0'
    symbol_names = b0
    symbol_values = b0z_exact
  []
  [dissipation_exact]
    type = ParsedFunction
    expression = '(225*x^4+390*x^3*y-30*x^3*z+15180*x^3+229*x^2*y^2-116*x^2*y*z+19480*x^2*y-59*x^2*z^2+1940*x^2*z+1187275*x^2+52*x*y^3-82*x*y^2*z+7890*x*y^2-46*x*y*z^2-1540*x*y*z+304250*x*y+4*x*z^3-1670*x*z^2-234200*x*z+15404500*x+4*y^4-12*y^3*z+1100*y^3+y^2*z^2-1170*y^2*z+161125*y^2+12*y*z^3-1280*y*z^2-42900*y*z+9909500*y+4*z^4-210*z^3+94550*z^2-8554000*z+323487500)/100000000'
  []
  [heat0_exact]
    type = ParsedFunction
    expression = '0.4*D'
    symbol_names = D
    symbol_values = dissipation_exact
  []
  [heat1_exact]
    type = ParsedFunction
    expression = '0.6*D'
    symbol_names = D
    symbol_values = dissipation_exact
  []
  [entropy_exact]
    type = ParsedFunction
    expression = '(8*x+7*y+9*z+1620)*(225*x^4+390*x^3*y-30*x^3*z+15180*x^3+229*x^2*y^2-116*x^2*y*z+19480*x^2*y-59*x^2*z^2+1940*x^2*z+1187275*x^2+52*x*y^3-82*x*y^2*z+7890*x*y^2-46*x*y*z^2-1540*x*y*z+304250*x*y+4*x*z^3-1670*x*z^2-234200*x*z+15404500*x+4*y^4-12*y^3*z+1100*y^3+y^2*z^2-1170*y^2*z+161125*y^2+12*y*z^3-1280*y*z^2-42900*y*z+9909500*y+4*z^4-210*z^3+94550*z^2-8554000*z+323487500)/(500000000*(x+2*y+3*z+360)*(2*x+y+z+300))'
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
  [v0z_ic]
    type = FunctionIC
    variable = v0z
    function = v0z_exact
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
  [v1z_ic]
    type = FunctionIC
    variable = v1z
    function = v1z_exact
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
    type = ADGenericConstantMaterial
    prop_names = R01
    prop_values = 0.1
  []
  [R02]
    type = ADGenericConstantMaterial
    prop_names = R02
    prop_values = 0.05
  []
  [R10]
    type = ADGenericConstantMaterial
    prop_names = R10
    prop_values = 0.1
  []
  [R11]
    type = ADParsedMaterial
    property_name = R11
    coupled_variables = resistance_state
    expression = '1.5+0.2*resistance_state'
  []
  [R12]
    type = ADGenericConstantMaterial
    prop_names = R12
    prop_values = 0.08
  []
  [R20]
    type = ADGenericConstantMaterial
    prop_names = R20
    prop_values = 0.05
  []
  [R21]
    type = ADGenericConstantMaterial
    prop_names = R21
    prop_values = 0.08
  []
  [R22]
    type = ADParsedMaterial
    property_name = R22
    coupled_variables = resistance_state
    expression = '1.2+0.1*resistance_state'
  []
  [interaction]
    type = ADPairwisePhaseInteractionMaterial
    phase_velocity_components = 'v0x v0y v0z v1x v1y v1z'
    phase_temperature_names = 'temperature0 temperature1'
    pair_first = 0
    pair_second = 1
    pair_resistance_component_names = 'R00 R01 R02 R10 R11 R12 R20 R21 R22'
    heating_fraction_to_first = 0.4
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
  [v0x_mms]
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
  [v0y_mms]
    type = ADPhaseMomentumFunctionSourceTerm
    variable = v0y
    source = b0y_exact
    scale = -1
  []
  [v0z_reaction]
    type = ADReaction
    variable = v0z
  []
  [v0z_target]
    type = ADBodyForce
    variable = v0z
    function = v0z_exact
  []
  [v0z_pair]
    type = ADPhaseMomentumVectorSourceTerm
    variable = v0z
    component = 2
    source_name = b0
  []
  [v0z_mms]
    type = ADPhaseMomentumFunctionSourceTerm
    variable = v0z
    source = b0z_exact
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
  [v1x_mms]
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
  [v1y_mms]
    type = ADPhaseMomentumFunctionSourceTerm
    variable = v1y
    source = b1y_exact
    scale = -1
  []
  [v1z_reaction]
    type = ADReaction
    variable = v1z
  []
  [v1z_target]
    type = ADBodyForce
    variable = v1z
    function = v1z_exact
  []
  [v1z_pair]
    type = ADPhaseMomentumVectorSourceTerm
    variable = v1z
    component = 2
    source_name = b1
  []
  [v1z_mms]
    type = ADPhaseMomentumFunctionSourceTerm
    variable = v1z
    source = b1z_exact
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
  [theta0_mms]
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
  [theta1_mms]
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
  [v0z_l2]
    type = ElementL2Error
    variable = v0z
    function = v0z_exact
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
  [v1z_l2]
    type = ElementL2Error
    variable = v1z
    function = v1z_exact
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
