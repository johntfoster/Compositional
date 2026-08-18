[Functions]
  [zero]
    type = ParsedFunction
    expression = '0'
  []
  [equivalent_pressure_exact]
    type = ParsedFunction
    expression = 'x+y+z'
  []
  [phase0_saturation_exact]
    type = ParsedFunction
    expression = '0.25+0.1*x'
  []
  [phase1_saturation_exact]
    type = ParsedFunction
    expression = '0.75-0.1*x'
  []
  [phase0_actual_pressure_potential]
    type = ParsedFunction
    expression = '1.7*x+y+z'
  []
  [phase1_actual_pressure_potential]
    type = ParsedFunction
    expression = '1.2*x+y+z'
  []
  [phase_momentum_pressure_potential]
    type = ParsedFunction
    expression = '1.4*x+y+z'
  []
  [entropy_exact]
    type = ParsedFunction
    expression = '0.008'
  []
  [power_exact]
    type = ParsedFunction
    expression = '2.4'
  []
[]

[ICs]
  [equivalent_pressure_ic]
    type = FunctionIC
    variable = equivalent_pressure
    function = equivalent_pressure_exact
  []
  [equivalent_pressure_enrichment_ic]
    type = FunctionIC
    variable = equivalent_pressure_enrichment
    function = zero
  []
  [phase0_saturation_ic]
    type = FunctionIC
    variable = phase0_saturation
    function = phase0_saturation_exact
  []
  [phase1_saturation_ic]
    type = FunctionIC
    variable = phase1_saturation
    function = phase1_saturation_exact
  []
  [phase0_saturation_enrichment_ic]
    type = FunctionIC
    variable = phase0_saturation_enrichment
    function = zero
  []
  [phase1_saturation_enrichment_ic]
    type = FunctionIC
    variable = phase1_saturation_enrichment
    function = zero
  []
[]

[Materials]
  [equivalent_pressure_reconstruction]
    type = ADEGReconstructedScalarMaterial
    backbone = equivalent_pressure
    enrichment = equivalent_pressure_enrichment
    field_name = test_equivalent_pressure
  []
  [phase0_saturation_reconstruction]
    type = ADEGReconstructedScalarMaterial
    backbone = phase0_saturation
    enrichment = phase0_saturation_enrichment
    field_name = test_phase0_saturation
  []
  [phase1_saturation_reconstruction]
    type = ADEGReconstructedScalarMaterial
    backbone = phase1_saturation
    enrichment = phase1_saturation_enrichment
    field_name = test_phase1_saturation
  []
  [constants]
    type = ADGenericConstantMaterial
    prop_names = 'test_gamma0 test_gamma1 test_L0 test_L1 test_rate0 test_rate1 test_reference_gauge test_fluid_fraction test_temperature test_three test_minus_two test_solid_psi test_solid_omega test_solid_vbar'
    prop_values = '2 4 0 4 -1 1 0 0.6 300 3 -2 5 2 0.5'
  []
  [onsager_temperature]
    type = ADGenericConstantMaterial
    prop_names = 'onsager_temperature_value'
    prop_values = '300'
  []
  [zero_gradients]
    type = ADGenericConstantVectorMaterial
    prop_names = 'test_gamma0_gradient test_gamma1_gradient test_L0_gradient test_L1_gradient'
    prop_values = '0 0 0  0 0 0  0 0 0  0 0 0'
  []
  [phase0_electric_enthalpy]
    type = ADParsedMaterial
    property_name = test_omega0
    material_property_names = test_phase0_saturation_total
    expression = '1+3*(test_phase0_saturation_total-0.25)'
  []
  [phase1_electric_enthalpy]
    type = ADParsedMaterial
    property_name = test_omega1
    material_property_names = test_phase0_saturation_total
    expression = '3-2*(test_phase0_saturation_total-0.25)'
  []
  [phase0_electric_enthalpy_gradient]
    type = ADThermodynamicPotentialGradientMaterial
    potential_derivative_names = test_three
    state_gradient_names = test_phase0_saturation_total_gradient
    potential_gradient_name = test_omega0_gradient
  []
  [phase1_electric_enthalpy_gradient]
    type = ADThermodynamicPotentialGradientMaterial
    potential_derivative_names = test_minus_two
    state_gradient_names = test_phase0_saturation_total_gradient
    potential_gradient_name = test_omega1_gradient
  []
  [interfacial_helmholtz]
    type = ADParsedMaterial
    property_name = test_gamma
    material_property_names = 'test_phase0_saturation_total test_phase1_saturation_total'
    expression = '2*test_phase0_saturation_total+4*test_phase1_saturation_total'
  []
  [volume_multiplier]
    type = ADParsedMaterial
    property_name = test_lambda
    material_property_names = test_equivalent_pressure_total
    expression = '-test_equivalent_pressure_total'
  []
  [phase0_pressure]
    type = ADParsedMaterial
    property_name = test_phase0_pressure
    material_property_names = 'test_equivalent_pressure_total test_omega0 test_phase1_saturation_total'
    expression = 'test_equivalent_pressure_total+2+test_omega0-4*test_phase1_saturation_total'
  []
  [phase1_pressure]
    type = ADParsedMaterial
    property_name = test_phase1_pressure
    material_property_names = 'test_equivalent_pressure_total test_omega1 test_phase1_saturation_total'
    expression = 'test_equivalent_pressure_total+8+test_omega1-4*test_phase1_saturation_total'
  []
  [solid_pressure]
    type = ADParsedMaterial
    property_name = test_solid_pressure
    material_property_names = test_equivalent_pressure_total
    expression = 'test_equivalent_pressure_total+2'
  []
  [saturation_onsager]
    type = ADSaturationOnsagerForceMaterial
    independent_phase_names = phase1
    saturation_rate_names = test_rate1
    resistance_matrix = 4
    porosity_name = test_fluid_fraction
    fluid_temperature_name = onsager_temperature_value
    property_prefix = test_saturation_onsager
  []
  [phase_thermodynamic_identities]
    type = ADPhaseThermodynamicIdentityMaterial
    include_fluid_gradients = true
    include_solid_legendre = true
    enforce_identity_residuals = true
    fluid_saturation_names = 'test_phase0_saturation_total test_phase1_saturation_total'
    fluid_pressure_names = 'test_phase0_pressure test_phase1_pressure'
    fluid_primitive_potential_names = 'test_gamma0 test_gamma1'
    fluid_electric_enthalpy_names = 'test_omega0 test_omega1'
    fluid_saturation_force_names = 'test_L0 test_L1'
    fluid_saturation_rate_names = 'test_rate0 test_rate1'
    predicted_force_difference_names = test_saturation_onsager_phase1_force_difference
    reference_fluid_index = 0
    reference_saturation_force_name = test_reference_gauge
    fluid_fraction_name = test_fluid_fraction
    fluid_temperature_name = test_temperature
    volume_constraint_multiplier_name = test_lambda
    interfacial_helmholtz_name = test_gamma
    equivalent_pressure_name = test_equivalent_pressure_total
    fluid_volume_fraction_el_residual_names = 'test_phase0_el_residual test_phase1_el_residual'
    exposed_saturation_force_names = 'test_exposed_L0 test_exposed_L1'
    force_difference_names = test_phase1_force_difference
    force_rate_residual_names = test_phase1_force_rate_residual
    reconstructed_fluid_pressure_names = 'test_reconstructed_phase0_pressure test_reconstructed_phase1_pressure'
    fluid_pressure_residual_names = 'test_phase0_pressure_residual test_phase1_pressure_residual'
    fluid_saturation_gradient_names = 'test_phase0_saturation_total_gradient test_phase1_saturation_total_gradient'
    fluid_primitive_potential_gradient_names = 'test_gamma0_gradient test_gamma1_gradient'
    fluid_electric_enthalpy_gradient_names = 'test_omega0_gradient test_omega1_gradient'
    fluid_saturation_force_gradient_names = 'test_L0_gradient test_L1_gradient'
    equivalent_pressure_gradient_name = test_equivalent_pressure_total_gradient
    reconstructed_fluid_pressure_gradient_names = 'test_reconstructed_phase0_pressure_gradient test_reconstructed_phase1_pressure_gradient'
    phase_momentum_pressure_potential_gradient_names = 'test_phase0_momentum_pressure_potential_gradient test_phase1_momentum_pressure_potential_gradient'
    solid_specific_helmholtz_name = test_solid_psi
    solid_electric_enthalpy_name = test_solid_omega
    solid_intrinsic_specific_volume_name = test_solid_vbar
    solid_phase_pressure_name = test_solid_pressure
    solid_equivalent_pressure_name = test_equivalent_pressure_total
  []
[]

[Postprocessors]
  [equivalent_pressure_l2]
    type = ElementL2Error
    variable = equivalent_pressure
    function = equivalent_pressure_exact
  []
  [equivalent_pressure_enrichment_l2]
    type = ElementL2Norm
    variable = equivalent_pressure_enrichment
  []
  [phase0_actual_pressure_gradient_l2]
    type = ADMaterialVectorL2Error
    property = test_reconstructed_phase0_pressure_gradient
    gradient_function = phase0_actual_pressure_potential
  []
  [phase1_actual_pressure_gradient_l2]
    type = ADMaterialVectorL2Error
    property = test_reconstructed_phase1_pressure_gradient
    gradient_function = phase1_actual_pressure_potential
  []
  [phase0_momentum_pressure_gradient_l2]
    type = ADMaterialVectorL2Error
    property = test_phase0_momentum_pressure_potential_gradient
    gradient_function = phase_momentum_pressure_potential
  []
  [phase1_momentum_pressure_gradient_l2]
    type = ADMaterialVectorL2Error
    property = test_phase1_momentum_pressure_potential_gradient
    gradient_function = phase_momentum_pressure_potential
  []
  [phase0_el_residual_l2]
    type = ADMaterialScalarL2Error
    property = test_phase0_el_residual
    function = zero
  []
  [phase1_el_residual_l2]
    type = ADMaterialScalarL2Error
    property = test_phase1_el_residual
    function = zero
  []
  [phase1_force_rate_residual_l2]
    type = ADMaterialScalarL2Error
    property = test_phase1_force_rate_residual
    function = zero
  []
  [equivalent_pressure_identity_l2]
    type = ADMaterialScalarL2Error
    property = equivalent_pressure_identity_residual
    function = zero
  []
  [entropy_l2]
    type = ADMaterialScalarL2Error
    property = saturation_entropy_production
    function = entropy_exact
  []
  [power_l2]
    type = ADMaterialScalarL2Error
    property = saturation_force_rate_power
    function = power_exact
  []
  [solid_equivalent_pressure_l2]
    type = ADMaterialScalarL2Error
    property = solid_phase_equivalent_pressure_residual
    function = zero
  []
[]
