[Mesh]
  type = GeneratedMesh
  dim = 1
  nx = 2
[]

[AuxVariables]
  [rho]
  []
  [temperature]
  []
  [phase_fraction]
  []
  [solid_pressure]
    family = MONOMIAL
    order = CONSTANT
  []
  [oil_pressure]
    family = MONOMIAL
    order = CONSTANT
  []
  [gas_pressure]
    family = MONOMIAL
    order = CONSTANT
  []
  [water_pressure]
    family = MONOMIAL
    order = CONSTANT
  []
  [solid_mu]
    family = MONOMIAL
    order = CONSTANT
  []
  [oil_mu]
    family = MONOMIAL
    order = CONSTANT
  []
  [gas_mu]
    family = MONOMIAL
    order = CONSTANT
  []
  [water_mu]
    family = MONOMIAL
    order = CONSTANT
  []
[]

[Functions]
  [one]
    type = ParsedFunction
    expression = '1'
  []
  [two]
    type = ParsedFunction
    expression = '2'
  []
[]

[ICs]
  [rho_ic]
    type = FunctionIC
    variable = rho
    function = two
  []
  [temperature_ic]
    type = FunctionIC
    variable = temperature
    function = one
  []
  [phase_fraction_ic]
    type = FunctionIC
    variable = phase_fraction
    function = one
  []
[]

[UserObjects]
  [phases]
    type = PhaseRegistry
    phases = 'solid oil gas water'
    reference_phase = solid
  []
[]

[Materials]
  [solid_helmholtz]
    type = ADDerivativeParsedMaterial
    coupled_variables = 'rho temperature'
    property_name = solid_A
    expression = '0.5*rho^2'
    derivative_order = 2
    enable_jit = true
  []
  [oil_helmholtz]
    type = ADDerivativeParsedMaterial
    coupled_variables = 'rho temperature'
    property_name = oil_A
    expression = 'rho^2'
    derivative_order = 2
    enable_jit = true
  []
  [gas_helmholtz]
    type = ADDerivativeParsedMaterial
    coupled_variables = 'rho temperature'
    property_name = gas_A
    expression = '1.5*rho^2'
    derivative_order = 2
    enable_jit = true
  []
  [water_helmholtz]
    type = ADDerivativeParsedMaterial
    coupled_variables = 'rho temperature'
    property_name = water_A
    expression = '2*rho^2'
    derivative_order = 2
    enable_jit = true
  []
  [solid_eos]
    type = ADHelmholtzEOSClosureMaterial
    phase = solid
    phase_registry = phases
    partial_densities = rho
    temperature = temperature
    porosity = phase_fraction
    helmholtz_density_name = solid_A
  []
  [oil_eos]
    type = ADHelmholtzEOSClosureMaterial
    phase = oil
    phase_registry = phases
    partial_densities = rho
    temperature = temperature
    porosity = phase_fraction
    helmholtz_density_name = oil_A
  []
  [gas_eos]
    type = ADHelmholtzEOSClosureMaterial
    phase = gas
    phase_registry = phases
    partial_densities = rho
    temperature = temperature
    porosity = phase_fraction
    helmholtz_density_name = gas_A
  []
  [water_eos]
    type = ADHelmholtzEOSClosureMaterial
    phase = water
    phase_registry = phases
    partial_densities = rho
    temperature = temperature
    porosity = phase_fraction
    helmholtz_density_name = water_A
  []
[]

[AuxKernels]
  [solid_pressure_aux]
    type = ADMaterialRealAux
    variable = solid_pressure
    property = solid_pressure_from_eos
    execute_on = INITIAL
  []
  [oil_pressure_aux]
    type = ADMaterialRealAux
    variable = oil_pressure
    property = oil_pressure_from_eos
    execute_on = INITIAL
  []
  [gas_pressure_aux]
    type = ADMaterialRealAux
    variable = gas_pressure
    property = gas_pressure_from_eos
    execute_on = INITIAL
  []
  [water_pressure_aux]
    type = ADMaterialRealAux
    variable = water_pressure
    property = water_pressure_from_eos
    execute_on = INITIAL
  []
  [solid_mu_aux]
    type = ADMaterialRealAux
    variable = solid_mu
    property = solid_chemical_potential_0
    execute_on = INITIAL
  []
  [oil_mu_aux]
    type = ADMaterialRealAux
    variable = oil_mu
    property = oil_chemical_potential_0
    execute_on = INITIAL
  []
  [gas_mu_aux]
    type = ADMaterialRealAux
    variable = gas_mu
    property = gas_chemical_potential_0
    execute_on = INITIAL
  []
  [water_mu_aux]
    type = ADMaterialRealAux
    variable = water_mu
    property = water_chemical_potential_0
    execute_on = INITIAL
  []
[]

[Postprocessors]
  [solid_pressure_value]
    type = ElementAverageValue
    variable = solid_pressure
    execute_on = INITIAL
  []
  [oil_pressure_value]
    type = ElementAverageValue
    variable = oil_pressure
    execute_on = INITIAL
  []
  [gas_pressure_value]
    type = ElementAverageValue
    variable = gas_pressure
    execute_on = INITIAL
  []
  [water_pressure_value]
    type = ElementAverageValue
    variable = water_pressure
    execute_on = INITIAL
  []
  [solid_mu_value]
    type = ElementAverageValue
    variable = solid_mu
    execute_on = INITIAL
  []
  [oil_mu_value]
    type = ElementAverageValue
    variable = oil_mu
    execute_on = INITIAL
  []
  [gas_mu_value]
    type = ElementAverageValue
    variable = gas_mu
    execute_on = INITIAL
  []
  [water_mu_value]
    type = ElementAverageValue
    variable = water_mu
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
