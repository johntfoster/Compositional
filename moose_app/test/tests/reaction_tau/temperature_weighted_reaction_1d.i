[Mesh]
  type = GeneratedMesh
  dim = 1
  nx = 2
[]

[Variables]
  [reaction_rate]
    family = MONOMIAL
    order = SECOND
  []
  [oil_temperature]
    family = LAGRANGE
    order = FIRST
  []
  [gas_temperature]
    family = LAGRANGE
    order = FIRST
  []
[]

[Functions]
  [reaction_rate_exact]
    type = ParsedFunction
    expression = '-0.1'
  []
  [oil_temperature_exact]
    type = ParsedFunction
    expression = '300'
  []
  [gas_temperature_exact]
    type = ParsedFunction
    expression = '400'
  []
  [oil_transfer_work_exact]
    type = ParsedFunction
    expression = '8'
  []
  [gas_transfer_work_exact]
    type = ParsedFunction
    expression = '16'
  []
  [oil_neutral_coefficient_exact]
    type = ParsedFunction
    expression = '10'
  []
  [gas_neutral_coefficient_exact]
    type = ParsedFunction
    expression = '20'
  []
  [affinity_exact]
    type = ParsedFunction
    expression = '-4'
  []
  [tau_correction_exact]
    type = ParsedFunction
    expression = '6'
  []
  [generalized_force_exact]
    type = ParsedFunction
    expression = '-10'
  []
  [temperature_weighted_force_exact]
    type = ParsedFunction
    expression = '-1.0/60.0'
  []
  [kinetic_residual_exact]
    type = ParsedFunction
    expression = '0'
  []
  [generalized_reaction_power_exact]
    type = ParsedFunction
    expression = '1'
  []
  [temperature_weighted_reaction_power_exact]
    type = ParsedFunction
    expression = '1.0/600.0'
  []
[]

[ICs]
  [reaction_rate_ic]
    type = ConstantIC
    variable = reaction_rate
    value = -0.05
  []
  [oil_temperature_ic]
    type = ConstantIC
    variable = oil_temperature
    value = 290
  []
  [gas_temperature_ic]
    type = ConstantIC
    variable = gas_temperature
    value = 410
  []
[]

[UserObjects]
  [phases]
    type = PhaseRegistry
    phases = 'solid oil gas'
    reference_phase = solid
  []
[]

[Materials]
  [thermodynamic_constants]
    type = ADGenericConstantMaterial
    prop_names = 'solid_reference_J oil_mu gas_mu oil_psi gas_psi oil_tau_offset gas_tau_offset'
    prop_values = '1 7 11 2 4 3 9'
  []
  [oil_transfer_work]
    type = ADGeneralizedTransferWorkMaterial
    chemical_potential_name = oil_mu
    specific_helmholtz_name = oil_psi
    tau_transfer_offset_name = oil_tau_offset
    generalized_transfer_work_name = oil_generalized_transfer_work
    neutral_conversion_coefficient_name = oil_neutral_conversion_coefficient
  []
  [gas_transfer_work]
    type = ADGeneralizedTransferWorkMaterial
    chemical_potential_name = gas_mu
    specific_helmholtz_name = gas_psi
    tau_transfer_offset_name = gas_tau_offset
    generalized_transfer_work_name = gas_generalized_transfer_work
    neutral_conversion_coefficient_name = gas_neutral_conversion_coefficient
  []
  [oil_temperature_property]
    type = ADParsedMaterial
    coupled_variables = oil_temperature
    property_name = oil_temperature_value
    expression = 'oil_temperature'
  []
  [gas_temperature_property]
    type = ADParsedMaterial
    coupled_variables = gas_temperature
    property_name = gas_temperature_value
    expression = 'gas_temperature'
  []
  [oil_temperature_residual]
    type = ADParsedMaterial
    coupled_variables = oil_temperature
    property_name = oil_temperature_residual
    expression = 'oil_temperature-300'
  []
  [gas_temperature_residual]
    type = ADParsedMaterial
    coupled_variables = gas_temperature
    property_name = gas_temperature_residual
    expression = 'gas_temperature-400'
  []
  [reaction_network]
    type = ADReactionNetworkMaterial
    phase_registry = phases
    phases = 'oil gas'
    components = gas_component
    reaction_rates = reaction_rate
    stoichiometric_coefficients = '-1 1'
    chemical_potential_names = 'oil_mu gas_mu'
    phase_tau_offset_names = 'oil_tau_offset gas_tau_offset'
    neutral_conversion_coefficient_names = 'oil_neutral_conversion_coefficient gas_neutral_conversion_coefficient'
    phase_temperature_names = 'oil_temperature_value gas_temperature_value'
    kinetic_force = temperature_weighted_neutral
    kinetic_mobilities = '6'
  []
[]

[Kernels]
  [reaction_rate_equation]
    type = ADMaterialPropertyResidual
    variable = reaction_rate
    property = reaction_network_kinetic_residual_0
  []
  [oil_temperature_equation]
    type = ADMaterialPropertyResidual
    variable = oil_temperature
    property = oil_temperature_residual
  []
  [gas_temperature_equation]
    type = ADMaterialPropertyResidual
    variable = gas_temperature
    property = gas_temperature_residual
  []
[]

[Postprocessors]
  [reaction_rate_error]
    type = ElementL2Error
    variable = reaction_rate
    function = reaction_rate_exact
  []
  [oil_temperature_error]
    type = ElementL2Error
    variable = oil_temperature
    function = oil_temperature_exact
  []
  [gas_temperature_error]
    type = ElementL2Error
    variable = gas_temperature
    function = gas_temperature_exact
  []
  [oil_transfer_work_error]
    type = ADMaterialScalarL2Error
    property = oil_generalized_transfer_work
    function = oil_transfer_work_exact
  []
  [gas_transfer_work_error]
    type = ADMaterialScalarL2Error
    property = gas_generalized_transfer_work
    function = gas_transfer_work_exact
  []
  [oil_neutral_coefficient_error]
    type = ADMaterialScalarL2Error
    property = oil_neutral_conversion_coefficient
    function = oil_neutral_coefficient_exact
  []
  [gas_neutral_coefficient_error]
    type = ADMaterialScalarL2Error
    property = gas_neutral_conversion_coefficient
    function = gas_neutral_coefficient_exact
  []
  [affinity_error]
    type = ADMaterialScalarL2Error
    property = reaction_network_affinity_0
    function = affinity_exact
  []
  [tau_correction_error]
    type = ADMaterialScalarL2Error
    property = reaction_network_transfer_work_correction_0
    function = tau_correction_exact
  []
  [generalized_force_error]
    type = ADMaterialScalarL2Error
    property = reaction_network_generalized_conversion_coefficient_0
    function = generalized_force_exact
  []
  [temperature_weighted_force_error]
    type = ADMaterialScalarL2Error
    property = reaction_network_temperature_weighted_force_0
    function = temperature_weighted_force_exact
  []
  [selected_kinetic_force_error]
    type = ADMaterialScalarL2Error
    property = reaction_network_kinetic_force_0
    function = temperature_weighted_force_exact
  []
  [kinetic_residual_error]
    type = ADMaterialScalarL2Error
    property = reaction_network_kinetic_residual_0
    function = kinetic_residual_exact
  []
  [generalized_reaction_power_error]
    type = ADMaterialScalarL2Error
    property = reaction_network_reaction_power_0
    function = generalized_reaction_power_exact
  []
  [temperature_weighted_reaction_power_error]
    type = ADMaterialScalarL2Error
    property = reaction_network_temperature_weighted_reaction_power_0
    function = temperature_weighted_reaction_power_exact
  []
[]

[Executioner]
  type = Steady
  solve_type = NEWTON
  nl_abs_tol = 1e-13
  nl_rel_tol = 1e-13
[]

[Outputs]
  console = true
  csv = true
[]
