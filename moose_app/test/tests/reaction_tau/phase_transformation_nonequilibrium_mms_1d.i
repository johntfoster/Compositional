mesh_nx := 6
solve_dt := 0.1

!include ../../../input/includes/mesh/generated_1d_q2.i

[Variables]
  [rho_o]
    family = LAGRANGE
    order = FIRST
  []
  [rho_g]
    family = LAGRANGE
    order = FIRST
  []
  [transformation_rate]
    family = LAGRANGE
    order = FIRST
  []
  [tau]
    family = LAGRANGE
    order = FIRST
  []
  [tau_enr]
    family = MONOMIAL
    order = CONSTANT
  []
  [oil_velocity]
    family = LAGRANGE
    order = FIRST
  []
  [gas_velocity]
    family = LAGRANGE
    order = FIRST
  []
  [temperature]
    family = LAGRANGE
    order = FIRST
  []
[]

[AuxVariables]
  [ux]
    family = LAGRANGE
    order = SECOND
  []
  [porosity]
  []
  [pressure_potential]
  []
  [oil_bulk_density]
  []
  [gas_bulk_density]
  []
  [oil_phase_fraction]
  []
  [gas_phase_fraction]
  []
  [dissipation]
    family = MONOMIAL
    order = CONSTANT
  []
[]

[Functions]
  [zero]
    type = ParsedFunction
    expression = '0'
  []
  [rho_o_exact]
    type = ParsedFunction
    expression = '1.4375+0.5625*pow(1.4,-t/0.1)'
  []
  [rho_g_exact]
    type = ParsedFunction
    expression = '1.5625-0.5625*pow(1.4,-t/0.1)'
  []
  [rate_exact]
    type = ParsedFunction
    expression = '1.125*pow(1.4,-t/0.1)'
  []
  [affinity_exact]
    type = ParsedFunction
    expression = '-0.125+1.125*pow(1.4,-t/0.1)'
  []
  [transfer_correction_exact]
    type = ParsedFunction
    expression = '-0.125'
  []
  [reaction_power_exact]
    type = ParsedFunction
    expression = 'pow(1.125*pow(1.4,-t/0.1),2)'
  []
  [temperature_exact]
    type = ParsedFunction
    expression = '1+0.03515625*(1-pow(1.4,-t/0.1))'
  []
  [tau_initial]
    type = ParsedFunction
    expression = 'x'
  []
  [tau_exact]
    type = ParsedFunction
    expression = 'x+3*t'
  []
  [oil_tau_offset_exact]
    type = ParsedFunction
    expression = '3'
  []
  [gas_tau_offset_exact]
    type = ParsedFunction
    expression = '2.875'
  []
  [oil_velocity_exact]
    type = ParsedFunction
    expression = '0'
  []
  [gas_velocity_exact]
    type = ParsedFunction
    expression = '0.5'
  []
  [oil_momentum_forcing]
    type = ParsedFunction
    expression = '1.125*pow(1.4,-t/0.1)'
  []
  [gas_momentum_forcing]
    type = ParsedFunction
    expression = '0.5-0.5*1.125*pow(1.4,-t/0.1)'
  []
[]

[ICs]
  [rho_o_ic]
    type = FunctionIC
    variable = rho_o
    function = rho_o_exact
  []
  [rho_g_ic]
    type = FunctionIC
    variable = rho_g
    function = rho_g_exact
  []
  [rate_ic]
    type = FunctionIC
    variable = transformation_rate
    function = rate_exact
  []
  [tau_ic]
    type = FunctionIC
    variable = tau
    function = tau_initial
  []
  [oil_velocity_ic]
    type = FunctionIC
    variable = oil_velocity
    function = oil_velocity_exact
  []
  [gas_velocity_ic]
    type = FunctionIC
    variable = gas_velocity
    function = gas_velocity_exact
  []
  [temperature_ic]
    type = FunctionIC
    variable = temperature
    function = temperature_exact
  []
  [porosity_ic]
    type = ConstantIC
    variable = porosity
    value = 0.5
  []
  [oil_bulk_density_ic]
    type = ConstantIC
    variable = oil_bulk_density
    value = 1
  []
  [gas_bulk_density_ic]
    type = ConstantIC
    variable = gas_bulk_density
    value = 1
  []
  [oil_phase_fraction_ic]
    type = ConstantIC
    variable = oil_phase_fraction
    value = 0.5
  []
  [gas_phase_fraction_ic]
    type = ConstantIC
    variable = gas_phase_fraction
    value = 0.5
  []
[]

[UserObjects]
  [phases]
    type = PhaseRegistry
    phases = 'solid oil gas'
    reference_phase = solid
    momentum_models = 'reference full full'
  []
[]

!include ../../../input/includes/materials/solid_kinematics_1d.i

[Materials]
  [thermodynamic_constants]
    type = ADGenericConstantMaterial
    prop_names = 'reference_neutral_mu reference_specific_helmholtz reference_pressure_work oil_active gas_active'
    prop_values = '5 1 1 1 1'
  []
  [zero_relative_fluxes]
    type = ADGenericConstantVectorMaterial
    prop_names = 'oil_reference_relative_mass_flux gas_reference_relative_mass_flux'
    prop_values = '0 0 0 0 0 0'
  []
  [oil_helmholtz]
    type = ADDerivativeParsedMaterial
    coupled_variables = 'rho_o temperature'
    property_name = oil_helmholtz_density
    expression = '0.5*rho_o^2'
    derivative_order = 2
    enable_jit = true
  []
  [gas_helmholtz]
    type = ADDerivativeParsedMaterial
    coupled_variables = 'rho_g temperature'
    property_name = gas_helmholtz_density
    expression = '0.5*rho_g^2'
    derivative_order = 2
    enable_jit = true
  []
  [oil_eos]
    type = ADHelmholtzEOSClosureMaterial
    phase = oil
    phase_registry = phases
    partial_densities = rho_o
    temperature = temperature
    porosity = porosity
    helmholtz_density_name = oil_helmholtz_density
  []
  [gas_eos]
    type = ADHelmholtzEOSClosureMaterial
    phase = gas
    phase_registry = phases
    partial_densities = rho_g
    temperature = temperature
    porosity = porosity
    helmholtz_density_name = gas_helmholtz_density
  []
  [tau_evolution]
    type = ADTauEvolutionMaterial
    tau = tau
    tau_enrichment = tau_enr
    reference_phase_velocity = ux
    reference_neutral_potential_name = reference_neutral_mu
    reference_specific_helmholtz_name = reference_specific_helmholtz
    reference_pressure_work_name = reference_pressure_work
  []
  [oil_tau_derivative]
    type = ADPhaseTauMaterialDerivative
    phase = oil
    phase_registry = phases
    phase_kind = mobile
    tau = tau
    tau_enrichment = tau_enr
    phase_velocity = oil_velocity
    bulk_density_name = oil_bulk_phase_density
    reference_relative_mass_flux_name = oil_reference_relative_mass_flux
    phase_active_name = oil_active
  []
  [gas_tau_derivative]
    type = ADPhaseTauMaterialDerivative
    phase = gas
    phase_registry = phases
    phase_kind = mobile
    tau = tau
    tau_enrichment = tau_enr
    phase_velocity = gas_velocity
    bulk_density_name = gas_bulk_phase_density
    reference_relative_mass_flux_name = gas_reference_relative_mass_flux
    phase_active_name = gas_active
  []
  [phase_transformation]
    type = ADReactionNetworkMaterial
    phase_registry = phases
    phases = 'oil gas'
    components = component0
    reaction_rates = transformation_rate
    stoichiometric_coefficients = '-1 1'
    chemical_potential_names = 'oil_chemical_potential_0 gas_chemical_potential_0'
    phase_tau_offset_names = 'oil_tau_transfer_offset gas_tau_transfer_offset'
    kinetic_mobilities = '1'
    property_prefix = phase_transfer
  []
[]

[Kernels]
  [oil_component_storage]
    type = ADReferenceComponentStorageTerm
    variable = rho_o
    coefficient = 0.5
  []
  [oil_component_conversion]
    type = ADReferenceComponentSourceTerm
    variable = rho_o
    reference_source_name = phase_transfer_oil_reference_component_source_0
  []
  [gas_component_storage]
    type = ADReferenceComponentStorageTerm
    variable = rho_g
    coefficient = 0.5
  []
  [gas_component_conversion]
    type = ADReferenceComponentSourceTerm
    variable = rho_g
    reference_source_name = phase_transfer_gas_reference_component_source_0
  []
  [finite_rate_closure]
    type = ADMaterialPropertyResidual
    variable = transformation_rate
    property = phase_transfer_kinetic_residual_0
  []
  [tau_backbone]
    type = ADEnrichedGalerkinMaterialPropertyResidual
    variable = tau
    property = tau_evolution_residual
  []
  [tau_enrichment]
    type = ADEnrichedGalerkinMaterialPropertyResidual
    variable = tau_enr
    property = tau_evolution_residual
    anchor_coefficient = 1
  []
  [oil_inertia]
    type = ADPhaseMomentumInertiaTerm
    variable = oil_velocity
    component = 0
    phase_velocity = oil_velocity
    solid_displacements = ux
    bulk_density = oil_bulk_density
  []
  [oil_pressure_force]
    type = ADPhaseMomentumScalarGradientTerm
    variable = oil_velocity
    component = 0
    potential = pressure_potential
    coefficient_variable = oil_phase_fraction
  []
  [oil_drag]
    type = ADPhaseMomentumDragTerm
    variable = oil_velocity
    component = 0
    phase_velocity = oil_velocity
    solid_displacements = ux
    phase_fraction = oil_phase_fraction
    viscosity = 4
    permeability = 1
  []
  [oil_conversion_insertion]
    type = ADPhaseMomentumConversionInsertionTerm
    variable = oil_velocity
    component = 0
    conversion_rate = transformation_rate
    rate_scale = -1
    tau = tau
    tau_enrichment = tau_enr
    phase_velocity_component = oil_velocity
  []
  [oil_manufactured_source]
    type = ADPhaseMomentumFunctionSourceTerm
    variable = oil_velocity
    source = oil_momentum_forcing
  []
  [gas_inertia]
    type = ADPhaseMomentumInertiaTerm
    variable = gas_velocity
    component = 0
    phase_velocity = gas_velocity
    solid_displacements = ux
    bulk_density = gas_bulk_density
  []
  [gas_pressure_force]
    type = ADPhaseMomentumScalarGradientTerm
    variable = gas_velocity
    component = 0
    potential = pressure_potential
    coefficient_variable = gas_phase_fraction
  []
  [gas_drag]
    type = ADPhaseMomentumDragTerm
    variable = gas_velocity
    component = 0
    phase_velocity = gas_velocity
    solid_displacements = ux
    phase_fraction = gas_phase_fraction
    viscosity = 4
    permeability = 1
  []
  [gas_conversion_insertion]
    type = ADPhaseMomentumConversionInsertionTerm
    variable = gas_velocity
    component = 0
    conversion_rate = transformation_rate
    rate_scale = 1
    tau = tau
    tau_enrichment = tau_enr
    phase_velocity_component = gas_velocity
  []
  [gas_manufactured_source]
    type = ADPhaseMomentumFunctionSourceTerm
    variable = gas_velocity
    source = gas_momentum_forcing
  []
  [fluid_energy_storage]
    type = ADReferenceEnergyStorageTerm
    variable = temperature
    coefficient = 1
  []
  [phase_conversion_energy]
    type = ADReferenceEnergyConversionTransferWorkTerm
    variable = temperature
    generalized_transfer_work_names = 'oil_tau_transfer_offset gas_tau_transfer_offset'
    current_component_source_names = 'phase_transfer_oil_current_component_source_0 phase_transfer_gas_current_component_source_0'
  []
[]

[BCs]
  [tau_bc]
    type = FunctionDirichletBC
    variable = tau
    boundary = 'left right'
    function = tau_exact
  []
  [oil_velocity_bc]
    type = FunctionDirichletBC
    variable = oil_velocity
    boundary = 'left right'
    function = oil_velocity_exact
  []
  [gas_velocity_bc]
    type = FunctionDirichletBC
    variable = gas_velocity
    boundary = 'left right'
    function = gas_velocity_exact
  []
[]

[AuxKernels]
  [dissipation_aux]
    type = ADMaterialRealAux
    variable = dissipation
    property = phase_transfer_reaction_power_0
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]

[Postprocessors]
  [rho_o_l2]
    type = ElementL2Error
    variable = rho_o
    function = rho_o_exact
  []
  [rho_g_l2]
    type = ElementL2Error
    variable = rho_g
    function = rho_g_exact
  []
  [rate_l2]
    type = ElementL2Error
    variable = transformation_rate
    function = rate_exact
  []
  [tau_l2]
    type = ElementL2Error
    variable = tau
    function = tau_exact
  []
  [oil_velocity_l2]
    type = ElementL2Error
    variable = oil_velocity
    function = oil_velocity_exact
  []
  [gas_velocity_l2]
    type = ElementL2Error
    variable = gas_velocity
    function = gas_velocity_exact
  []
  [temperature_l2]
    type = ElementL2Error
    variable = temperature
    function = temperature_exact
  []
  [oil_mu_l2]
    type = ADMaterialScalarL2Error
    property = oil_chemical_potential_0
    function = rho_o_exact
  []
  [gas_mu_l2]
    type = ADMaterialScalarL2Error
    property = gas_chemical_potential_0
    function = rho_g_exact
  []
  [tau_evolution_residual_l2]
    type = ADMaterialScalarL2Error
    property = tau_evolution_residual
    function = zero
  []
  [oil_tau_offset_l2]
    type = ADMaterialScalarL2Error
    property = oil_tau_transfer_offset
    function = oil_tau_offset_exact
  []
  [gas_tau_offset_l2]
    type = ADMaterialScalarL2Error
    property = gas_tau_transfer_offset
    function = gas_tau_offset_exact
  []
  [affinity_l2]
    type = ADMaterialScalarL2Error
    property = phase_transfer_affinity_0
    function = affinity_exact
  []
  [transfer_correction_l2]
    type = ADMaterialScalarL2Error
    property = phase_transfer_transfer_work_correction_0
    function = transfer_correction_exact
  []
  [generalized_force_l2]
    type = ADMaterialScalarL2Error
    property = phase_transfer_generalized_conversion_coefficient_0
    function = rate_exact
  []
  [kinetic_residual_l2]
    type = ADMaterialScalarL2Error
    property = phase_transfer_kinetic_residual_0
    function = zero
  []
  [dissipation_l2]
    type = ADMaterialScalarL2Error
    property = phase_transfer_reaction_power_0
    function = reaction_power_exact
  []
  [oil_mass]
    type = ElementIntegralVariablePostprocessor
    variable = rho_o
  []
  [gas_mass]
    type = ElementIntegralVariablePostprocessor
    variable = rho_g
  []
  [total_mass]
    type = LinearCombinationPostprocessor
    pp_names = 'oil_mass gas_mass'
    pp_coefs = '0.5 0.5'
  []
  [minimum_dissipation]
    type = ElementExtremeValue
    variable = dissipation
    value_type = min
  []
[]

[Executioner]
  type = Transient
  solve_type = NEWTON
  automatic_scaling = true
  petsc_options_iname = '-pc_type -pc_factor_mat_solver_type'
  petsc_options_value = 'lu superlu_dist'
  dt = ${solve_dt}
  end_time = 0.3
  nl_rel_tol = 1e-11
  nl_abs_tol = 1e-12
  nl_max_its = 20
[]

[Outputs]
  csv = true
  execute_on = 'INITIAL TIMESTEP_END'
[]
