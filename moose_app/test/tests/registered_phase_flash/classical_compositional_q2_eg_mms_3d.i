mesh_nx := 3
mesh_ny := 2
mesh_nz := 2

[Mesh]
  type = GeneratedMesh
  dim = 3
  xmin = 0
  xmax = 1
  ymin = 0
  ymax = 1
  zmin = 0
  zmax = 1
  nx = ${mesh_nx}
  ny = ${mesh_ny}
  nz = ${mesh_nz}
  elem_type = TET10
[]

!include ../../../input/includes/fields/solid_q2_aux_3d.i
!include ../../../input/includes/fields/eg_registered_phase_pressures_aux.i

[Variables]
  [component0_reference_storage]
    family = LAGRANGE
    order = FIRST
  []
  [component1_reference_storage]
    family = LAGRANGE
    order = FIRST
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
  [rho0]
  []
  [rho1]
  []
  [eta_oil_0]
  []
  [eta_oil_1]
  []
  [eta_gas_0]
  []
  [eta_gas_1]
  []
  [z0]
  []
  [z1]
  []
  [component0_reference_source_aux]
    family = MONOMIAL
    order = CONSTANT
  []
  [component1_reference_source_aux]
    family = MONOMIAL
    order = CONSTANT
  []
  [component0_reference_storage_rate_aux]
    family = MONOMIAL
    order = CONSTANT
  []
  [component1_reference_storage_rate_aux]
    family = MONOMIAL
    order = CONSTANT
  []
[]

[Functions]
  [zero]
    type = ParsedFunction
    expression = '0'
  []
  [ux_exact]
    type = ParsedFunction
    expression = '0.1*x'
  []
  [uy_exact]
    type = ParsedFunction
    expression = '0.2*y'
  []
  [uz_exact]
    type = ParsedFunction
    expression = '0.3*z'
  []
  [solid_reference_jacobian_exact]
    type = ParsedFunction
    expression = '1.716'
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
  [phase_intrinsic_density_exact]
    type = ParsedFunction
    expression = '3'
  []
  # Let s=0.936*x+0.7865*y+0.67015384615384615385*z.  Since each production Darcy phase flux is
  # W=(-0.936,-0.7865,-0.67015384615384615385)=-Grad(s), so every
  # phase/component flux below has an independent analytic potential while
  # retaining nonzero x, y, and z transport.
  [eta_oil_0_exact]
    type = ParsedFunction
    expression = '0.7+0.1*(0.936*x+0.7865*y+0.67015384615384615385*z)'
  []
  [eta_oil_1_exact]
    type = ParsedFunction
    expression = '0.3-0.1*(0.936*x+0.7865*y+0.67015384615384615385*z)'
  []
  [eta_gas_0_exact]
    type = ParsedFunction
    expression = '0.2+0.05*(0.936*x+0.7865*y+0.67015384615384615385*z)'
  []
  [eta_gas_1_exact]
    type = ParsedFunction
    expression = '0.8-0.05*(0.936*x+0.7865*y+0.67015384615384615385*z)'
  []
  [z0_exact]
    type = ParsedFunction
    expression = '8/15+(0.936*x+0.7865*y+0.67015384615384615385*z)/12'
  []
  [z1_exact]
    type = ParsedFunction
    expression = '7/15-(0.936*x+0.7865*y+0.67015384615384615385*z)/12'
  []
  [pressure_backbone_exact]
    type = ParsedFunction
    expression = '1.75+x+y+z'
  []
  [pressure_enrichment_exact]
    type = ParsedFunction
    expression = '0.25'
  []
  [pressure_exact]
    type = ParsedFunction
    expression = '2+x+y+z'
  []

  # Direct summed Eq. (32) variables, with every phase contribution explicit:
  # sum_xi J phi_xi fluid_intrinsic_density_xi eta_xi_component.
  [direct_summed_eq32_component0_reference_storage_exact]
    type = ParsedFunction
    expression = '1.716*(0.2*3*(0.7+0.1*(0.936*x+0.7865*y+0.67015384615384615385*z))+0.1*3*(0.2+0.05*(0.936*x+0.7865*y+0.67015384615384615385*z)))'
  []
  [direct_summed_eq32_component1_reference_storage_exact]
    type = ParsedFunction
    expression = '1.716*(0.2*3*(0.3-0.1*(0.936*x+0.7865*y+0.67015384615384615385*z))+0.1*3*(0.8-0.05*(0.936*x+0.7865*y+0.67015384615384615385*z)))'
  []
  [oil_reference_relative_mass_flux_potential]
    type = ParsedFunction
    expression = '-0.936*x-0.7865*y-0.67015384615384615385*z'
  []
  [gas_reference_relative_mass_flux_potential]
    type = ParsedFunction
    expression = '-0.936*x-0.7865*y-0.67015384615384615385*z'
  []
  [oil_component0_reference_flux_potential]
    type = ParsedFunction
    expression = '-0.7*(0.936*x+0.7865*y+0.67015384615384615385*z)-0.05*(0.936*x+0.7865*y+0.67015384615384615385*z)^2'
  []
  [oil_component1_reference_flux_potential]
    type = ParsedFunction
    expression = '-0.3*(0.936*x+0.7865*y+0.67015384615384615385*z)+0.05*(0.936*x+0.7865*y+0.67015384615384615385*z)^2'
  []
  [gas_component0_reference_flux_potential]
    type = ParsedFunction
    expression = '-0.2*(0.936*x+0.7865*y+0.67015384615384615385*z)-0.025*(0.936*x+0.7865*y+0.67015384615384615385*z)^2'
  []
  [gas_component1_reference_flux_potential]
    type = ParsedFunction
    expression = '-0.8*(0.936*x+0.7865*y+0.67015384615384615385*z)+0.025*(0.936*x+0.7865*y+0.67015384615384615385*z)^2'
  []
  [component0_reference_flux_potential]
    type = ParsedFunction
    expression = '-0.9*(0.936*x+0.7865*y+0.67015384615384615385*z)-0.075*(0.936*x+0.7865*y+0.67015384615384615385*z)^2'
  []
  [component1_reference_flux_potential]
    type = ParsedFunction
    expression = '-1.1*(0.936*x+0.7865*y+0.67015384615384615385*z)+0.075*(0.936*x+0.7865*y+0.67015384615384615385*z)^2'
  []
  [component0_current_source_exact]
    type = ParsedFunction
    expression = '-0.291567664127218935/1.716'
  []
  [component1_current_source_exact]
    type = ParsedFunction
    expression = '0.291567664127218935/1.716'
  []
  [component0_reference_source_exact]
    type = ParsedFunction
    expression = '-0.291567664127218935'
  []
  [component1_reference_source_exact]
    type = ParsedFunction
    expression = '0.291567664127218935'
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
  [component0_reference_storage_ic]
    type = FunctionIC
    variable = component0_reference_storage
    function = direct_summed_eq32_component0_reference_storage_exact
  []
  [component1_reference_storage_ic]
    type = FunctionIC
    variable = component1_reference_storage
    function = direct_summed_eq32_component1_reference_storage_exact
  []
  [ux_ic]
    type = FunctionIC
    variable = ux
    function = ux_exact
  []
  [uy_ic]
    type = FunctionIC
    variable = uy
    function = uy_exact
  []
  [uz_ic]
    type = FunctionIC
    variable = uz
    function = uz_exact
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
  [eta_oil_0_ic]
    type = FunctionIC
    variable = eta_oil_0
    function = eta_oil_0_exact
  []
  [eta_oil_1_ic]
    type = FunctionIC
    variable = eta_oil_1
    function = eta_oil_1_exact
  []
  [eta_gas_0_ic]
    type = FunctionIC
    variable = eta_gas_0
    function = eta_gas_0_exact
  []
  [eta_gas_1_ic]
    type = FunctionIC
    variable = eta_gas_1
    function = eta_gas_1_exact
  []
  [z0_ic]
    type = FunctionIC
    variable = z0
    function = z0_exact
  []
  [z1_ic]
    type = FunctionIC
    variable = z1
    function = z1_exact
  []
  [pressure_oil_ic]
    type = FunctionIC
    variable = pressure_oil
    function = pressure_backbone_exact
  []
  [pressure_oil_enr_ic]
    type = FunctionIC
    variable = pressure_oil_enr
    function = pressure_enrichment_exact
  []
  [pressure_gas_ic]
    type = FunctionIC
    variable = pressure_gas
    function = pressure_backbone_exact
  []
  [pressure_gas_enr_ic]
    type = FunctionIC
    variable = pressure_gas_enr
    function = pressure_enrichment_exact
  []
  [pressure_water_ic]
    type = FunctionIC
    variable = pressure_water
    function = zero
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
    phases = 'solid oil gas'
    reference_phase = solid
    momentum_models = 'reference relative_flux relative_flux'
  []
[]

!include ../../../input/includes/materials/solid_kinematics_3d.i
!include ../../../input/includes/materials/eg_registered_phase_pressures_reconstruction.i

[Materials]
  [user_helmholtz]
    type = ADDerivativeParsedMaterial
    coupled_variables = 'rho0 rho1 temperature'
    property_name = compositional_helmholtz_density
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
    helmholtz_density_name = compositional_helmholtz_density
  []
  [gas_eos]
    type = ADHelmholtzEOSClosureMaterial
    phase = gas
    phase_registry = phases
    partial_densities = 'rho0 rho1'
    temperature = temperature
    porosity = phi_gas
    helmholtz_density_name = compositional_helmholtz_density
  []
  [flash]
    type = ADRegisteredPhaseFlashMaterial
    phase_registry = phases
    phases = 'oil gas'
    components = 'component0 component1'
    equilibrium_reference_phase = oil
    total_phase_fraction = phi_total
    phase_volume_fractions = 'phi_oil phi_gas'
    phase_component_mass_fractions = 'eta_oil_0 eta_oil_1 eta_gas_0 eta_gas_1'
    overall_mass_fractions = 'z0 z1'
    phase_intrinsic_density_names = 'oil_intrinsic_density gas_intrinsic_density'
    phase_pressure_names = 'oil_pressure_from_eos gas_pressure_from_eos'
    chemical_potential_names = 'oil_chemical_potential_0 oil_chemical_potential_1 gas_chemical_potential_0 gas_chemical_potential_1'
  []
  [oil_darcy]
    type = ADStandardDarcyReferenceFluxMaterial
    phase = oil
    phase_registry = phases
    pressure = pressure_oil
    pressure_enrichment = pressure_oil_enr
    intrinsic_density_source = material
    intrinsic_density_name = oil_intrinsic_density
    permeability = 0.22
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
    permeability = 0.22
    viscosity = 1
    reference_relative_mass_flux_name = gas_reference_relative_mass_flux
    darcy_mobility_ref_name = gas_darcy_mobility_ref
  []

  # The two conserved variables are the direct Eq. (32) sums. Keep every
  # phase contribution explicit: sum_xi J phi_xi
  # fluid_intrinsic_density_xi eta_xi_component.
  [direct_summed_eq32_component0_reference_storage]
    type = ADParsedMaterial
    coupled_variables = 'phi_oil eta_oil_0 phi_gas eta_gas_0'
    material_property_names = 'solid_reference_J oil_intrinsic_density gas_intrinsic_density'
    property_name = direct_summed_eq32_component0_reference_storage
    expression = 'solid_reference_J*(phi_oil*oil_intrinsic_density*eta_oil_0+phi_gas*gas_intrinsic_density*eta_gas_0)'
  []
  [direct_summed_eq32_component1_reference_storage]
    type = ADParsedMaterial
    coupled_variables = 'phi_oil eta_oil_1 phi_gas eta_gas_1'
    material_property_names = 'solid_reference_J oil_intrinsic_density gas_intrinsic_density'
    property_name = direct_summed_eq32_component1_reference_storage
    expression = 'solid_reference_J*(phi_oil*oil_intrinsic_density*eta_oil_1+phi_gas*gas_intrinsic_density*eta_gas_1)'
  []
  [steady_storage_rates]
    type = ADGenericConstantMaterial
    prop_names = 'direct_summed_eq32_component0_reference_storage_rate direct_summed_eq32_component1_reference_storage_rate'
    prop_values = '0 0'
  []

  [oil_component0_reference_flux]
    type = ADRegisteredPhaseComponentFluxMaterial
    phase_registry = phases
    phases = 'oil'
    component = 0
    phase_reference_relative_mass_flux_names = 'oil_reference_relative_mass_flux'
    phase_component_mass_fraction_names = 'registered_flash_oil_component_mass_fraction_0'
    phase_active_names = 'registered_flash_oil_active'
    reference_component_flux_name = oil_component0_reference_flux
    reference_component_source_name = oil_component0_reference_source
  []
  [oil_component1_reference_flux]
    type = ADRegisteredPhaseComponentFluxMaterial
    phase_registry = phases
    phases = 'oil'
    component = 1
    phase_reference_relative_mass_flux_names = 'oil_reference_relative_mass_flux'
    phase_component_mass_fraction_names = 'registered_flash_oil_component_mass_fraction_1'
    phase_active_names = 'registered_flash_oil_active'
    reference_component_flux_name = oil_component1_reference_flux
    reference_component_source_name = oil_component1_reference_source
  []
  [gas_component0_reference_flux]
    type = ADRegisteredPhaseComponentFluxMaterial
    phase_registry = phases
    phases = 'gas'
    component = 0
    phase_reference_relative_mass_flux_names = 'gas_reference_relative_mass_flux'
    phase_component_mass_fraction_names = 'registered_flash_gas_component_mass_fraction_0'
    phase_active_names = 'registered_flash_gas_active'
    reference_component_flux_name = gas_component0_reference_flux
    reference_component_source_name = gas_component0_reference_source
  []
  [gas_component1_reference_flux]
    type = ADRegisteredPhaseComponentFluxMaterial
    phase_registry = phases
    phases = 'gas'
    component = 1
    phase_reference_relative_mass_flux_names = 'gas_reference_relative_mass_flux'
    phase_component_mass_fraction_names = 'registered_flash_gas_component_mass_fraction_1'
    phase_active_names = 'registered_flash_gas_active'
    reference_component_flux_name = gas_component1_reference_flux
    reference_component_source_name = gas_component1_reference_source
  []
  [direct_summed_eq32_component0_reference_flux_and_source]
    type = ADRegisteredPhaseComponentFluxMaterial
    phase_registry = phases
    phases = 'oil gas'
    component = 0
    phase_reference_relative_mass_flux_names = 'oil_reference_relative_mass_flux gas_reference_relative_mass_flux'
    phase_component_mass_fraction_names = 'registered_flash_oil_component_mass_fraction_0 registered_flash_gas_component_mass_fraction_0'
    phase_active_names = 'registered_flash_oil_active registered_flash_gas_active'
    current_component_source = component0_current_source_exact
    reference_component_flux_name = direct_summed_eq32_component0_reference_flux
    reference_component_source_name = direct_summed_eq32_component0_reference_source
  []
  [direct_summed_eq32_component1_reference_flux_and_source]
    type = ADRegisteredPhaseComponentFluxMaterial
    phase_registry = phases
    phases = 'oil gas'
    component = 1
    phase_reference_relative_mass_flux_names = 'oil_reference_relative_mass_flux gas_reference_relative_mass_flux'
    phase_component_mass_fraction_names = 'registered_flash_oil_component_mass_fraction_1 registered_flash_gas_component_mass_fraction_1'
    phase_active_names = 'registered_flash_oil_active registered_flash_gas_active'
    current_component_source = component1_current_source_exact
    reference_component_flux_name = direct_summed_eq32_component1_reference_flux
    reference_component_source_name = direct_summed_eq32_component1_reference_source
  []
[]

[Kernels]
  [direct_summed_eq32_component0_balance]
    type = ADReferenceFluidComponentBalance
    variable = component0_reference_storage
    reference_component_flux = direct_summed_eq32_component0_reference_flux
    reference_component_source = direct_summed_eq32_component0_reference_source
  []
  [direct_summed_eq32_component1_balance]
    type = ADReferenceFluidComponentBalance
    variable = component1_reference_storage
    reference_component_flux = direct_summed_eq32_component1_reference_flux
    reference_component_source = direct_summed_eq32_component1_reference_source
  []
[]

[BCs]
  [component0_exact]
    type = FunctionDirichletBC
    variable = component0_reference_storage
    boundary = 'left right bottom top front back'
    function = direct_summed_eq32_component0_reference_storage_exact
  []
  [component1_exact]
    type = FunctionDirichletBC
    variable = component1_reference_storage
    boundary = 'left right bottom top front back'
    function = direct_summed_eq32_component1_reference_storage_exact
  []
[]

[AuxKernels]
  [component0_reference_source_aux]
    type = ADMaterialRealAux
    variable = component0_reference_source_aux
    property = direct_summed_eq32_component0_reference_source
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [component1_reference_source_aux]
    type = ADMaterialRealAux
    variable = component1_reference_source_aux
    property = direct_summed_eq32_component1_reference_source
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [component0_reference_storage_rate_aux]
    type = ADMaterialRealAux
    variable = component0_reference_storage_rate_aux
    property = direct_summed_eq32_component0_reference_storage_rate
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [component1_reference_storage_rate_aux]
    type = ADMaterialRealAux
    variable = component1_reference_storage_rate_aux
    property = direct_summed_eq32_component1_reference_storage_rate
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]

[Postprocessors]
  [ux_l2]
    type = ElementL2Error
    variable = ux
    function = ux_exact
  []
  [uy_l2]
    type = ElementL2Error
    variable = uy
    function = uy_exact
  []
  [uz_l2]
    type = ElementL2Error
    variable = uz
    function = uz_exact
  []
  [solid_reference_jacobian_l2]
    type = ADMaterialScalarL2Error
    property = solid_reference_J
    function = solid_reference_jacobian_exact
  []
  [oil_pressure_backbone_l2]
    type = ElementL2Error
    variable = pressure_oil
    function = pressure_backbone_exact
  []
  [oil_pressure_reconstructed_l2]
    type = ADMaterialScalarL2Error
    property = pressure_oil_total
    function = pressure_exact
  []
  [oil_pressure_enrichment_l2]
    type = ElementL2Error
    variable = pressure_oil_enr
    function = pressure_enrichment_exact
  []
  [gas_pressure_backbone_l2]
    type = ElementL2Error
    variable = pressure_gas
    function = pressure_backbone_exact
  []
  [gas_pressure_enrichment_l2]
    type = ElementL2Error
    variable = pressure_gas_enr
    function = pressure_enrichment_exact
  []
  [gas_pressure_reconstructed_l2]
    type = ADMaterialScalarL2Error
    property = pressure_gas_total
    function = pressure_exact
  []
  [oil_intrinsic_density_l2]
    type = ADMaterialScalarL2Error
    property = oil_intrinsic_density
    function = phase_intrinsic_density_exact
  []
  [gas_intrinsic_density_l2]
    type = ADMaterialScalarL2Error
    property = gas_intrinsic_density
    function = phase_intrinsic_density_exact
  []
  [component0_primary_l2]
    type = ElementL2Error
    variable = component0_reference_storage
    function = direct_summed_eq32_component0_reference_storage_exact
  []
  [component1_primary_l2]
    type = ElementL2Error
    variable = component1_reference_storage
    function = direct_summed_eq32_component1_reference_storage_exact
  []
  [component0_direct_storage_l2]
    type = ADMaterialScalarL2Error
    property = direct_summed_eq32_component0_reference_storage
    function = direct_summed_eq32_component0_reference_storage_exact
  []
  [component1_direct_storage_l2]
    type = ADMaterialScalarL2Error
    property = direct_summed_eq32_component1_reference_storage
    function = direct_summed_eq32_component1_reference_storage_exact
  []
  [component0_flash_storage_l2]
    type = ADMaterialScalarL2Error
    property = registered_flash_total_reference_component_storage_0
    function = direct_summed_eq32_component0_reference_storage_exact
  []
  [component1_flash_storage_l2]
    type = ADMaterialScalarL2Error
    property = registered_flash_total_reference_component_storage_1
    function = direct_summed_eq32_component1_reference_storage_exact
  []
  [flash_volume_constraint_l2]
    type = ADMaterialScalarL2Error
    property = registered_flash_volume_constraint_residual
    function = zero
  []
  [flash_oil_composition_closure_l2]
    type = ADMaterialScalarL2Error
    property = registered_flash_oil_component_mass_fraction_residual
    function = zero
  []
  [flash_gas_composition_closure_l2]
    type = ADMaterialScalarL2Error
    property = registered_flash_gas_component_mass_fraction_residual
    function = zero
  []
  [flash_component0_overall_closure_l2]
    type = ADMaterialScalarL2Error
    property = registered_flash_overall_composition_residual_0
    function = zero
  []
  [flash_component1_overall_closure_l2]
    type = ADMaterialScalarL2Error
    property = registered_flash_overall_composition_residual_1
    function = zero
  []
  [flash_gas_pressure_equilibrium_l2]
    type = ADMaterialScalarL2Error
    property = registered_flash_gas_pressure_equilibrium_residual
    function = zero
  []
  [flash_gas_component0_chemical_equilibrium_l2]
    type = ADMaterialScalarL2Error
    property = registered_flash_gas_chemical_equilibrium_residual_0
    function = zero
  []
  [flash_gas_component1_chemical_equilibrium_l2]
    type = ADMaterialScalarL2Error
    property = registered_flash_gas_chemical_equilibrium_residual_1
    function = zero
  []
  [oil_saturation_l2]
    type = ADMaterialScalarL2Error
    property = registered_flash_oil_saturation
    function = oil_saturation_exact
  []
  [gas_saturation_l2]
    type = ADMaterialScalarL2Error
    property = registered_flash_gas_saturation
    function = gas_saturation_exact
  []
  [oil_component0_composition_l2]
    type = ADMaterialScalarL2Error
    property = registered_flash_oil_component_mass_fraction_0
    function = eta_oil_0_exact
  []
  [oil_component1_composition_l2]
    type = ADMaterialScalarL2Error
    property = registered_flash_oil_component_mass_fraction_1
    function = eta_oil_1_exact
  []
  [gas_component0_composition_l2]
    type = ADMaterialScalarL2Error
    property = registered_flash_gas_component_mass_fraction_0
    function = eta_gas_0_exact
  []
  [gas_component1_composition_l2]
    type = ADMaterialScalarL2Error
    property = registered_flash_gas_component_mass_fraction_1
    function = eta_gas_1_exact
  []
  [oil_reference_relative_mass_flux_l2]
    type = ADMaterialVectorL2Error
    property = oil_reference_relative_mass_flux
    gradient_function = oil_reference_relative_mass_flux_potential
  []
  [gas_reference_relative_mass_flux_l2]
    type = ADMaterialVectorL2Error
    property = gas_reference_relative_mass_flux
    gradient_function = gas_reference_relative_mass_flux_potential
  []
  [oil_component0_reference_flux_l2]
    type = ADMaterialVectorL2Error
    property = oil_component0_reference_flux
    gradient_function = oil_component0_reference_flux_potential
  []
  [oil_component1_reference_flux_l2]
    type = ADMaterialVectorL2Error
    property = oil_component1_reference_flux
    gradient_function = oil_component1_reference_flux_potential
  []
  [gas_component0_reference_flux_l2]
    type = ADMaterialVectorL2Error
    property = gas_component0_reference_flux
    gradient_function = gas_component0_reference_flux_potential
  []
  [gas_component1_reference_flux_l2]
    type = ADMaterialVectorL2Error
    property = gas_component1_reference_flux
    gradient_function = gas_component1_reference_flux_potential
  []
  [component0_reference_flux_l2]
    type = ADMaterialVectorL2Error
    property = direct_summed_eq32_component0_reference_flux
    gradient_function = component0_reference_flux_potential
  []
  [component1_reference_flux_l2]
    type = ADMaterialVectorL2Error
    property = direct_summed_eq32_component1_reference_flux
    gradient_function = component1_reference_flux_potential
  []
  [component0_reference_source_l2]
    type = ADMaterialScalarL2Error
    property = direct_summed_eq32_component0_reference_source
    function = component0_reference_source_exact
  []
  [component1_reference_source_l2]
    type = ADMaterialScalarL2Error
    property = direct_summed_eq32_component1_reference_source
    function = component1_reference_source_exact
  []

  [component0_reference_storage_rate_integral]
    type = ElementIntegralVariablePostprocessor
    variable = component0_reference_storage_rate_aux
  []
  [component1_reference_storage_rate_integral]
    type = ElementIntegralVariablePostprocessor
    variable = component1_reference_storage_rate_aux
  []
  [component0_reference_source_integral]
    type = ElementIntegralVariablePostprocessor
    variable = component0_reference_source_aux
  []
  [component1_reference_source_integral]
    type = ElementIntegralVariablePostprocessor
    variable = component1_reference_source_aux
  []
  [component0_left_reference_flux]
    type = ADSideIntegralMaterialProperty
    boundary = left
    property = direct_summed_eq32_component0_reference_flux
    component = 0
  []
  [component0_right_reference_flux]
    type = ADSideIntegralMaterialProperty
    boundary = right
    property = direct_summed_eq32_component0_reference_flux
    component = 0
  []
  [component0_bottom_reference_flux]
    type = ADSideIntegralMaterialProperty
    boundary = bottom
    property = direct_summed_eq32_component0_reference_flux
    component = 1
  []
  [component0_top_reference_flux]
    type = ADSideIntegralMaterialProperty
    boundary = top
    property = direct_summed_eq32_component0_reference_flux
    component = 1
  []
  [component0_front_reference_flux]
    type = ADSideIntegralMaterialProperty
    boundary = front
    property = direct_summed_eq32_component0_reference_flux
    component = 2
  []
  [component0_back_reference_flux]
    type = ADSideIntegralMaterialProperty
    boundary = back
    property = direct_summed_eq32_component0_reference_flux
    component = 2
  []
  [component1_left_reference_flux]
    type = ADSideIntegralMaterialProperty
    boundary = left
    property = direct_summed_eq32_component1_reference_flux
    component = 0
  []
  [component1_right_reference_flux]
    type = ADSideIntegralMaterialProperty
    boundary = right
    property = direct_summed_eq32_component1_reference_flux
    component = 0
  []
  [component1_bottom_reference_flux]
    type = ADSideIntegralMaterialProperty
    boundary = bottom
    property = direct_summed_eq32_component1_reference_flux
    component = 1
  []
  [component1_top_reference_flux]
    type = ADSideIntegralMaterialProperty
    boundary = top
    property = direct_summed_eq32_component1_reference_flux
    component = 1
  []
  [component1_front_reference_flux]
    type = ADSideIntegralMaterialProperty
    boundary = front
    property = direct_summed_eq32_component1_reference_flux
    component = 2
  []
  [component1_back_reference_flux]
    type = ADSideIntegralMaterialProperty
    boundary = back
    property = direct_summed_eq32_component1_reference_flux
    component = 2
  []
  [oil_component0_left_reference_flux]
    type = ADSideIntegralMaterialProperty
    boundary = left
    property = oil_component0_reference_flux
    component = 0
  []
  [oil_component0_right_reference_flux]
    type = ADSideIntegralMaterialProperty
    boundary = right
    property = oil_component0_reference_flux
    component = 0
  []
  [oil_component0_bottom_reference_flux]
    type = ADSideIntegralMaterialProperty
    boundary = bottom
    property = oil_component0_reference_flux
    component = 1
  []
  [oil_component0_top_reference_flux]
    type = ADSideIntegralMaterialProperty
    boundary = top
    property = oil_component0_reference_flux
    component = 1
  []
  [oil_component0_front_reference_flux]
    type = ADSideIntegralMaterialProperty
    boundary = front
    property = oil_component0_reference_flux
    component = 2
  []
  [oil_component0_back_reference_flux]
    type = ADSideIntegralMaterialProperty
    boundary = back
    property = oil_component0_reference_flux
    component = 2
  []
  [oil_component1_left_reference_flux]
    type = ADSideIntegralMaterialProperty
    boundary = left
    property = oil_component1_reference_flux
    component = 0
  []
  [oil_component1_right_reference_flux]
    type = ADSideIntegralMaterialProperty
    boundary = right
    property = oil_component1_reference_flux
    component = 0
  []
  [oil_component1_bottom_reference_flux]
    type = ADSideIntegralMaterialProperty
    boundary = bottom
    property = oil_component1_reference_flux
    component = 1
  []
  [oil_component1_top_reference_flux]
    type = ADSideIntegralMaterialProperty
    boundary = top
    property = oil_component1_reference_flux
    component = 1
  []
  [oil_component1_front_reference_flux]
    type = ADSideIntegralMaterialProperty
    boundary = front
    property = oil_component1_reference_flux
    component = 2
  []
  [oil_component1_back_reference_flux]
    type = ADSideIntegralMaterialProperty
    boundary = back
    property = oil_component1_reference_flux
    component = 2
  []
  [gas_component0_left_reference_flux]
    type = ADSideIntegralMaterialProperty
    boundary = left
    property = gas_component0_reference_flux
    component = 0
  []
  [gas_component0_right_reference_flux]
    type = ADSideIntegralMaterialProperty
    boundary = right
    property = gas_component0_reference_flux
    component = 0
  []
  [gas_component0_bottom_reference_flux]
    type = ADSideIntegralMaterialProperty
    boundary = bottom
    property = gas_component0_reference_flux
    component = 1
  []
  [gas_component0_top_reference_flux]
    type = ADSideIntegralMaterialProperty
    boundary = top
    property = gas_component0_reference_flux
    component = 1
  []
  [gas_component0_front_reference_flux]
    type = ADSideIntegralMaterialProperty
    boundary = front
    property = gas_component0_reference_flux
    component = 2
  []
  [gas_component0_back_reference_flux]
    type = ADSideIntegralMaterialProperty
    boundary = back
    property = gas_component0_reference_flux
    component = 2
  []
  [gas_component1_left_reference_flux]
    type = ADSideIntegralMaterialProperty
    boundary = left
    property = gas_component1_reference_flux
    component = 0
  []
  [gas_component1_right_reference_flux]
    type = ADSideIntegralMaterialProperty
    boundary = right
    property = gas_component1_reference_flux
    component = 0
  []
  [gas_component1_bottom_reference_flux]
    type = ADSideIntegralMaterialProperty
    boundary = bottom
    property = gas_component1_reference_flux
    component = 1
  []
  [gas_component1_top_reference_flux]
    type = ADSideIntegralMaterialProperty
    boundary = top
    property = gas_component1_reference_flux
    component = 1
  []
  [gas_component1_front_reference_flux]
    type = ADSideIntegralMaterialProperty
    boundary = front
    property = gas_component1_reference_flux
    component = 2
  []
  [gas_component1_back_reference_flux]
    type = ADSideIntegralMaterialProperty
    boundary = back
    property = gas_component1_reference_flux
    component = 2
  []
  [component0_net_outward_reference_flux]
    type = LinearCombinationPostprocessor
    pp_names = 'component0_right_reference_flux component0_left_reference_flux component0_top_reference_flux component0_bottom_reference_flux component0_front_reference_flux component0_back_reference_flux'
    pp_coefs = '1 -1 1 -1 1 -1'
  []
  [component1_net_outward_reference_flux]
    type = LinearCombinationPostprocessor
    pp_names = 'component1_right_reference_flux component1_left_reference_flux component1_top_reference_flux component1_bottom_reference_flux component1_front_reference_flux component1_back_reference_flux'
    pp_coefs = '1 -1 1 -1 1 -1'
  []
  [direct_summed_eq32_component0_global_balance]
    type = LinearCombinationPostprocessor
    pp_names = 'component0_reference_storage_rate_integral component0_net_outward_reference_flux component0_reference_source_integral'
    pp_coefs = '1 1 -1'
  []
  [direct_summed_eq32_component1_global_balance]
    type = LinearCombinationPostprocessor
    pp_names = 'component1_reference_storage_rate_integral component1_net_outward_reference_flux component1_reference_source_integral'
    pp_coefs = '1 1 -1'
  []
[]

[Executioner]
  type = Transient
  scheme = implicit-euler
  start_time = 0
  dt = 1
  num_steps = 1
  solve_type = NEWTON
  nl_abs_tol = 1e-12
  nl_rel_tol = 1e-12
[]

[Outputs]
  csv = true
[]
