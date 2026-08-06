mesh_nx := 4
solve_dt := 0.25
solve_steps := 4

!include ../../../input/includes/mesh/generated_1d_q2.i

[Variables]
  [summed_reference_component_0_density]
  []
  [summed_reference_component_1_density]
  []
[]

[AuxVariables]
  [reaction_rate]
    family = MONOMIAL
    order = CONSTANT
  []
  [summed_reference_component_0_source]
    family = MONOMIAL
    order = CONSTANT
  []
  [summed_reference_component_1_source]
    family = MONOMIAL
    order = CONSTANT
  []
  [oil_stoichiometric_mass_sum]
    family = MONOMIAL
    order = CONSTANT
  []
  [gas_stoichiometric_mass_sum]
    family = MONOMIAL
    order = CONSTANT
  []
[]

[Functions]
  [summed_reference_component_0_exact]
    type = ParsedFunction
    expression = '2-0.4*t'
  []
  [summed_reference_component_1_exact]
    type = ParsedFunction
    expression = '1+0.4*t'
  []
[]

[ICs]
  [summed_reference_component_0_density_ic]
    type = ConstantIC
    variable = summed_reference_component_0_density
    value = 2
  []
  [summed_reference_component_1_density_ic]
    type = ConstantIC
    variable = summed_reference_component_1_density
    value = 1
  []
  [reaction_rate_ic]
    type = ConstantIC
    variable = reaction_rate
    value = 0.4
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
  [closed_box_constants]
    type = ADGenericConstantMaterial
    prop_names = 'solid_reference_J oil_chemical_potential_0 oil_chemical_potential_1 gas_chemical_potential_0 gas_chemical_potential_1'
    prop_values = '1 0 0 0 0'
  []
  [zero_reference_flux]
    type = ADGenericConstantVectorMaterial
    prop_names = 'component_0_reference_flux component_1_reference_flux'
    prop_values = '0 0 0 0 0 0'
  []
  [network]
    type = ADReactionNetworkMaterial
    phase_registry = phases
    phases = 'oil gas'
    components = 'component0 component1'
    reaction_rates = reaction_rate
    stoichiometric_coefficients = '-1 0 0 1'
    chemical_potential_names = 'oil_chemical_potential_0 oil_chemical_potential_1 gas_chemical_potential_0 gas_chemical_potential_1'
  []
[]

[Kernels]
  [summed_reference_component_0_balance]
    type = ADReferenceFluidComponentBalance
    variable = summed_reference_component_0_density
    reference_component_flux = component_0_reference_flux
    reference_component_source = reaction_network_reference_component_source_0
  []
  [summed_reference_component_1_balance]
    type = ADReferenceFluidComponentBalance
    variable = summed_reference_component_1_density
    reference_component_flux = component_1_reference_flux
    reference_component_source = reaction_network_reference_component_source_1
  []
[]

[AuxKernels]
  [summed_reference_component_0_source_aux]
    type = ADMaterialRealAux
    variable = summed_reference_component_0_source
    property = reaction_network_reference_component_source_0
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [summed_reference_component_1_source_aux]
    type = ADMaterialRealAux
    variable = summed_reference_component_1_source
    property = reaction_network_reference_component_source_1
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [oil_stoichiometric_mass_sum_aux]
    type = ADMaterialRealAux
    variable = oil_stoichiometric_mass_sum
    property = reaction_network_mechanism_0_oil_mass_sum
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [gas_stoichiometric_mass_sum_aux]
    type = ADMaterialRealAux
    variable = gas_stoichiometric_mass_sum
    property = reaction_network_mechanism_0_gas_mass_sum
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]

[Postprocessors]
  [summed_reference_component_0_l2]
    type = ElementL2Error
    variable = summed_reference_component_0_density
    function = summed_reference_component_0_exact
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [summed_reference_component_1_l2]
    type = ElementL2Error
    variable = summed_reference_component_1_density
    function = summed_reference_component_1_exact
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [summed_reference_component_0_integral]
    type = ElementIntegralVariablePostprocessor
    variable = summed_reference_component_0_density
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [summed_reference_component_1_integral]
    type = ElementIntegralVariablePostprocessor
    variable = summed_reference_component_1_density
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [closed_box_total_mass]
    type = LinearCombinationPostprocessor
    pp_names = 'summed_reference_component_0_integral summed_reference_component_1_integral'
    pp_coefs = '1 1'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [summed_reference_component_0_source_average]
    type = ElementAverageValue
    variable = summed_reference_component_0_source
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [summed_reference_component_1_source_average]
    type = ElementAverageValue
    variable = summed_reference_component_1_source
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [stoichiometric_source_sum]
    type = LinearCombinationPostprocessor
    pp_names = 'summed_reference_component_0_source_average summed_reference_component_1_source_average'
    pp_coefs = '1 1'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [oil_stoichiometric_mass_sum_average]
    type = ElementAverageValue
    variable = oil_stoichiometric_mass_sum
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [gas_stoichiometric_mass_sum_average]
    type = ElementAverageValue
    variable = gas_stoichiometric_mass_sum
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [mechanism_stoichiometric_mass_sum]
    type = LinearCombinationPostprocessor
    pp_names = 'oil_stoichiometric_mass_sum_average gas_stoichiometric_mass_sum_average'
    pp_coefs = '1 1'
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]

!include ../../../input/includes/executioner/transient_newton.i
!include ../../../input/includes/outputs/csv.i
