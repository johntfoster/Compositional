[Mesh]
  type = GeneratedMesh
  dim = 1
  nx = 4
[]

[Variables]
  [phi_gas]
  []
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
  [volume_residual]
    family = MONOMIAL
    order = CONSTANT
  []
[]

[Functions]
  [zero]
    type = ParsedFunction
    expression = '0'
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
  [phi_gas_initial]
    type = ParsedFunction
    expression = '0.05'
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
[]

[ICs]
  [phi_gas_ic]
    type = FunctionIC
    variable = phi_gas
    function = phi_gas_initial
  []
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
  [volume_residual_aux]
    type = ADMaterialRealAux
    variable = volume_residual
    property = registered_flash_volume_constraint_residual
    execute_on = TIMESTEP_END
  []
[]

[Kernels]
  [volume_constraint]
    type = ADMaterialPropertyResidual
    variable = phi_gas
    property = registered_flash_volume_constraint_residual
  []
[]

[Postprocessors]
  [phi_gas_l2]
    type = ElementL2Error
    variable = phi_gas
    function = phi_gas_exact
  []
  [volume_residual_l2]
    type = ElementL2Error
    variable = volume_residual
    function = zero
  []
[]

[Executioner]
  type = Steady
  solve_type = NEWTON
  nl_rel_tol = 1e-12
  nl_abs_tol = 1e-12
[]

[Outputs]
  console = true
  csv = true
[]
