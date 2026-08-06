[Variables]
  [theta_f]
    family = LAGRANGE
    order = SECOND
  []
  [theta_f_enr]
    family = MONOMIAL
    order = CONSTANT
  []
  [theta_s]
    family = LAGRANGE
    order = SECOND
  []
  [theta_s_enr]
    family = MONOMIAL
    order = CONSTANT
  []
[]

[AuxVariables]
  [fluid_velocity_x]
    family = LAGRANGE
    order = SECOND
  []
  [fluid_velocity_y]
    family = LAGRANGE
    order = SECOND
  []
  [fluid_velocity_z]
    family = LAGRANGE
    order = SECOND
  []
  [solid_velocity_x]
    family = LAGRANGE
    order = SECOND
  []
  [solid_velocity_y]
    family = LAGRANGE
    order = SECOND
  []
  [solid_velocity_z]
    family = LAGRANGE
    order = SECOND
  []
  [electric_potential]
    family = LAGRANGE
    order = SECOND
  []
[]

[Functions]
  [theta_f_exact]
    type = ParsedFunction
    expression = ${theta_f_exact_expression}
  []
  [theta_s_exact]
    type = ParsedFunction
    expression = ${theta_s_exact_expression}
  []
  [fluid_velocity_x_exact]
    type = ParsedFunction
    expression = 'x'
  []
  [fluid_velocity_y_exact]
    type = ParsedFunction
    expression = ${fluid_velocity_y_expression}
  []
  [fluid_velocity_z_exact]
    type = ParsedFunction
    expression = ${fluid_velocity_z_expression}
  []
  [solid_velocity_x_exact]
    type = ParsedFunction
    expression = '2*x'
  []
  [solid_velocity_y_exact]
    type = ParsedFunction
    expression = ${solid_velocity_y_expression}
  []
  [solid_velocity_z_exact]
    type = ParsedFunction
    expression = ${solid_velocity_z_expression}
  []
  [electric_potential_exact]
    type = ParsedFunction
    expression = ${electric_potential_expression}
  []
  [fluid_advection_flux_exact]
    type = ParsedFunction
    expression = ${fluid_advection_flux_potential_expression}
  []
  [fluid_heat_flux_exact]
    type = ParsedFunction
    expression = ${fluid_heat_flux_potential_expression}
  []
  [fluid_total_flux_exact]
    type = ParsedFunction
    expression = ${fluid_total_flux_potential_expression}
  []
  [solid_advection_flux_exact]
    type = ParsedFunction
    expression = ${solid_advection_flux_potential_expression}
  []
  [solid_heat_flux_exact]
    type = ParsedFunction
    expression = ${solid_heat_flux_potential_expression}
  []
  [solid_total_flux_exact]
    type = ParsedFunction
    expression = ${solid_total_flux_potential_expression}
  []
  [fluid_external_exact]
    type = ParsedFunction
    expression = ${fluid_external_expression}
  []
  [solid_external_exact]
    type = ParsedFunction
    expression = ${solid_external_expression}
  []
  [exchange_exact]
    type = ParsedFunction
    expression = ${fluid_exchange_expression}
  []
  [solid_exchange_exact]
    type = ParsedFunction
    expression = ${solid_exchange_expression}
  []
  [fluid_total_source_exact]
    type = ParsedFunction
    expression = ${fluid_total_source_expression}
  []
  [solid_total_source_exact]
    type = ParsedFunction
    expression = ${solid_total_source_expression}
  []
  [zero]
    type = ConstantFunction
    value = 0
  []
[]

[ICs]
  [theta_f_ic]
    type = FunctionIC
    variable = theta_f
    function = theta_f_exact
  []
  [theta_s_ic]
    type = FunctionIC
    variable = theta_s
    function = theta_s_exact
  []
[]

[Materials]
  [theta_f_reconstruction]
    type = ADEGReconstructedScalarMaterial
    backbone = theta_f
    enrichment = theta_f_enr
    field_name = theta_f
  []
  [theta_s_reconstruction]
    type = ADEGReconstructedScalarMaterial
    backbone = theta_s
    enrichment = theta_s_enr
    field_name = theta_s
  []
  [reference_scalars]
    type = ADGenericConstantMaterial
    prop_names = 'solid_reference_J fluid_storage solid_storage
                  fluid_stress_power_rhs solid_stress_power_rhs
                  fluid_transfer_work fluid_conversion_source
                  solid_transfer_work solid_conversion_source
                  fluid_electric_work_rhs solid_electric_work_rhs'
    prop_values = '1 2 3
                   ${fluid_stress_power_rhs} ${solid_stress_power_rhs}
                   3 0.4
                   -2 0.3
                   ${fluid_electric_work_rhs} ${solid_electric_work_rhs}'
  []
  [reference_inverse]
    type = ADGenericConstantRankTwoTensor
    tensor_name = solid_reference_F_inv
    tensor_values = '1 0 0  0 1 0  0 0 1'
  []
  [fluid_stress]
    type = ADGenericConstantRankTwoTensor
    tensor_name = fluid_total_reversible_stress
    tensor_values = '2 0 0  0 3 0  0 0 4'
  []
  [solid_stress]
    type = ADGenericConstantRankTwoTensor
    tensor_name = solid_total_reversible_stress
    tensor_values = '1.5 0 0  0 2.5 0  0 0 3'
  []
  [relative_charge_currents]
    type = ADGenericConstantVectorMaterial
    prop_names = 'fluid_relative_charge_current solid_relative_charge_current'
    prop_values = '0.8 0.4 0.2  0.4 0.3 0.1'
  []
  [fluid_relative_internal_energy_advection]
    type = ADScalarDiffusionReferenceFluxMaterial
    backbone = theta_f
    enrichment = theta_f_enr
    diffusivity = 0.5
    mobility_name = fluid_advection_mobility
    reference_flux_name = fluid_relative_internal_energy_flux
  []
  [fluid_fourier_cross_flux]
    type = ADScalarDiffusionReferenceFluxMaterial
    backbone = theta_f
    enrichment = theta_f_enr
    diffusivity = 2
    mobility_name = fluid_heat_mobility
    reference_flux_name = fluid_nonadvective_heat_flux
  []
  [fluid_total_flux]
    type = ADScalarDiffusionReferenceFluxMaterial
    backbone = theta_f
    enrichment = theta_f_enr
    diffusivity = 2.5
    mobility_name = fluid_total_energy_mobility
    reference_flux_name = fluid_total_reference_energy_flux
    reference_flux_divergence_name = fluid_total_reference_energy_flux_divergence
  []
  [solid_relative_internal_energy_advection]
    type = ADScalarDiffusionReferenceFluxMaterial
    backbone = theta_s
    enrichment = theta_s_enr
    diffusivity = 0.4
    mobility_name = solid_advection_mobility
    reference_flux_name = solid_relative_internal_energy_flux
  []
  [solid_fourier_cross_flux]
    type = ADScalarDiffusionReferenceFluxMaterial
    backbone = theta_s
    enrichment = theta_s_enr
    diffusivity = 3
    mobility_name = solid_heat_mobility
    reference_flux_name = solid_nonadvective_heat_flux
  []
  [solid_total_flux]
    type = ADScalarDiffusionReferenceFluxMaterial
    backbone = theta_s
    enrichment = theta_s_enr
    diffusivity = 3.4
    mobility_name = solid_total_energy_mobility
    reference_flux_name = solid_total_reference_energy_flux
    reference_flux_divergence_name = solid_total_reference_energy_flux_divergence
  []
  [temperature_properties]
    type = ADParsedMaterial
    coupled_variables = 'theta_f theta_f_enr'
    property_name = fluid_temperature_property
    expression = 'theta_f+theta_f_enr'
  []
  [solid_temperature_property]
    type = ADParsedMaterial
    coupled_variables = 'theta_s theta_s_enr'
    property_name = solid_temperature_property
    expression = 'theta_s+theta_s_enr'
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
    fluid_heat_source_name = fluid_exchange_source
    solid_heat_source_name = solid_exchange_source
    exchange_cancellation_name = fluid_solid_exchange_cancellation
    entropy_production_name = fluid_solid_exchange_entropy_production
  []
  [manufactured_external_heat]
    type = ADGenericFunctionMaterial
    prop_names = 'fluid_external_heat solid_external_heat'
    prop_values = 'fluid_external_exact solid_external_exact'
  []
  [fluid_total_source]
    type = ADParsedMaterial
    material_property_names = 'fluid_stress_power_rhs fluid_transfer_work fluid_conversion_source
                               fluid_electric_work_rhs fluid_external_heat fluid_exchange_source'
    property_name = fluid_total_energy_source
    expression = 'fluid_stress_power_rhs-fluid_transfer_work*fluid_conversion_source+fluid_electric_work_rhs+fluid_external_heat+fluid_exchange_source'
  []
  [solid_total_source]
    type = ADParsedMaterial
    material_property_names = 'solid_stress_power_rhs solid_transfer_work solid_conversion_source
                               solid_electric_work_rhs solid_external_heat solid_exchange_source'
    property_name = solid_total_energy_source
    expression = 'solid_stress_power_rhs-solid_transfer_work*solid_conversion_source+solid_electric_work_rhs+solid_external_heat+solid_exchange_source'
  []
  [fluid_strong_residual_audit]
    type = ADReferenceSubsystemEnergyDiagnosticMaterial
    temperature = theta_f
    storage_coefficient_name = fluid_storage
    reference_flux_divergence_name = fluid_total_reference_energy_flux_divergence
    current_source_names = 'fluid_stress_power_rhs fluid_electric_work_rhs fluid_external_heat fluid_exchange_source'
    source_scales = '1 1 1 1'
    generalized_transfer_work_names = fluid_transfer_work
    current_component_source_names = fluid_conversion_source
    property_prefix = fluid_full_energy
  []
  [solid_strong_residual_audit]
    type = ADReferenceSubsystemEnergyDiagnosticMaterial
    temperature = theta_s
    storage_coefficient_name = solid_storage
    reference_flux_divergence_name = solid_total_reference_energy_flux_divergence
    current_source_names = 'solid_stress_power_rhs solid_electric_work_rhs solid_external_heat solid_exchange_source'
    source_scales = '1 1 1 1'
    generalized_transfer_work_names = solid_transfer_work
    current_component_source_names = solid_conversion_source
    property_prefix = solid_full_energy
  []
[]

[AuxKernels]
  [fluid_velocity_x]
    type = FunctionAux
    variable = fluid_velocity_x
    function = fluid_velocity_x_exact
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [fluid_velocity_y]
    type = FunctionAux
    variable = fluid_velocity_y
    function = fluid_velocity_y_exact
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [fluid_velocity_z]
    type = FunctionAux
    variable = fluid_velocity_z
    function = fluid_velocity_z_exact
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [solid_velocity_x]
    type = FunctionAux
    variable = solid_velocity_x
    function = solid_velocity_x_exact
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [solid_velocity_y]
    type = FunctionAux
    variable = solid_velocity_y
    function = solid_velocity_y_exact
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [solid_velocity_z]
    type = FunctionAux
    variable = solid_velocity_z
    function = solid_velocity_z_exact
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [electric_potential]
    type = FunctionAux
    variable = electric_potential
    function = electric_potential_exact
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
[]

[Kernels]
  [fluid_storage]
    type = ADReferenceEnergyStorageTerm
    variable = theta_f
    coefficient_name = fluid_storage
  []
  [fluid_relative_internal_energy_advection]
    type = ADReferenceEnergyFluxTerm
    variable = theta_f
    reference_flux_name = fluid_relative_internal_energy_flux
    scale = -1
  []
  [fluid_fourier_cross_flux]
    type = ADReferenceEnergyFluxTerm
    variable = theta_f
    reference_flux_name = fluid_nonadvective_heat_flux
    scale = -1
  []
  [fluid_stress_power]
    type = ADReferenceEnergyStressPowerTerm
    variable = theta_f
    phase_velocity = ${fluid_velocity_components}
    cauchy_stress_name = fluid_total_reversible_stress
  []
  [fluid_conversion_work]
    type = ADReferenceEnergyConversionTransferWorkTerm
    variable = theta_f
    generalized_transfer_work_names = fluid_transfer_work
    current_component_source_names = fluid_conversion_source
  []
  [fluid_electric_work]
    type = ADReferenceEnergyRelativeCurrentWorkTerm
    variable = theta_f
    current_relative_charge_flux_name = fluid_relative_charge_current
    electric_potential = electric_potential
  []
  [fluid_external_heat]
    type = ADReferenceEnergySourceTerm
    variable = theta_f
    source_name = fluid_external_heat
  []
  [fluid_exchange]
    type = ADReferenceEnergySourceTerm
    variable = theta_f
    source_name = fluid_exchange_source
  []
  [fluid_enrichment]
    type = ADEnrichedGalerkinScalarEnrichmentBalance
    variable = theta_f_enr
    backbone = theta_f
    time_coefficient_name = fluid_storage
    source_name = fluid_total_energy_source
  []

  [solid_storage]
    type = ADReferenceEnergyStorageTerm
    variable = theta_s
    coefficient_name = solid_storage
  []
  [solid_relative_internal_energy_advection]
    type = ADReferenceEnergyFluxTerm
    variable = theta_s
    reference_flux_name = solid_relative_internal_energy_flux
    scale = -1
  []
  [solid_fourier_cross_flux]
    type = ADReferenceEnergyFluxTerm
    variable = theta_s
    reference_flux_name = solid_nonadvective_heat_flux
    scale = -1
  []
  [solid_stress_power]
    type = ADReferenceEnergyStressPowerTerm
    variable = theta_s
    phase_velocity = ${solid_velocity_components}
    cauchy_stress_name = solid_total_reversible_stress
  []
  [solid_conversion_work]
    type = ADReferenceEnergyConversionTransferWorkTerm
    variable = theta_s
    generalized_transfer_work_names = solid_transfer_work
    current_component_source_names = solid_conversion_source
  []
  [solid_electric_work]
    type = ADReferenceEnergyRelativeCurrentWorkTerm
    variable = theta_s
    current_relative_charge_flux_name = solid_relative_charge_current
    electric_potential = electric_potential
  []
  [solid_external_heat]
    type = ADReferenceEnergySourceTerm
    variable = theta_s
    source_name = solid_external_heat
  []
  [solid_exchange]
    type = ADReferenceEnergySourceTerm
    variable = theta_s
    source_name = solid_exchange_source
  []
  [solid_enrichment]
    type = ADEnrichedGalerkinScalarEnrichmentBalance
    variable = theta_s_enr
    backbone = theta_s
    time_coefficient_name = solid_storage
    source_name = solid_total_energy_source
  []
[]

[DGKernels]
  [fluid_relative_internal_energy_advection]
    type = ADEnrichedGalerkinFluxDG
    variable = theta_f_enr
    reference_flux_name = fluid_relative_internal_energy_flux
    mobility_name = fluid_advection_mobility
    epsilon = ${eg_epsilon}
    sigma = ${eg_sigma}
  []
  [fluid_advection_symmetry]
    type = ADEnrichedGalerkinSymmetryDG
    variable = theta_f
    enrichment = theta_f_enr
    mobility_name = fluid_advection_mobility
    epsilon = ${eg_epsilon}
  []
  [fluid_fourier_cross_flux]
    type = ADEnrichedGalerkinFluxDG
    variable = theta_f_enr
    reference_flux_name = fluid_nonadvective_heat_flux
    mobility_name = fluid_heat_mobility
    epsilon = ${eg_epsilon}
    sigma = ${eg_sigma}
  []
  [fluid_heat_symmetry]
    type = ADEnrichedGalerkinSymmetryDG
    variable = theta_f
    enrichment = theta_f_enr
    mobility_name = fluid_heat_mobility
    epsilon = ${eg_epsilon}
  []
  [solid_relative_internal_energy_advection]
    type = ADEnrichedGalerkinFluxDG
    variable = theta_s_enr
    reference_flux_name = solid_relative_internal_energy_flux
    mobility_name = solid_advection_mobility
    epsilon = ${eg_epsilon}
    sigma = ${eg_sigma}
  []
  [solid_advection_symmetry]
    type = ADEnrichedGalerkinSymmetryDG
    variable = theta_s
    enrichment = theta_s_enr
    mobility_name = solid_advection_mobility
    epsilon = ${eg_epsilon}
  []
  [solid_fourier_cross_flux]
    type = ADEnrichedGalerkinFluxDG
    variable = theta_s_enr
    reference_flux_name = solid_nonadvective_heat_flux
    mobility_name = solid_heat_mobility
    epsilon = ${eg_epsilon}
    sigma = ${eg_sigma}
  []
  [solid_heat_symmetry]
    type = ADEnrichedGalerkinSymmetryDG
    variable = theta_s
    enrichment = theta_s_enr
    mobility_name = solid_heat_mobility
    epsilon = ${eg_epsilon}
  []
[]

[BCs]
  [fluid_backbone]
    type = FunctionDirichletBC
    variable = theta_f
    boundary = ${all_boundaries}
    function = theta_f_exact
  []
  [fluid_advection_enrichment]
    type = ADEnrichedGalerkinPenaltyBC
    variable = theta_f_enr
    backbone = theta_f
    boundary = ${all_boundaries}
    reference_flux_name = fluid_relative_internal_energy_flux
    mobility_name = fluid_advection_mobility
    function = theta_f_exact
    epsilon = ${eg_epsilon}
    sigma = ${eg_sigma}
  []
  [fluid_heat_enrichment]
    type = ADEnrichedGalerkinPenaltyBC
    variable = theta_f_enr
    backbone = theta_f
    boundary = ${all_boundaries}
    reference_flux_name = fluid_nonadvective_heat_flux
    mobility_name = fluid_heat_mobility
    function = theta_f_exact
    epsilon = ${eg_epsilon}
    sigma = ${eg_sigma}
  []
  [solid_backbone]
    type = FunctionDirichletBC
    variable = theta_s
    boundary = ${all_boundaries}
    function = theta_s_exact
  []
  [solid_advection_enrichment]
    type = ADEnrichedGalerkinPenaltyBC
    variable = theta_s_enr
    backbone = theta_s
    boundary = ${all_boundaries}
    reference_flux_name = solid_relative_internal_energy_flux
    mobility_name = solid_advection_mobility
    function = theta_s_exact
    epsilon = ${eg_epsilon}
    sigma = ${eg_sigma}
  []
  [solid_heat_enrichment]
    type = ADEnrichedGalerkinPenaltyBC
    variable = theta_s_enr
    backbone = theta_s
    boundary = ${all_boundaries}
    reference_flux_name = solid_nonadvective_heat_flux
    mobility_name = solid_heat_mobility
    function = theta_s_exact
    epsilon = ${eg_epsilon}
    sigma = ${eg_sigma}
  []
[]

[Postprocessors]
  [theta_f_total_l2]
    type = ADMaterialScalarL2Error
    property = theta_f_total
    function = theta_f_exact
  []
  [theta_s_total_l2]
    type = ADMaterialScalarL2Error
    property = theta_s_total
    function = theta_s_exact
  []
  [theta_f_gradient_l2]
    type = ADMaterialVectorL2Error
    property = theta_f_total_gradient
    gradient_function = theta_f_exact
  []
  [theta_s_gradient_l2]
    type = ADMaterialVectorL2Error
    property = theta_s_total_gradient
    gradient_function = theta_s_exact
  []
  [fluid_advection_flux_l2]
    type = ADMaterialVectorL2Error
    property = fluid_relative_internal_energy_flux
    gradient_function = fluid_advection_flux_exact
  []
  [fluid_heat_flux_l2]
    type = ADMaterialVectorL2Error
    property = fluid_nonadvective_heat_flux
    gradient_function = fluid_heat_flux_exact
  []
  [fluid_total_flux_l2]
    type = ADMaterialVectorL2Error
    property = fluid_total_reference_energy_flux
    gradient_function = fluid_total_flux_exact
  []
  [solid_advection_flux_l2]
    type = ADMaterialVectorL2Error
    property = solid_relative_internal_energy_flux
    gradient_function = solid_advection_flux_exact
  []
  [solid_heat_flux_l2]
    type = ADMaterialVectorL2Error
    property = solid_nonadvective_heat_flux
    gradient_function = solid_heat_flux_exact
  []
  [solid_total_flux_l2]
    type = ADMaterialVectorL2Error
    property = solid_total_reference_energy_flux
    gradient_function = solid_total_flux_exact
  []
  [fluid_exchange_l2]
    type = ADMaterialScalarL2Error
    property = fluid_exchange_source
    function = exchange_exact
  []
  [solid_exchange_l2]
    type = ADMaterialScalarL2Error
    property = solid_exchange_source
    function = solid_exchange_exact
  []
  [fluid_total_source_l2]
    type = ADMaterialScalarL2Error
    property = fluid_total_energy_source
    function = fluid_total_source_exact
  []
  [solid_total_source_l2]
    type = ADMaterialScalarL2Error
    property = solid_total_energy_source
    function = solid_total_source_exact
  []
  [fluid_velocity_x_h1]
    type = ElementH1Error
    variable = fluid_velocity_x
    function = fluid_velocity_x_exact
  []
  [fluid_velocity_y_h1]
    type = ElementH1Error
    variable = fluid_velocity_y
    function = fluid_velocity_y_exact
  []
  [solid_velocity_x_h1]
    type = ElementH1Error
    variable = solid_velocity_x
    function = solid_velocity_x_exact
  []
  [solid_velocity_y_h1]
    type = ElementH1Error
    variable = solid_velocity_y
    function = solid_velocity_y_exact
  []
  [electric_potential_h1]
    type = ElementH1Error
    variable = electric_potential
    function = electric_potential_exact
  []
  [exchange_cancellation_l2]
    type = ADMaterialScalarL2Error
    property = fluid_solid_exchange_cancellation
    function = zero
  []
  [minimum_exchange_entropy_production]
    type = ADElementExtremeMaterialProperty
    mat_prop = fluid_solid_exchange_entropy_production
    value_type = min
  []
  [fluid_local_energy_residual_l2]
    type = ADMaterialScalarL2Error
    property = fluid_full_energy_local_residual
    function = zero
  []
  [solid_local_energy_residual_l2]
    type = ADMaterialScalarL2Error
    property = solid_full_energy_local_residual
    function = zero
  []
[]

[Executioner]
  type = Transient
  solve_type = NEWTON
  automatic_scaling = false
  scheme = implicit-euler
  dt = 0.1
  end_time = 0.1
  nl_rel_tol = 1e-11
  nl_abs_tol = 1e-11
  nl_max_its = 20
  petsc_options_iname = '-pc_type -pc_factor_mat_solver_type'
  petsc_options_value = 'lu superlu_dist'
[]

[Outputs]
  csv = true
[]
