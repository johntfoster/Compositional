!include spe1_initial_pvt_1d.i

[AuxVariables]
  [electric_potential][]
[]

[Functions]
  [electric_potential_exact]
    type = ParsedFunction
    expression = '2'
  []
  [normalized_gap_exact]
    type = ParsedFunction
    expression = '0.2732844'
  []
  [phase_transform_free_energy_exact]
    type = ParsedFunction
    expression = '3.663762258633486e-7'
  []
  [dissolved_neutral_mu_exact]
    type = ParsedFunction
    expression = '149.70027364764957'
  []
  [free_neutral_mu_exact]
    type = ParsedFunction
    expression = '149.702976810891'
  []
  [dissolved_electrochemical_mu_exact]
    type = ParsedFunction
    expression = '155.70027364764957'
  []
  [free_electrochemical_mu_exact]
    type = ParsedFunction
    expression = '151.702976810891'
  []
  [electrochemical_affinity_exact]
    type = ParsedFunction
    expression = '3.9972968367585793'
  []
[]

[ICs]
  [electric_potential_ic]
    type = FunctionIC
    variable = electric_potential
    function = electric_potential_exact
  []
[]

[Materials]
  [oil_pressure_property]
    type = ADParsedMaterial
    coupled_variables = oil_pressure
    property_name = oil_pressure_property
    expression = 'oil_pressure'
  []
  [phase_transform_mu]
    type = ADBlackOilPhaseTransformationThermodynamicsMaterial
    undersaturation_gap_name = benchmark_black_oil_undersaturation_gap
    oil_component_mass_fraction_name = benchmark_black_oil_oil_component_mass_fraction_in_oil
    dissolved_gas_mass_fraction_name = benchmark_black_oil_gas_component_mass_fraction_in_oil
    oil_intrinsic_density_name = benchmark_black_oil_oil_intrinsic_density
    gas_intrinsic_density_name = benchmark_black_oil_gas_intrinsic_density
    oil_bulk_density_name = benchmark_black_oil_oil_bulk_phase_density
    gas_bulk_density_name = benchmark_black_oil_gas_bulk_phase_density
    oil_pressure_name = oil_pressure_property
    gas_pressure_name = oil_pressure_property
    solution_gas_oil_ratio_scale = 1
    chemical_stiffness = 10
    oil_surface_density = 53.66
    gas_surface_density = 0.0533
    electric_potential = electric_potential
    dissolved_specific_charge = 3
    free_specific_charge = 1
    property_prefix = spe1_phase_transform
  []
[]

[Postprocessors]
  [normalized_gap_l2]
    type = ADMaterialScalarL2Error
    property = spe1_phase_transform_normalized_undersaturation
    function = normalized_gap_exact
    execute_on = INITIAL
  []
  [phase_transform_free_energy_l2]
    type = ADMaterialScalarL2Error
    property = spe1_phase_transform_specific_free_energy
    function = phase_transform_free_energy_exact
    execute_on = INITIAL
  []
  [dissolved_neutral_mu_l2]
    type = ADMaterialScalarL2Error
    property = spe1_phase_transform_dissolved_gas_neutral_mu
    function = dissolved_neutral_mu_exact
    execute_on = INITIAL
  []
  [free_neutral_mu_l2]
    type = ADMaterialScalarL2Error
    property = spe1_phase_transform_free_gas_neutral_mu
    function = free_neutral_mu_exact
    execute_on = INITIAL
  []
  [dissolved_electrochemical_mu_l2]
    type = ADMaterialScalarL2Error
    property = spe1_phase_transform_dissolved_gas_electrochemical_mu
    function = dissolved_electrochemical_mu_exact
    execute_on = INITIAL
  []
  [free_electrochemical_mu_l2]
    type = ADMaterialScalarL2Error
    property = spe1_phase_transform_free_gas_electrochemical_mu
    function = free_electrochemical_mu_exact
    execute_on = INITIAL
  []
  [electrochemical_affinity_l2]
    type = ADMaterialScalarL2Error
    property = spe1_phase_transform_dissolved_to_free_affinity
    function = electrochemical_affinity_exact
    execute_on = INITIAL
  []
[]
