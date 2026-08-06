[Mesh]
  type = GeneratedMesh
  dim = 1
  nx = 2
[]

[AuxVariables]
  [ux]
  []
  [temperature]
  []
  [phi_total]
  []
  [phi_oil]
  []
  [phi_gas]
  []
  [phi_water]
  []
  [rho0]
  []
  [rho1]
  []
  [rho_oil_0]
  []
  [rho_oil_1]
  []
  [rho_gas_0]
  []
  [rho_gas_1]
  []
  [rho_water_0]
  []
  [rho_water_1]
  []
  [eta_oil_0]
  []
  [eta_oil_1]
  []
  [eta_gas_0]
  []
  [eta_gas_1]
  []
  [eta_water_0]
  []
  [eta_water_1]
  []
  [z0]
  []
  [z1]
  []
  [storage0]
    family = MONOMIAL
    order = CONSTANT
  []
  [storage1]
    family = MONOMIAL
    order = CONSTANT
  []
  [oil_saturation]
    family = MONOMIAL
    order = CONSTANT
  []
  [gas_saturation]
    family = MONOMIAL
    order = CONSTANT
  []
  [water_active]
    family = MONOMIAL
    order = CONSTANT
  []
  [volume_residual]
    family = MONOMIAL
    order = CONSTANT
  []
  [gas_mu0_residual]
    family = MONOMIAL
    order = CONSTANT
  []
  [water_mu0_residual]
    family = MONOMIAL
    order = CONSTANT
  []
  [gas_pressure_residual]
    family = MONOMIAL
    order = CONSTANT
  []
  [overall_z0_residual]
    family = MONOMIAL
    order = CONSTANT
  []
[]

[Functions]
  [zero]
    type = ParsedFunction
    expression = '0'
  []
  [one]
    type = ParsedFunction
    expression = '1'
  []
  [temperature_exact]
    type = ParsedFunction
    expression = '2'
  []
  [phi_total_exact]
    type = ParsedFunction
    expression = '0.3'
  []
  [phi_oil_exact]
    type = ParsedFunction
    expression = '0.2'
  []
  [phi_gas_exact]
    type = ParsedFunction
    expression = '0.1'
  []
  [rho0_exact]
    type = ParsedFunction
    expression = '1'
  []
  [rho1_exact]
    type = ParsedFunction
    expression = '2'
  []
  [rho_water_0_exact]
    type = ParsedFunction
    expression = '3'
  []
  [rho_water_1_exact]
    type = ParsedFunction
    expression = '1'
  []
  [eta0_exact]
    type = ParsedFunction
    expression = '1/3'
  []
  [eta1_exact]
    type = ParsedFunction
    expression = '2/3'
  []
  [eta_water_0_exact]
    type = ParsedFunction
    expression = '0.75'
  []
  [eta_water_1_exact]
    type = ParsedFunction
    expression = '0.25'
  []
  [storage0_exact]
    type = ParsedFunction
    expression = '0.3'
  []
  [storage1_exact]
    type = ParsedFunction
    expression = '0.6'
  []
  [oil_saturation_exact]
    type = ParsedFunction
    expression = '2/3'
  []
  [gas_saturation_exact]
    type = ParsedFunction
    expression = '1/3'
  []
[]

[ICs]
  [ux_ic]
    type = FunctionIC
    variable = ux
    function = zero
  []
  [temperature_ic]
    type = FunctionIC
    variable = temperature
    function = temperature_exact
  []
  [phi_total_ic]
    type = FunctionIC
    variable = phi_total
    function = phi_total_exact
  []
  [phi_oil_ic]
    type = FunctionIC
    variable = phi_oil
    function = phi_oil_exact
  []
  [phi_gas_ic]
    type = FunctionIC
    variable = phi_gas
    function = phi_gas_exact
  []
  [phi_water_ic]
    type = FunctionIC
    variable = phi_water
    function = zero
  []
  [rho0_ic]
    type = FunctionIC
    variable = rho0
    function = rho0_exact
  []
  [rho1_ic]
    type = FunctionIC
    variable = rho1
    function = rho1_exact
  []
  [rho_oil_0_ic]
    type = FunctionIC
    variable = rho_oil_0
    function = rho0_exact
  []
  [rho_oil_1_ic]
    type = FunctionIC
    variable = rho_oil_1
    function = rho1_exact
  []
  [rho_gas_0_ic]
    type = FunctionIC
    variable = rho_gas_0
    function = rho0_exact
  []
  [rho_gas_1_ic]
    type = FunctionIC
    variable = rho_gas_1
    function = rho1_exact
  []
  [rho_water_0_ic]
    type = FunctionIC
    variable = rho_water_0
    function = rho_water_0_exact
  []
  [rho_water_1_ic]
    type = FunctionIC
    variable = rho_water_1
    function = rho_water_1_exact
  []
  [eta_oil_0_ic]
    type = FunctionIC
    variable = eta_oil_0
    function = eta0_exact
  []
  [eta_oil_1_ic]
    type = FunctionIC
    variable = eta_oil_1
    function = eta1_exact
  []
  [eta_gas_0_ic]
    type = FunctionIC
    variable = eta_gas_0
    function = eta0_exact
  []
  [eta_gas_1_ic]
    type = FunctionIC
    variable = eta_gas_1
    function = eta1_exact
  []
  [eta_water_0_ic]
    type = FunctionIC
    variable = eta_water_0
    function = eta_water_0_exact
  []
  [eta_water_1_ic]
    type = FunctionIC
    variable = eta_water_1
    function = eta_water_1_exact
  []
  [z0_ic]
    type = FunctionIC
    variable = z0
    function = eta0_exact
  []
  [z1_ic]
    type = FunctionIC
    variable = z1
    function = eta1_exact
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
  [kinematics]
    type = ADSolidReferenceKinematics
    displacements = 'ux'
  []
  [user_helmholtz]
    type = ADDerivativeParsedMaterial
    coupled_variables = 'rho0 rho1 temperature'
    property_name = oil_helmholtz_density
    constant_names = 'K rho_ref R'
    constant_expressions = '4 2 5'
    expression = '0.5*K*(rho0+rho1-rho_ref)^2 + R*temperature*(rho0*(log(rho0)-1)+rho1*(log(rho1)-1))'
    derivative_order = 2
    enable_jit = true
  []
  [oil_eos]
    type = ADHelmholtzEOSClosureMaterial
    phase = oil
    phase_registry = phases
    partial_densities = 'rho0 rho1'
    temperature = temperature
    porosity = phi_oil
    helmholtz_density_name = oil_helmholtz_density
  []
  [gas_eos]
    type = ADHelmholtzEOSClosureMaterial
    phase = gas
    phase_registry = phases
    partial_densities = 'rho0 rho1'
    temperature = temperature
    porosity = phi_gas
    helmholtz_density_name = oil_helmholtz_density
  []
  [water_eos]
    type = ADHelmholtzEOSClosureMaterial
    phase = water
    phase_registry = phases
    partial_densities = 'rho0 rho1'
    temperature = temperature
    porosity = phi_water
    helmholtz_density_name = oil_helmholtz_density
  []
  [flash]
    type = ADRegisteredPhaseFlashMaterial
    phase_registry = phases
    phases = 'oil gas water'
    components = 'component0 component1'
    equilibrium_reference_phase = oil
    total_phase_fraction = phi_total
    phase_volume_fractions = 'phi_oil phi_gas phi_water'
    phase_component_mass_fractions = 'eta_oil_0 eta_oil_1 eta_gas_0 eta_gas_1 eta_water_0 eta_water_1'
    overall_mass_fractions = 'z0 z1'
    phase_intrinsic_density_names = 'oil_intrinsic_density gas_intrinsic_density water_intrinsic_density'
    phase_pressure_names = 'oil_pressure_from_eos gas_pressure_from_eos water_pressure_from_eos'
    chemical_potential_names = 'oil_chemical_potential_0 oil_chemical_potential_1 gas_chemical_potential_0 gas_chemical_potential_1 water_chemical_potential_0 water_chemical_potential_1'
  []
[]

[AuxKernels]
  [storage0_aux]
    type = ADMaterialRealAux
    variable = storage0
    property = registered_flash_total_reference_component_storage_0
    execute_on = INITIAL
  []
  [storage1_aux]
    type = ADMaterialRealAux
    variable = storage1
    property = registered_flash_total_reference_component_storage_1
    execute_on = INITIAL
  []
  [oil_saturation_aux]
    type = ADMaterialRealAux
    variable = oil_saturation
    property = registered_flash_oil_saturation
    execute_on = INITIAL
  []
  [gas_saturation_aux]
    type = ADMaterialRealAux
    variable = gas_saturation
    property = registered_flash_gas_saturation
    execute_on = INITIAL
  []
  [water_active_aux]
    type = ADMaterialRealAux
    variable = water_active
    property = registered_flash_water_active
    execute_on = INITIAL
  []
  [volume_residual_aux]
    type = ADMaterialRealAux
    variable = volume_residual
    property = registered_flash_volume_constraint_residual
    execute_on = INITIAL
  []
  [gas_mu0_residual_aux]
    type = ADMaterialRealAux
    variable = gas_mu0_residual
    property = registered_flash_gas_chemical_equilibrium_residual_0
    execute_on = INITIAL
  []
  [water_mu0_residual_aux]
    type = ADMaterialRealAux
    variable = water_mu0_residual
    property = registered_flash_water_chemical_equilibrium_residual_0
    execute_on = INITIAL
  []
  [gas_pressure_residual_aux]
    type = ADMaterialRealAux
    variable = gas_pressure_residual
    property = registered_flash_gas_pressure_equilibrium_residual
    execute_on = INITIAL
  []
  [overall_z0_residual_aux]
    type = ADMaterialRealAux
    variable = overall_z0_residual
    property = registered_flash_overall_composition_residual_0
    execute_on = INITIAL
  []
[]

[Postprocessors]
  [storage0_l2]
    type = ElementL2Error
    variable = storage0
    function = storage0_exact
    execute_on = INITIAL
  []
  [storage1_l2]
    type = ElementL2Error
    variable = storage1
    function = storage1_exact
    execute_on = INITIAL
  []
  [oil_saturation_l2]
    type = ElementL2Error
    variable = oil_saturation
    function = oil_saturation_exact
    execute_on = INITIAL
  []
  [gas_saturation_l2]
    type = ElementL2Error
    variable = gas_saturation
    function = gas_saturation_exact
    execute_on = INITIAL
  []
  [water_active_l2]
    type = ElementL2Error
    variable = water_active
    function = zero
    execute_on = INITIAL
  []
  [volume_residual_l2]
    type = ElementL2Error
    variable = volume_residual
    function = zero
    execute_on = INITIAL
  []
  [gas_mu0_residual_l2]
    type = ElementL2Error
    variable = gas_mu0_residual
    function = zero
    execute_on = INITIAL
  []
  [water_mu0_residual_l2]
    type = ElementL2Error
    variable = water_mu0_residual
    function = zero
    execute_on = INITIAL
  []
  [gas_pressure_residual_l2]
    type = ElementL2Error
    variable = gas_pressure_residual
    function = zero
    execute_on = INITIAL
  []
  [overall_z0_residual_l2]
    type = ElementL2Error
    variable = overall_z0_residual
    function = zero
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
