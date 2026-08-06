mesh_nx := 8
!include ../../../input/includes/mesh/generated_1d_q2.i

[Variables]
  [fluid_temperature]
    family = LAGRANGE
    order = SECOND
  []
  [solid_temperature]
    family = LAGRANGE
    order = SECOND
  []
[]

[AuxVariables]
  [ux]
    family = LAGRANGE
    order = SECOND
  []
  [fluid_velocity]
    family = LAGRANGE
    order = SECOND
  []
  [solid_velocity]
    family = LAGRANGE
    order = SECOND
  []
  [electric_potential]
    family = LAGRANGE
    order = SECOND
  []
[]

[Functions]
  [fluid_temperature_exact]
    type = ParsedFunction
    expression = '1+t+x^2'
  []
  [solid_temperature_exact]
    type = ParsedFunction
    expression = '2+2*t+3*x^2'
  []
  [fluid_velocity_exact]
    type = ParsedFunction
    expression = 'x'
  []
  [solid_velocity_exact]
    type = ParsedFunction
    expression = '2*x'
  []
  [electric_potential_exact]
    type = ParsedFunction
    expression = 'x'
  []
  [zero]
    type = ParsedFunction
    expression = '0'
  []
[]

[ICs]
  [fluid_temperature_ic]
    type = FunctionIC
    variable = fluid_temperature
    function = fluid_temperature_exact
  []
  [solid_temperature_ic]
    type = FunctionIC
    variable = solid_temperature
    function = solid_temperature_exact
  []
[]

!include ../../../input/includes/materials/solid_kinematics_1d.i

[Materials]
  [energy_constants]
    type = ADGenericConstantMaterial
    prop_names = 'fluid_storage solid_storage
                  f_omega_phi f_omega_density f_omega_composition f_omega_temperature
                  f_gamma_phi f_gamma_history f_gamma_temperature
                  s_omega_phi s_omega_density s_omega_composition s_omega_temperature
                  fluid_transfer_work fluid_conversion_source
                  solid_transfer_work solid_conversion_source
                  fluid_pressure_density_power fluid_pressure_fraction_power
                  fluid_constraint_power fluid_composition_multiplier_power
                  fluid_mechanical_heating
                  solid_pressure_density_power solid_pressure_fraction_power
                  solid_constraint_power solid_composition_multiplier_power
                  solid_mechanical_heating'
    prop_values = '2 3
                   0.1 0.2 0.3 0.4 0.5 0.6 0.7
                   0.11 0.12 0.13 0.14
                   3 0.4 -2 0.3
                   0.1 0.2 0.3 0.4 0.7
                   0.11 0.12 0.13 0.14 0.17'
  []
  [energy_vectors]
    type = ADGenericConstantVectorMaterial
    prop_names = 'fluid_relative_charge_current solid_relative_charge_current'
    prop_values = '0.8 0 0 0.4 0 0'
  []
  [energy_stresses]
    type = ADGenericConstantRankTwoTensor
    tensor_name = fluid_total_reversible_stress
    tensor_values = '2 0 0 0 0 0 0 0 0'
  []
  [fluid_maxwell_stress]
    type = ADGenericConstantRankTwoTensor
    tensor_name = fluid_maxwell_stress
    tensor_values = '0.5 0 0 0 0 0 0 0 0'
  []
  [solid_total_stress]
    type = ADGenericConstantRankTwoTensor
    tensor_name = solid_total_reversible_stress
    tensor_values = '1.5 0 0 0 0 0 0 0 0'
  []
  [solid_maxwell_stress]
    type = ADGenericConstantRankTwoTensor
    tensor_name = solid_maxwell_stress
    tensor_values = '0.25 0 0 0 0 0 0 0 0'
  []
  [fluid_relative_internal_energy_flux]
    type = ADScalarDiffusionReferenceFluxMaterial
    backbone = fluid_temperature
    diffusivity = 0.3
    mobility_name = fluid_relative_internal_energy_mobility
    reference_flux_name = fluid_relative_internal_energy_flux
  []
  [fluid_heat_flux]
    type = ADScalarDiffusionReferenceFluxMaterial
    backbone = fluid_temperature
    diffusivity = 0.7
    mobility_name = fluid_heat_mobility
    reference_flux_name = fluid_nonadvective_heat_flux
  []
  [solid_relative_internal_energy_flux]
    type = ADScalarDiffusionReferenceFluxMaterial
    backbone = solid_temperature
    diffusivity = 0.2
    mobility_name = solid_relative_internal_energy_mobility
    reference_flux_name = solid_relative_internal_energy_flux
  []
  [solid_heat_flux]
    type = ADScalarDiffusionReferenceFluxMaterial
    backbone = solid_temperature
    diffusivity = 0.8
    mobility_name = solid_heat_mobility
    reference_flux_name = solid_nonadvective_heat_flux
  []
  [subsystem_temperature_properties]
    type = ADParsedMaterial
    coupled_variables = 'fluid_temperature solid_temperature'
    property_name = fluid_temperature_property
    expression = fluid_temperature
  []
  [solid_temperature_property]
    type = ADParsedMaterial
    coupled_variables = 'fluid_temperature solid_temperature'
    property_name = solid_temperature_property
    expression = solid_temperature
  []
  [state_dependent_heat_transfer_coefficient]
    type = ADParsedMaterial
    material_property_names = fluid_temperature_property
    property_name = fluid_solid_heat_transfer_coefficient
    expression = '1+0.01*fluid_temperature_property'
  []
  [fluid_solid_heat_exchange]
    type = ADInterSubsystemHeatExchangeMaterial
    fluid_temperature_name = fluid_temperature_property
    solid_temperature_name = solid_temperature_property
    heat_transfer_coefficient_name = fluid_solid_heat_transfer_coefficient
    fluid_heat_source_name = fluid_interphase_energy
    solid_heat_source_name = solid_interphase_energy
    exchange_cancellation_name = fluid_solid_exchange_cancellation
    entropy_production_name = fluid_solid_exchange_entropy_production
  []
  [fluid_compensating_external_heat]
    type = ADParsedMaterial
    material_property_names = fluid_interphase_energy
    property_name = fluid_external_heat
    expression = '2.3-fluid_interphase_energy'
  []
  [solid_compensating_external_heat]
    type = ADParsedMaterial
    material_property_names = fluid_interphase_energy
    property_name = solid_external_heat
    expression = '-2.61+fluid_interphase_energy'
  []
[]

[AuxKernels]
  [ux_zero]
    type = FunctionAux
    variable = ux
    function = zero
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [fluid_velocity_prescribed]
    type = FunctionAux
    variable = fluid_velocity
    function = fluid_velocity_exact
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [solid_velocity_prescribed]
    type = FunctionAux
    variable = solid_velocity
    function = solid_velocity_exact
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [electric_potential_prescribed]
    type = FunctionAux
    variable = electric_potential
    function = electric_potential_exact
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
[]

[Kernels]
  [fluid_internal_energy_storage]
    type = ADReferenceEnergyStorageTerm
    variable = fluid_temperature
    coefficient_name = fluid_storage
  []
  [fluid_omega_phi_rate]
    type = ADReferenceEnergyStateRateTerm
    variable = fluid_temperature
    state = fluid_temperature
    coefficient_name = f_omega_phi
  []
  [fluid_omega_density_rate]
    type = ADReferenceEnergyStateRateTerm
    variable = fluid_temperature
    state = solid_temperature
    coefficient_name = f_omega_density
  []
  [fluid_omega_composition_rate]
    type = ADReferenceEnergyStateRateTerm
    variable = fluid_temperature
    state = fluid_temperature
    coefficient_name = f_omega_composition
  []
  [fluid_omega_temperature_rate]
    type = ADReferenceEnergyStateRateTerm
    variable = fluid_temperature
    state = fluid_temperature
    coefficient_name = f_omega_temperature
  []
  [fluid_gamma_phi_rate]
    type = ADReferenceEnergyStateRateTerm
    variable = fluid_temperature
    state = solid_temperature
    coefficient_name = f_gamma_phi
  []
  [fluid_gamma_history_rate]
    type = ADReferenceEnergyStateRateTerm
    variable = fluid_temperature
    state = fluid_temperature
    coefficient_name = f_gamma_history
  []
  [fluid_gamma_temperature_rate]
    type = ADReferenceEnergyStateRateTerm
    variable = fluid_temperature
    state = fluid_temperature
    coefficient_name = f_gamma_temperature
  []
  [fluid_relative_internal_energy_transport]
    type = ADReferenceEnergyFluxTerm
    variable = fluid_temperature
    reference_flux_name = fluid_relative_internal_energy_flux
    scale = -1
  []
  [fluid_nonadvective_heat_transport]
    type = ADReferenceEnergyFluxTerm
    variable = fluid_temperature
    reference_flux_name = fluid_nonadvective_heat_flux
    scale = -1
  []
  [fluid_total_stress_power]
    type = ADReferenceEnergyStressPowerTerm
    variable = fluid_temperature
    phase_velocity = fluid_velocity
    cauchy_stress_name = fluid_total_reversible_stress
  []
  [fluid_maxwell_storage_power]
    type = ADReferenceEnergyStressPowerTerm
    variable = fluid_temperature
    phase_velocity = fluid_velocity
    cauchy_stress_name = fluid_maxwell_stress
    scale = -1
  []
  [fluid_conversion_transfer_work]
    type = ADReferenceEnergyConversionTransferWorkTerm
    variable = fluid_temperature
    generalized_transfer_work_names = fluid_transfer_work
    current_component_source_names = fluid_conversion_source
  []
  [fluid_relative_current_work]
    type = ADReferenceEnergyRelativeCurrentWorkTerm
    variable = fluid_temperature
    current_relative_charge_flux_name = fluid_relative_charge_current
    electric_potential = electric_potential
  []
  [fluid_pressure_density_power]
    type = ADReferenceEnergySourceTerm
    variable = fluid_temperature
    source_name = fluid_pressure_density_power
  []
  [fluid_pressure_fraction_power]
    type = ADReferenceEnergySourceTerm
    variable = fluid_temperature
    source_name = fluid_pressure_fraction_power
  []
  [fluid_constraint_power]
    type = ADReferenceEnergySourceTerm
    variable = fluid_temperature
    source_name = fluid_constraint_power
  []
  [fluid_composition_multiplier_power]
    type = ADReferenceEnergySourceTerm
    variable = fluid_temperature
    source_name = fluid_composition_multiplier_power
  []
  [fluid_external_heat]
    type = ADReferenceEnergySourceTerm
    variable = fluid_temperature
    source_name = fluid_external_heat
  []
  [fluid_interphase_energy]
    type = ADReferenceEnergySourceTerm
    variable = fluid_temperature
    source_name = fluid_interphase_energy
  []
  [fluid_mechanical_heating]
    type = ADReferenceEnergySourceTerm
    variable = fluid_temperature
    source_name = fluid_mechanical_heating
  []

  [solid_internal_energy_storage]
    type = ADReferenceEnergyStorageTerm
    variable = solid_temperature
    coefficient_name = solid_storage
  []
  [solid_omega_phi_rate]
    type = ADReferenceEnergyStateRateTerm
    variable = solid_temperature
    state = fluid_temperature
    coefficient_name = s_omega_phi
  []
  [solid_omega_density_rate]
    type = ADReferenceEnergyStateRateTerm
    variable = solid_temperature
    state = solid_temperature
    coefficient_name = s_omega_density
  []
  [solid_omega_composition_rate]
    type = ADReferenceEnergyStateRateTerm
    variable = solid_temperature
    state = fluid_temperature
    coefficient_name = s_omega_composition
  []
  [solid_omega_temperature_rate]
    type = ADReferenceEnergyStateRateTerm
    variable = solid_temperature
    state = solid_temperature
    coefficient_name = s_omega_temperature
  []
  [solid_relative_internal_energy_transport]
    type = ADReferenceEnergyFluxTerm
    variable = solid_temperature
    reference_flux_name = solid_relative_internal_energy_flux
    scale = -1
  []
  [solid_nonadvective_heat_transport]
    type = ADReferenceEnergyFluxTerm
    variable = solid_temperature
    reference_flux_name = solid_nonadvective_heat_flux
    scale = -1
  []
  [solid_total_stress_power]
    type = ADReferenceEnergyStressPowerTerm
    variable = solid_temperature
    phase_velocity = solid_velocity
    cauchy_stress_name = solid_total_reversible_stress
  []
  [solid_maxwell_storage_power]
    type = ADReferenceEnergyStressPowerTerm
    variable = solid_temperature
    phase_velocity = solid_velocity
    cauchy_stress_name = solid_maxwell_stress
    scale = -1
  []
  [solid_conversion_transfer_work]
    type = ADReferenceEnergyConversionTransferWorkTerm
    variable = solid_temperature
    generalized_transfer_work_names = solid_transfer_work
    current_component_source_names = solid_conversion_source
  []
  [solid_relative_current_work]
    type = ADReferenceEnergyRelativeCurrentWorkTerm
    variable = solid_temperature
    current_relative_charge_flux_name = solid_relative_charge_current
    electric_potential = electric_potential
  []
  [solid_pressure_density_power]
    type = ADReferenceEnergySourceTerm
    variable = solid_temperature
    source_name = solid_pressure_density_power
  []
  [solid_pressure_fraction_power]
    type = ADReferenceEnergySourceTerm
    variable = solid_temperature
    source_name = solid_pressure_fraction_power
  []
  [solid_constraint_power]
    type = ADReferenceEnergySourceTerm
    variable = solid_temperature
    source_name = solid_constraint_power
  []
  [solid_composition_multiplier_power]
    type = ADReferenceEnergySourceTerm
    variable = solid_temperature
    source_name = solid_composition_multiplier_power
  []
  [solid_external_heat]
    type = ADReferenceEnergySourceTerm
    variable = solid_temperature
    source_name = solid_external_heat
  []
  [solid_interphase_energy]
    type = ADReferenceEnergySourceTerm
    variable = solid_temperature
    source_name = solid_interphase_energy
  []
  [solid_mechanical_heating]
    type = ADReferenceEnergySourceTerm
    variable = solid_temperature
    source_name = solid_mechanical_heating
  []
[]

[BCs]
  [fluid_temperature_exact]
    type = FunctionDirichletBC
    variable = fluid_temperature
    boundary = 'left right'
    function = fluid_temperature_exact
  []
  [solid_temperature_exact]
    type = FunctionDirichletBC
    variable = solid_temperature
    boundary = 'left right'
    function = solid_temperature_exact
  []
[]

[Postprocessors]
  [fluid_temperature_l2]
    type = ElementL2Error
    variable = fluid_temperature
    function = fluid_temperature_exact
  []
  [solid_temperature_l2]
    type = ElementL2Error
    variable = solid_temperature
    function = solid_temperature_exact
  []
[]

[Executioner]
  type = Transient
  solve_type = NEWTON
  automatic_scaling = false
  scheme = implicit-euler
  dt = 0.1
  end_time = 0.1
  nl_rel_tol = 1e-12
  nl_abs_tol = 1e-13
  nl_max_its = 15
  petsc_options_iname = '-pc_type -pc_factor_mat_solver_type'
  petsc_options_value = 'lu superlu_dist'
[]

[Outputs]
  csv = true
[]
