[Mesh]
  type = GeneratedMesh
  dim = 1
  nx = 2
[]

[Variables]
  [water_volume_fraction_rate]
    family = LAGRANGE
    order = FIRST
  []
[]

[Functions]
  [water_volume_fraction_rate_exact]
    type = ParsedFunction
    expression = '0.1224'
  []
  [fluid_fraction_exact]
    type = ParsedFunction
    expression = '0.6'
  []
  [stored_energy_density_exact]
    type = ParsedFunction
    expression = '6'
  []
  [water_saturation_exact]
    type = ParsedFunction
    expression = '1.0/3.0'
  []
  [oil_saturation_exact]
    type = ParsedFunction
    expression = '0.5'
  []
  [gas_saturation_exact]
    type = ParsedFunction
    expression = '1.0/6.0'
  []
  [water_interfacial_potential_exact]
    type = ParsedFunction
    expression = '25.0/3.0'
  []
  [oil_interfacial_potential_exact]
    type = ParsedFunction
    expression = '31.0/3.0'
  []
  [gas_interfacial_potential_exact]
    type = ParsedFunction
    expression = '37.0/3.0'
  []
  [history_storage_rate_exact]
    type = ParsedFunction
    expression = '-1.2'
  []
  [temperature_storage_rate_exact]
    type = ParsedFunction
    expression = '0.18'
  []
  [history_dissipation_exact]
    type = ParsedFunction
    expression = '1.2'
  []
  [history_entropy_production_exact]
    type = ParsedFunction
    expression = '0.004'
  []
  [zero]
    type = ParsedFunction
    expression = '0'
  []
[]

[ICs]
  [water_volume_fraction_rate_ic]
    type = ConstantIC
    variable = water_volume_fraction_rate
    value = 0.1
  []
[]

[Materials]
  [constants]
    type = ADGenericConstantMaterial
    prop_names = 'solid_reference_J unit water_phi oil_phi gas_phi oil_phi_rate gas_phi_rate gamma gamma_Sw gamma_So gamma_Sg gamma_h0 gamma_h1 h0_rate h1_rate gamma_temperature temperature_rate fluid_temperature'
    prop_values = '1 1 0.2 0.3 0.1 0 0 10 1 3 5 2 -4 -0.5 0.25 0.1 3 300'
  []
  [water_rate_property]
    type = ADParsedMaterial
    coupled_variables = water_volume_fraction_rate
    property_name = water_phi_rate
    expression = 'water_volume_fraction_rate'
  []
  [surface_energy]
    type = ADInterfacialSurfaceEnergyMaterial
    phase_names = 'water oil gas'
    phase_volume_fraction_names = 'water_phi oil_phi gas_phi'
    phase_volume_fraction_rate_names = 'water_phi_rate oil_phi_rate gas_phi_rate'
    surface_energy_name = gamma
    saturation_derivative_names = 'gamma_Sw gamma_So gamma_Sg'
    history_derivative_names = 'gamma_h0 gamma_h1'
    history_rate_names = 'h0_rate h1_rate'
    temperature_derivative_name = gamma_temperature
    fluid_temperature_rate_name = temperature_rate
    fluid_temperature_name = fluid_temperature
  []
[]

[Kernels]
  [surface_energy_rate_equation]
    type = ADReferenceEnergyPropertyRateTerm
    variable = water_volume_fraction_rate
    rate_name = interfacial_surface_stored_energy_rate
    coefficient_name = unit
  []
[]

[Postprocessors]
  [water_volume_fraction_rate_error]
    type = ElementL2Error
    variable = water_volume_fraction_rate
    function = water_volume_fraction_rate_exact
  []
  [fluid_fraction_error]
    type = ADMaterialScalarL2Error
    property = interfacial_surface_fluid_volume_fraction
    function = fluid_fraction_exact
  []
  [stored_energy_density_error]
    type = ADMaterialScalarL2Error
    property = interfacial_surface_stored_energy_density
    function = stored_energy_density_exact
  []
  [stored_energy_rate_error]
    type = ADMaterialScalarL2Error
    property = interfacial_surface_stored_energy_rate
    function = zero
  []
  [water_saturation_error]
    type = ADMaterialScalarL2Error
    property = interfacial_surface_water_saturation
    function = water_saturation_exact
  []
  [oil_saturation_error]
    type = ADMaterialScalarL2Error
    property = interfacial_surface_oil_saturation
    function = oil_saturation_exact
  []
  [gas_saturation_error]
    type = ADMaterialScalarL2Error
    property = interfacial_surface_gas_saturation
    function = gas_saturation_exact
  []
  [water_interfacial_potential_error]
    type = ADMaterialScalarL2Error
    property = interfacial_surface_water_interfacial_potential
    function = water_interfacial_potential_exact
  []
  [oil_interfacial_potential_error]
    type = ADMaterialScalarL2Error
    property = interfacial_surface_oil_interfacial_potential
    function = oil_interfacial_potential_exact
  []
  [gas_interfacial_potential_error]
    type = ADMaterialScalarL2Error
    property = interfacial_surface_gas_interfacial_potential
    function = gas_interfacial_potential_exact
  []
  [history_storage_rate_error]
    type = ADMaterialScalarL2Error
    property = interfacial_surface_history_storage_rate
    function = history_storage_rate_exact
  []
  [temperature_storage_rate_error]
    type = ADMaterialScalarL2Error
    property = interfacial_surface_temperature_storage_rate
    function = temperature_storage_rate_exact
  []
  [history_dissipation_error]
    type = ADMaterialScalarL2Error
    property = interfacial_surface_history_dissipation_rate
    function = history_dissipation_exact
  []
  [history_entropy_production_error]
    type = ADMaterialScalarL2Error
    property = interfacial_surface_history_entropy_production_rate
    function = history_entropy_production_exact
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
