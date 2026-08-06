[Mesh]
  type = GeneratedMesh
  dim = 1
  nx = 2
[]

[AuxVariables]
  [reaction_rate_0]
  []
  [reaction_rate_1]
  []
  [oil_current_source_0]
    family = MONOMIAL
    order = CONSTANT
  []
  [oil_current_source_1]
    family = MONOMIAL
    order = CONSTANT
  []
  [gas_current_source_0]
    family = MONOMIAL
    order = CONSTANT
  []
  [gas_current_source_1]
    family = MONOMIAL
    order = CONSTANT
  []
  [total_reference_source_0]
    family = MONOMIAL
    order = CONSTANT
  []
  [total_reference_source_1]
    family = MONOMIAL
    order = CONSTANT
  []
  [affinity_0]
    family = MONOMIAL
    order = CONSTANT
  []
  [affinity_1]
    family = MONOMIAL
    order = CONSTANT
  []
  [correction_0]
    family = MONOMIAL
    order = CONSTANT
  []
  [correction_1]
    family = MONOMIAL
    order = CONSTANT
  []
  [generalized_0]
    family = MONOMIAL
    order = CONSTANT
  []
  [generalized_1]
    family = MONOMIAL
    order = CONSTANT
  []
  [kinetic_residual_0]
    family = MONOMIAL
    order = CONSTANT
  []
  [kinetic_residual_1]
    family = MONOMIAL
    order = CONSTANT
  []
  [reaction_power_0]
    family = MONOMIAL
    order = CONSTANT
  []
  [reaction_power_1]
    family = MONOMIAL
    order = CONSTANT
  []
  [oil_mass_sum_0]
    family = MONOMIAL
    order = CONSTANT
  []
  [gas_mass_sum_0]
    family = MONOMIAL
    order = CONSTANT
  []
  [oil_mass_sum_1]
    family = MONOMIAL
    order = CONSTANT
  []
  [gas_mass_sum_1]
    family = MONOMIAL
    order = CONSTANT
  []
[]

[Functions]
  [rate_0_exact]
    type = ParsedFunction
    expression = '0.5'
  []
  [rate_1_exact]
    type = ParsedFunction
    expression = '0.25'
  []
[]

[ICs]
  [reaction_rate_0_ic]
    type = FunctionIC
    variable = reaction_rate_0
    function = rate_0_exact
  []
  [reaction_rate_1_ic]
    type = FunctionIC
    variable = reaction_rate_1
    function = rate_1_exact
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
  [constants]
    type = ADGenericConstantMaterial
    prop_names = 'solid_reference_J oil_chemical_potential_0 oil_chemical_potential_1 gas_chemical_potential_0 gas_chemical_potential_1 oil_tau_transfer_offset gas_tau_transfer_offset forward_availability_0 forward_availability_1 reverse_availability_0 reverse_availability_1'
    prop_values = '2 2 5 7 11 1.25 -0.5 0.25 0.5 0.75 0.2'
  []
  [network]
    type = ADReactionNetworkMaterial
    phase_registry = phases
    phases = 'oil gas'
    components = 'component0 component1'
    reaction_rates = 'reaction_rate_0 reaction_rate_1'
    stoichiometric_coefficients = '-1 1 1 -1 -2 0 0 3'
    chemical_potential_names = 'oil_chemical_potential_0 oil_chemical_potential_1 gas_chemical_potential_0 gas_chemical_potential_1'
    phase_tau_offset_names = 'oil_tau_transfer_offset gas_tau_transfer_offset'
    kinetic_mobilities = '0.5 0.1'
  []
[]

[AuxKernels]
  [oil_current_source_0_aux]
    type = ADMaterialRealAux
    variable = oil_current_source_0
    property = reaction_network_oil_current_component_source_0
    execute_on = INITIAL
  []
  [oil_current_source_1_aux]
    type = ADMaterialRealAux
    variable = oil_current_source_1
    property = reaction_network_oil_current_component_source_1
    execute_on = INITIAL
  []
  [gas_current_source_0_aux]
    type = ADMaterialRealAux
    variable = gas_current_source_0
    property = reaction_network_gas_current_component_source_0
    execute_on = INITIAL
  []
  [gas_current_source_1_aux]
    type = ADMaterialRealAux
    variable = gas_current_source_1
    property = reaction_network_gas_current_component_source_1
    execute_on = INITIAL
  []
  [total_reference_source_0_aux]
    type = ADMaterialRealAux
    variable = total_reference_source_0
    property = reaction_network_reference_component_source_0
    execute_on = INITIAL
  []
  [total_reference_source_1_aux]
    type = ADMaterialRealAux
    variable = total_reference_source_1
    property = reaction_network_reference_component_source_1
    execute_on = INITIAL
  []
  [affinity_0_aux]
    type = ADMaterialRealAux
    variable = affinity_0
    property = reaction_network_affinity_0
    execute_on = INITIAL
  []
  [affinity_1_aux]
    type = ADMaterialRealAux
    variable = affinity_1
    property = reaction_network_affinity_1
    execute_on = INITIAL
  []
  [correction_0_aux]
    type = ADMaterialRealAux
    variable = correction_0
    property = reaction_network_transfer_work_correction_0
    execute_on = INITIAL
  []
  [correction_1_aux]
    type = ADMaterialRealAux
    variable = correction_1
    property = reaction_network_transfer_work_correction_1
    execute_on = INITIAL
  []
  [generalized_0_aux]
    type = ADMaterialRealAux
    variable = generalized_0
    property = reaction_network_generalized_conversion_coefficient_0
    execute_on = INITIAL
  []
  [generalized_1_aux]
    type = ADMaterialRealAux
    variable = generalized_1
    property = reaction_network_generalized_conversion_coefficient_1
    execute_on = INITIAL
  []
  [kinetic_residual_0_aux]
    type = ADMaterialRealAux
    variable = kinetic_residual_0
    property = reaction_network_kinetic_residual_0
    execute_on = INITIAL
  []
  [kinetic_residual_1_aux]
    type = ADMaterialRealAux
    variable = kinetic_residual_1
    property = reaction_network_kinetic_residual_1
    execute_on = INITIAL
  []
  [reaction_power_0_aux]
    type = ADMaterialRealAux
    variable = reaction_power_0
    property = reaction_network_reaction_power_0
    execute_on = INITIAL
  []
  [reaction_power_1_aux]
    type = ADMaterialRealAux
    variable = reaction_power_1
    property = reaction_network_reaction_power_1
    execute_on = INITIAL
  []
  [oil_mass_sum_0_aux]
    type = ADMaterialRealAux
    variable = oil_mass_sum_0
    property = reaction_network_mechanism_0_oil_mass_sum
    execute_on = INITIAL
  []
  [gas_mass_sum_0_aux]
    type = ADMaterialRealAux
    variable = gas_mass_sum_0
    property = reaction_network_mechanism_0_gas_mass_sum
    execute_on = INITIAL
  []
  [oil_mass_sum_1_aux]
    type = ADMaterialRealAux
    variable = oil_mass_sum_1
    property = reaction_network_mechanism_1_oil_mass_sum
    execute_on = INITIAL
  []
  [gas_mass_sum_1_aux]
    type = ADMaterialRealAux
    variable = gas_mass_sum_1
    property = reaction_network_mechanism_1_gas_mass_sum
    execute_on = INITIAL
  []
[]

[Postprocessors]
  [oil_current_source_0_value]
    type = ElementAverageValue
    variable = oil_current_source_0
    execute_on = INITIAL
  []
  [oil_current_source_1_value]
    type = ElementAverageValue
    variable = oil_current_source_1
    execute_on = INITIAL
  []
  [gas_current_source_0_value]
    type = ElementAverageValue
    variable = gas_current_source_0
    execute_on = INITIAL
  []
  [gas_current_source_1_value]
    type = ElementAverageValue
    variable = gas_current_source_1
    execute_on = INITIAL
  []
  [total_reference_source_0_value]
    type = ElementAverageValue
    variable = total_reference_source_0
    execute_on = INITIAL
  []
  [total_reference_source_1_value]
    type = ElementAverageValue
    variable = total_reference_source_1
    execute_on = INITIAL
  []
  [affinity_0_value]
    type = ElementAverageValue
    variable = affinity_0
    execute_on = INITIAL
  []
  [affinity_1_value]
    type = ElementAverageValue
    variable = affinity_1
    execute_on = INITIAL
  []
  [correction_0_value]
    type = ElementAverageValue
    variable = correction_0
    execute_on = INITIAL
  []
  [correction_1_value]
    type = ElementAverageValue
    variable = correction_1
    execute_on = INITIAL
  []
  [generalized_0_value]
    type = ElementAverageValue
    variable = generalized_0
    execute_on = INITIAL
  []
  [generalized_1_value]
    type = ElementAverageValue
    variable = generalized_1
    execute_on = INITIAL
  []
  [kinetic_residual_0_value]
    type = ElementAverageValue
    variable = kinetic_residual_0
    execute_on = INITIAL
  []
  [kinetic_residual_1_value]
    type = ElementAverageValue
    variable = kinetic_residual_1
    execute_on = INITIAL
  []
  [reaction_power_0_value]
    type = ElementAverageValue
    variable = reaction_power_0
    execute_on = INITIAL
  []
  [reaction_power_1_value]
    type = ElementAverageValue
    variable = reaction_power_1
    execute_on = INITIAL
  []
  [oil_mass_sum_0_value]
    type = ElementAverageValue
    variable = oil_mass_sum_0
    execute_on = INITIAL
  []
  [gas_mass_sum_0_value]
    type = ElementAverageValue
    variable = gas_mass_sum_0
    execute_on = INITIAL
  []
  [oil_mass_sum_1_value]
    type = ElementAverageValue
    variable = oil_mass_sum_1
    execute_on = INITIAL
  []
  [gas_mass_sum_1_value]
    type = ElementAverageValue
    variable = gas_mass_sum_1
    execute_on = INITIAL
  []
[]

[Problem]
  solve = false
[]

[Executioner]
  type = Steady
[]

[Outputs]
  console = true
  csv = true
[]
