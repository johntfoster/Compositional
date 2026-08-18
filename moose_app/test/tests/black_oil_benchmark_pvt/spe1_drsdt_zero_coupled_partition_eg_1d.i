[Mesh]
  [line]
    type = GeneratedMeshGenerator
    dim = 1
    nx = 2
  []
[]

[Variables]
  [solution_gas_oil_ratio]
    family = LAGRANGE
    order = FIRST
  []
  [gas_saturation]
    family = BERNSTEIN
    order = SECOND
  []
  [gas_saturation_enrichment]
    family = MONOMIAL
    order = CONSTANT
  []
  [gas_phase_transformation_rate]
    family = LAGRANGE
    order = FIRST
  []
[]

[Functions]
  [solution_gas_oil_ratio_initial]
    type = ParsedFunction
    expression = '1.5'
  []
  [gas_saturation_initial]
    type = ParsedFunction
    expression = '0'
  []
  [zero]
    type = ParsedFunction
    expression = '0'
  []
  [one]
    type = ParsedFunction
    expression = '1'
  []
  [oil_pressure_history]
    type = ParsedFunction
    expression = '4200'
  []
  [oil_pressure_history_rate]
    type = ParsedFunction
    expression = '0'
  []
[]

[ICs]
  [solution_gas_oil_ratio_ic]
    type = FunctionIC
    variable = solution_gas_oil_ratio
    function = solution_gas_oil_ratio_initial
  []
  [gas_saturation_ic]
    type = ConstantIC
    variable = gas_saturation
    value = 0
  []
  [gas_saturation_enrichment_ic]
    type = FunctionIC
    variable = gas_saturation_enrichment
    function = zero
  []
  [gas_phase_transformation_rate_ic]
    type = FunctionIC
    variable = gas_phase_transformation_rate
    function = zero
  []
[]

[UserObjects]
  [phases]
    type = PhaseRegistry
    phases = 'matrix oil gas water'
    reference_phase = matrix
    momentum_models = 'reference relative_flux relative_flux relative_flux'
  []
[]

[Materials]
  [reference_kinematics]
    type = ADGenericConstantMaterial
    prop_names = 'solid_reference_J solid_reference_J_dot porosity_for_pvt porosity_for_pvt_dot water_saturation_for_pvt water_saturation_for_pvt_dot oil_tau_transfer_offset gas_tau_transfer_offset'
    prop_values = '1 0 0.3 0 0.2 0 0 0'
  []
  [prescribed_oil_pressure]
    type = ADGenericFunctionMaterial
    prop_names = 'oil_pressure_for_pvt oil_pressure_for_pvt_dot'
    prop_values = 'oil_pressure_history oil_pressure_history_rate'
  []
  [gas_saturation_reconstruction]
    type = ADEGReconstructedScalarMaterial
    field_name = constrained_gas_saturation
    backbone = gas_saturation
    enrichment = gas_saturation_enrichment
  []
  [benchmark_pvt]
    type = ADBlackOilBenchmarkPVTMaterial
    compute_storage_rates = true
    oil_pressure_name = oil_pressure_for_pvt
    oil_pressure_rate_name = oil_pressure_for_pvt_dot
    solution_gas_oil_ratio = solution_gas_oil_ratio
    porosity_name = porosity_for_pvt
    porosity_rate_name = porosity_for_pvt_dot
    water_saturation_name = water_saturation_for_pvt
    water_saturation_rate_name = water_saturation_for_pvt_dot
    gas_saturation_name = constrained_gas_saturation_total
    gas_saturation_rate_name = constrained_gas_saturation_total_dot
    reject_oversaturated_state = false
    equilibrate_solution_gas_with_free_gas = false
    enforce_nonincreasing_solution_gas = true
    maximum_solution_gas_oil_ratio = 2
    solution_gas_transition_width = 0
    out_of_range_policy = clamp
    water_reference_pressure = 4000
    water_reference_fvf = 1
    water_compressibility = 0
    water_reference_viscosity = 1
    water_viscosibility = 0
    gas_pressure_points = '4000 5000'
    gas_fvf_values = '1 0.8'
    gas_viscosity_values = '0.02 0.03'
    oil_solution_gas_oil_ratio_points = '1 2'
    oil_bubble_pressure_points = '4000 5000'
    oil_branch_offsets = '0 1 2'
    oil_pressure_points = '4000 5000'
    oil_fvf_values = '1.2 1.4'
    oil_viscosity_values = '1 0.8'
    saturated_oil_fvf_values = '1.2 1.4'
    saturated_oil_viscosity_values = '1 0.8'
    water_surface_density = 1000
    oil_surface_density = 800
    gas_surface_density = 1
  []
  [phase_transform_thermodynamics]
    type = ADBlackOilPhaseTransformationThermodynamicsMaterial
    undersaturation_gap_name = benchmark_black_oil_undersaturation_gap
    oil_component_mass_fraction_name = benchmark_black_oil_oil_component_mass_fraction_in_oil
    dissolved_gas_mass_fraction_name = benchmark_black_oil_gas_component_mass_fraction_in_oil
    oil_intrinsic_density_name = benchmark_black_oil_oil_intrinsic_density
    gas_intrinsic_density_name = benchmark_black_oil_gas_intrinsic_density
    oil_bulk_density_name = benchmark_black_oil_oil_bulk_phase_density
    gas_bulk_density_name = benchmark_black_oil_gas_bulk_phase_density
    oil_pressure_name = oil_pressure_for_pvt
    gas_pressure_name = oil_pressure_for_pvt
    solution_gas_oil_ratio_scale = 1
    chemical_stiffness = 1
    oil_surface_density = 800
    gas_surface_density = 1
    property_prefix = constrained_phase_transform
  []
  [phase_transfer]
    type = ADReactionNetworkMaterial
    phase_registry = phases
    phases = 'oil gas'
    components = gas
    reaction_rates = gas_phase_transformation_rate
    stoichiometric_coefficients = '-1 1'
    chemical_potential_names = 'constrained_phase_transform_dissolved_gas_electrochemical_mu constrained_phase_transform_free_gas_electrochemical_mu'
    phase_tau_offset_names = 'oil_tau_transfer_offset gas_tau_transfer_offset'
    property_prefix = constrained_phase_transfer
  []
  [phase_transform_power]
    type = ADParsedMaterial
    coupled_variables = gas_phase_transformation_rate
    material_property_names = constrained_phase_transform_dissolved_to_free_affinity
    property_name = constrained_phase_transform_power
    expression = 'constrained_phase_transform_dissolved_to_free_affinity*gas_phase_transformation_rate'
  []
  [free_gas_phase_balance]
    type = ADParsedMaterial
    material_property_names = 'benchmark_black_oil_free_gas_reference_component_storage_rate constrained_phase_transfer_gas_reference_component_source_0'
    property_name = free_gas_phase_balance_residual
    expression = 'benchmark_black_oil_free_gas_reference_component_storage_rate-constrained_phase_transfer_gas_reference_component_source_0'
  []
[]

[Kernels]
  [total_gas_balance]
    type = ADMaterialPropertyResidual
    variable = solution_gas_oil_ratio
    property = benchmark_black_oil_gas_reference_component_storage_rate
  []
  [free_gas_balance]
    type = ADEnrichedGalerkinScalarBalance
    variable = gas_saturation
    enrichment = gas_saturation_enrichment
    reference_component_storage_rate_name = benchmark_black_oil_free_gas_reference_component_storage_rate
    source_name = constrained_phase_transfer_gas_reference_component_source_0
  []
  [free_gas_enrichment_balance]
    type = ADEnrichedGalerkinScalarEnrichmentBalance
    variable = gas_saturation_enrichment
    backbone = gas_saturation
    reference_component_storage_rate_name = benchmark_black_oil_free_gas_reference_component_storage_rate
    source_name = constrained_phase_transfer_gas_reference_component_source_0
  []
  [solution_gas_history]
    type = ADMaterialPropertyResidual
    variable = gas_phase_transformation_rate
    property = benchmark_black_oil_solution_gas_constraint_residual
  []
[]

[Postprocessors]
  [solution_gas_oil_ratio_average]
    type = ElementAverageValue
    variable = solution_gas_oil_ratio
    execute_on = TIMESTEP_END
  []
  [oil_pressure_average]
    type = ADElementAverageMaterialProperty
    mat_prop = oil_pressure_for_pvt
    execute_on = TIMESTEP_END
  []
  [gas_saturation_average]
    type = ADElementAverageMaterialProperty
    mat_prop = constrained_gas_saturation_total
    execute_on = TIMESTEP_END
  []
  [gas_saturation_enrichment_l2]
    type = ElementL2Norm
    variable = gas_saturation_enrichment
    execute_on = TIMESTEP_END
  []
  [gas_saturation_initial_l2]
    type = ElementL2Error
    variable = gas_saturation
    function = gas_saturation_initial
    execute_on = INITIAL
  []
  [gas_phase_transformation_rate_average]
    type = ElementAverageValue
    variable = gas_phase_transformation_rate
    execute_on = TIMESTEP_END
  []
  [phase_transform_affinity_average]
    type = ADElementAverageMaterialProperty
    mat_prop = constrained_phase_transform_dissolved_to_free_affinity
    execute_on = TIMESTEP_END
  []
  [phase_transform_power_average]
    type = ADElementAverageMaterialProperty
    mat_prop = constrained_phase_transform_power
    execute_on = TIMESTEP_END
  []
  [phase_transfer_generalized_force_average]
    type = ADElementAverageMaterialProperty
    mat_prop = constrained_phase_transfer_generalized_conversion_coefficient_0
    execute_on = TIMESTEP_END
  []
  [phase_transfer_reaction_power_average]
    type = ADElementAverageMaterialProperty
    mat_prop = constrained_phase_transfer_reaction_power_0
    execute_on = TIMESTEP_END
  []
  [solution_gas_history_l2]
    type = ADMaterialScalarL2Error
    property = benchmark_black_oil_solution_gas_constraint_residual
    function = zero
    execute_on = TIMESTEP_END
  []
  [total_gas_balance_l2]
    type = ADMaterialScalarL2Error
    property = benchmark_black_oil_gas_reference_component_storage_rate
    function = zero
    execute_on = TIMESTEP_END
  []
  [free_gas_phase_balance_l2]
    type = ADMaterialScalarL2Error
    property = free_gas_phase_balance_residual
    function = zero
    execute_on = TIMESTEP_END
  []
  [total_gas_balance_integral]
    type = ADElementIntegralMaterialProperty
    mat_prop = benchmark_black_oil_gas_reference_component_storage_rate
    execute_on = TIMESTEP_END
  []
  [free_gas_phase_balance_integral]
    type = ADElementIntegralMaterialProperty
    mat_prop = free_gas_phase_balance_residual
    execute_on = TIMESTEP_END
  []
[]

[Executioner]
  type = Transient
  solve_type = NEWTON
  dt = 1
  num_steps = 2
  nl_abs_tol = 1e-12
  nl_rel_tol = 1e-12
  petsc_options_iname = '-pc_type -pc_factor_mat_solver_type'
  petsc_options_value = 'lu superlu_dist'
[]

[Outputs]
  csv = true
[]
