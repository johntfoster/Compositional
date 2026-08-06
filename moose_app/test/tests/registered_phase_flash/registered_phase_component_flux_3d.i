mesh_nx := 3
mesh_ny := 3
mesh_nz := 3

!include ../../../input/includes/mesh/generated_3d_q2.i
!include ../../../input/includes/fields/solid_q2_aux_3d.i
!include ../../../input/includes/fields/eg_registered_phase_pressures_aux.i

[Variables]
  [component_storage]
  []
[]

[AuxVariables]
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
  [storage0_from_flash]
    family = MONOMIAL
    order = CONSTANT
  []
  [component_flux_x]
    family = MONOMIAL
    order = CONSTANT
  []
  [component_flux_y]
    family = MONOMIAL
    order = CONSTANT
  []
  [component_flux_z]
    family = MONOMIAL
    order = CONSTANT
  []
[]

[Functions]
  [zero]
    type = ParsedFunction
    expression = '0'
  []
  [zero_vector]
    type = ParsedVectorFunction
    expression_x = '0'
    expression_y = '0'
    expression_z = '0'
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
  [pressure_oil_exact]
    type = ParsedFunction
    expression = 'x + y + z'
  []
  [pressure_gas_exact]
    type = ParsedFunction
    expression = '2*x - y + 0.5*z'
  []
  [pressure_water_exact]
    type = ParsedFunction
    expression = '5*x + 7*y - z'
  []
  [storage0_exact]
    type = ParsedFunction
    expression = '0.3'
  []
  [component_flux_x_exact]
    type = ParsedFunction
    expression = '-5/3'
  []
  [component_flux_y_exact]
    type = ParsedFunction
    expression = '-2/3'
  []
  [component_flux_z_exact]
    type = ParsedFunction
    expression = '-7/6'
  []
[]

[ICs]
  [component_storage_ic]
    type = FunctionIC
    variable = component_storage
    function = storage0_exact
  []
  [ux_ic]
    type = FunctionIC
    variable = ux
    function = zero
  []
  [uy_ic]
    type = FunctionIC
    variable = uy
    function = zero
  []
  [uz_ic]
    type = FunctionIC
    variable = uz
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
  [pressure_oil_ic]
    type = FunctionIC
    variable = pressure_oil
    function = pressure_oil_exact
  []
  [pressure_oil_enr_ic]
    type = FunctionIC
    variable = pressure_oil_enr
    function = zero
  []
  [pressure_gas_ic]
    type = FunctionIC
    variable = pressure_gas
    function = pressure_gas_exact
  []
  [pressure_gas_enr_ic]
    type = FunctionIC
    variable = pressure_gas_enr
    function = zero
  []
  [pressure_water_ic]
    type = FunctionIC
    variable = pressure_water
    function = pressure_water_exact
  []
  [pressure_water_enr_ic]
    type = FunctionIC
    variable = pressure_water_enr
    function = zero
  []
[]

[UserObjects]
  [phases]
    type = PhaseRegistry
    phases = 'solid oil gas water'
    reference_phase = solid
  []
[]

!include ../../../input/includes/materials/solid_kinematics_3d.i
!include ../../../input/includes/materials/eg_registered_phase_pressures_reconstruction.i

[Materials]
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
  [oil_darcy]
    type = ADStandardDarcyReferenceFluxMaterial
    phase = oil
    phase_registry = phases
    pressure = pressure_oil
    pressure_enrichment = pressure_oil_enr
    intrinsic_density_source = material
    intrinsic_density_name = oil_intrinsic_density
    permeability = 1
    viscosity = 1
    reference_relative_mass_flux_name = oil_reference_relative_mass_flux
    darcy_mobility_ref_name = oil_darcy_mobility_ref
  []
  [gas_darcy]
    type = ADStandardDarcyReferenceFluxMaterial
    phase = gas
    phase_registry = phases
    pressure = pressure_gas
    pressure_enrichment = pressure_gas_enr
    intrinsic_density_source = material
    intrinsic_density_name = gas_intrinsic_density
    permeability = 0.3333333333333333
    viscosity = 1
    reference_relative_mass_flux_name = gas_reference_relative_mass_flux
    darcy_mobility_ref_name = gas_darcy_mobility_ref
  []
  [water_darcy]
    type = ADStandardDarcyReferenceFluxMaterial
    phase = water
    phase_registry = phases
    pressure = pressure_water
    pressure_enrichment = pressure_water_enr
    intrinsic_density_source = material
    intrinsic_density_name = water_intrinsic_density
    permeability = 10
    viscosity = 1
    reference_relative_mass_flux_name = water_reference_relative_mass_flux
    darcy_mobility_ref_name = water_darcy_mobility_ref
  []
  [component_flux]
    type = ADRegisteredPhaseComponentFluxMaterial
    phase_registry = phases
    phases = 'oil gas water'
    component = 0
    phase_reference_relative_mass_flux_names = 'oil_reference_relative_mass_flux gas_reference_relative_mass_flux water_reference_relative_mass_flux'
    phase_component_mass_fraction_names = 'registered_flash_oil_component_mass_fraction_0 registered_flash_gas_component_mass_fraction_0 registered_flash_water_component_mass_fraction_0'
    phase_active_names = 'registered_flash_oil_active registered_flash_gas_active registered_flash_water_active'
    current_component_extra_flux = zero_vector
    current_component_source = zero
  []
[]

[AuxKernels]
  [storage0_aux]
    type = ADMaterialRealAux
    variable = storage0_from_flash
    property = registered_flash_total_reference_component_storage_0
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [component_flux_x_aux]
    type = ADMaterialRealVectorValueAux
    variable = component_flux_x
    property = reference_component_flux
    component = 0
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [component_flux_y_aux]
    type = ADMaterialRealVectorValueAux
    variable = component_flux_y
    property = reference_component_flux
    component = 1
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [component_flux_z_aux]
    type = ADMaterialRealVectorValueAux
    variable = component_flux_z
    property = reference_component_flux
    component = 2
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]

[Kernels]
  [component_balance]
    type = ADReferenceFluidComponentBalance
    variable = component_storage
  []
[]

[BCs]
  [exact]
    type = FunctionDirichletBC
    variable = component_storage
    boundary = 'left right bottom top back front'
    function = storage0_exact
  []
[]

[Postprocessors]
  [component_l2]
    type = ElementL2Error
    variable = component_storage
    function = storage0_exact
  []
  [storage0_l2]
    type = ElementL2Error
    variable = storage0_from_flash
    function = storage0_exact
  []
  [component_flux_x_l2]
    type = ElementL2Error
    variable = component_flux_x
    function = component_flux_x_exact
  []
  [component_flux_y_l2]
    type = ElementL2Error
    variable = component_flux_y
    function = component_flux_y_exact
  []
  [component_flux_z_l2]
    type = ElementL2Error
    variable = component_flux_z
    function = component_flux_z_exact
  []
[]

[Executioner]
  type = Transient
  start_time = 0
  dt = 1
  num_steps = 1
  solve_type = NEWTON
  nl_rel_tol = 1e-12
  nl_abs_tol = 1e-12
[]

[Outputs]
  console = true
  csv = true
[]
