!include spe1_initial_pvt_1d.i

[AuxVariables]
  [water_component_flux_x]
    family = MONOMIAL
    order = CONSTANT
  []
  [oil_component_flux_x]
    family = MONOMIAL
    order = CONSTANT
  []
  [gas_component_flux_x]
    family = MONOMIAL
    order = CONSTANT
  []
[]

[Functions]
  [water_component_flux_exact]
    type = ParsedFunction
    expression = '-4'
  []
  [oil_component_flux_exact]
    type = ParsedFunction
    expression = '-1.9969388312652954'
  []
  [gas_component_flux_exact]
    type = ParsedFunction
    expression = '-3.0030611687347046'
  []
[]

[UserObjects]
  [phases]
    type = PhaseRegistry
    phases = 'matrix oil gas water'
    reference_phase = matrix
    momentum_models = 'reference relative_flux relative_flux relative_flux'
  []
[]

[Materials]
  [phase_fluxes]
    type = ADGenericConstantVectorMaterial
    prop_names = 'oil_reference_relative_mass_flux gas_reference_relative_mass_flux water_reference_relative_mass_flux'
    prop_values = '-2 0 0 -3 0 0 -4 0 0'
  []
  [zero_component_fraction]
    type = ADGenericConstantMaterial
    prop_names = zero_component_fraction
    prop_values = '0'
  []
  [water_component_flux]
    type = ADRegisteredPhaseComponentFluxMaterial
    phase_registry = phases
    phases = 'oil gas water'
    component = 0
    phase_reference_relative_mass_flux_names = 'oil_reference_relative_mass_flux gas_reference_relative_mass_flux water_reference_relative_mass_flux'
    phase_component_mass_fraction_names = 'zero_component_fraction zero_component_fraction benchmark_black_oil_water_component_mass_fraction_in_water'
    reference_component_flux_name = water_reference_component_flux
    reference_component_source_name = water_reference_component_source
  []
  [oil_component_flux]
    type = ADRegisteredPhaseComponentFluxMaterial
    phase_registry = phases
    phases = 'oil gas water'
    component = 1
    phase_reference_relative_mass_flux_names = 'oil_reference_relative_mass_flux gas_reference_relative_mass_flux water_reference_relative_mass_flux'
    phase_component_mass_fraction_names = 'benchmark_black_oil_oil_component_mass_fraction_in_oil zero_component_fraction zero_component_fraction'
    reference_component_flux_name = oil_reference_component_flux
    reference_component_source_name = oil_reference_component_source
  []
  [gas_component_flux]
    type = ADRegisteredPhaseComponentFluxMaterial
    phase_registry = phases
    phases = 'oil gas water'
    component = 2
    phase_reference_relative_mass_flux_names = 'oil_reference_relative_mass_flux gas_reference_relative_mass_flux water_reference_relative_mass_flux'
    phase_component_mass_fraction_names = 'benchmark_black_oil_gas_component_mass_fraction_in_oil benchmark_black_oil_gas_component_mass_fraction_in_gas zero_component_fraction'
    reference_component_flux_name = gas_reference_component_flux
    reference_component_source_name = gas_reference_component_source
  []
[]

[AuxKernels]
  [water_component_flux_x_aux]
    type = ADMaterialRealVectorValueAux
    variable = water_component_flux_x
    property = water_reference_component_flux
    component = 0
    execute_on = INITIAL
  []
  [oil_component_flux_x_aux]
    type = ADMaterialRealVectorValueAux
    variable = oil_component_flux_x
    property = oil_reference_component_flux
    component = 0
    execute_on = INITIAL
  []
  [gas_component_flux_x_aux]
    type = ADMaterialRealVectorValueAux
    variable = gas_component_flux_x
    property = gas_reference_component_flux
    component = 0
    execute_on = INITIAL
  []
[]

[Postprocessors]
  [water_component_flux_l2]
    type = ElementL2Error
    variable = water_component_flux_x
    function = water_component_flux_exact
    execute_on = INITIAL
  []
  [oil_component_flux_l2]
    type = ElementL2Error
    variable = oil_component_flux_x
    function = oil_component_flux_exact
    execute_on = INITIAL
  []
  [gas_component_flux_l2]
    type = ElementL2Error
    variable = gas_component_flux_x
    function = gas_component_flux_exact
    execute_on = INITIAL
  []
[]
