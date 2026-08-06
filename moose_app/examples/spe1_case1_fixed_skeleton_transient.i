# Fixed-skeleton SPE1 Case 1 finite-element diagnostic in SI units.
# This deck exercises the black-oil P1+P0 pressure and component-balance path,
# but prescribed identity kinematics exclude it from production acceptance.
spe1_use_pressure_dependent_rock_porosity = true
!include spe1_case1_mesh_only.i

[Variables]
  [oil_pressure]
    family = LAGRANGE
    order = FIRST
    scaling = 1e-7
  []
  [oil_pressure_enrichment]
    family = MONOMIAL
    order = CONSTANT
    initial_condition = 0
    scaling = 1e-7
  []
  [solution_gas_oil_ratio]
    family = LAGRANGE
    order = FIRST
  []
  [water_saturation]
    family = LAGRANGE
    order = FIRST
  []
  [gas_saturation]
    family = LAGRANGE
    order = FIRST
  []
  [injector_bhp_scalar]
    family = SCALAR
    order = FIRST
    initial_condition = 36700000
    scaling = 1e-7
  []
  [producer_bhp_scalar]
    family = SCALAR
    order = FIRST
    initial_condition = 20000000
    scaling = 1e-7
  []
[]

[AuxVariables]
  [porosity]
    family = LAGRANGE
    order = FIRST
  []
[]

[Functions]
  [initial_oil_pressure]
    type = PiecewiseLinear
    axis = z
    x = '2540.508 2548.128 2560.32'
    y = '32972876.15288512 33019779.87273818 33094835.007206395'
  []
[]

[ICs]
  [oil_pressure]
    type = FunctionIC
    variable = oil_pressure
    function = initial_oil_pressure
  []
  [solution_gas_oil_ratio]
    type = ConstantIC
    variable = solution_gas_oil_ratio
    value = 226.19666048237477
  []
  [water_saturation]
    type = ConstantIC
    variable = water_saturation
    value = 0.12
  []
  [gas_saturation]
    type = ConstantIC
    variable = gas_saturation
    value = 0
  []
  [porosity]
    type = ConstantIC
    variable = porosity
    value = 0.3
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
    prop_names = 'solid_reference_J solid_reference_J_dot'
    prop_values = '1 0'
  []
  [reference_inverse]
    type = ADGenericConstantRankTwoTensor
    tensor_name = solid_reference_F_inv
    tensor_values = '1 0 0 0 1 0 0 0 1'
  []
  [reference_jacobian_inverse]
    type = ADGenericConstantRankTwoTensor
    tensor_name = solid_reference_J_F_inv
    tensor_values = '1 0 0 0 1 0 0 0 1'
  []
  [oil_pressure_reconstruction]
    type = ADEGReconstructedScalarMaterial
    field_name = spe1_oil_pressure
    backbone = oil_pressure
    enrichment = oil_pressure_enrichment
  []
  [water_saturation_reconstruction]
    type = ADEGReconstructedScalarMaterial
    field_name = spe1_water_saturation
    backbone = water_saturation
  []
  [gas_saturation_reconstruction]
    type = ADEGReconstructedScalarMaterial
    field_name = spe1_gas_saturation
    backbone = gas_saturation
  []
[]

!include ../input/includes/materials/spe1_case1_black_oil_pvt.i

[Materials]
  [layer_1_water_darcy]
    type = ADStandardDarcyReferenceFluxMaterial
    block = '1 11'
    phase = water
    phase_registry = phases
    pressure = oil_pressure
    pressure_enrichment = oil_pressure_enrichment
    intrinsic_density_source = material
    intrinsic_density_name = benchmark_black_oil_water_intrinsic_density
    permeability = 4.9346165e-13
    viscosity_name = benchmark_black_oil_water_viscosity
    relative_permeability_name = black_oil_water_relative_permeability
    gravity = '0 0 9.80665'
    darcy_mobility_ref_name = water_darcy_mobility
    reference_relative_mass_flux_name = water_reference_relative_mass_flux
  []
  [layer_2_water_darcy]
    type = ADStandardDarcyReferenceFluxMaterial
    block = 2
    phase = water
    phase_registry = phases
    pressure = oil_pressure
    pressure_enrichment = oil_pressure_enrichment
    intrinsic_density_source = material
    intrinsic_density_name = benchmark_black_oil_water_intrinsic_density
    permeability = 4.9346165e-14
    viscosity_name = benchmark_black_oil_water_viscosity
    relative_permeability_name = black_oil_water_relative_permeability
    gravity = '0 0 9.80665'
    darcy_mobility_ref_name = water_darcy_mobility
    reference_relative_mass_flux_name = water_reference_relative_mass_flux
  []
  [layer_3_water_darcy]
    type = ADStandardDarcyReferenceFluxMaterial
    block = '3 13'
    phase = water
    phase_registry = phases
    pressure = oil_pressure
    pressure_enrichment = oil_pressure_enrichment
    intrinsic_density_source = material
    intrinsic_density_name = benchmark_black_oil_water_intrinsic_density
    permeability = 1.9738466e-13
    viscosity_name = benchmark_black_oil_water_viscosity
    relative_permeability_name = black_oil_water_relative_permeability
    gravity = '0 0 9.80665'
    darcy_mobility_ref_name = water_darcy_mobility
    reference_relative_mass_flux_name = water_reference_relative_mass_flux
  []
  [layer_1_oil_darcy]
    type = ADStandardDarcyReferenceFluxMaterial
    block = '1 11'
    phase = oil
    phase_registry = phases
    pressure = oil_pressure
    pressure_enrichment = oil_pressure_enrichment
    intrinsic_density_source = material
    intrinsic_density_name = benchmark_black_oil_oil_intrinsic_density
    permeability = 4.9346165e-13
    viscosity_name = benchmark_black_oil_oil_viscosity
    relative_permeability_name = black_oil_oil_relative_permeability
    gravity = '0 0 9.80665'
    darcy_mobility_ref_name = oil_darcy_mobility
    reference_relative_mass_flux_name = oil_reference_relative_mass_flux
  []
  [layer_2_oil_darcy]
    type = ADStandardDarcyReferenceFluxMaterial
    block = 2
    phase = oil
    phase_registry = phases
    pressure = oil_pressure
    pressure_enrichment = oil_pressure_enrichment
    intrinsic_density_source = material
    intrinsic_density_name = benchmark_black_oil_oil_intrinsic_density
    permeability = 4.9346165e-14
    viscosity_name = benchmark_black_oil_oil_viscosity
    relative_permeability_name = black_oil_oil_relative_permeability
    gravity = '0 0 9.80665'
    darcy_mobility_ref_name = oil_darcy_mobility
    reference_relative_mass_flux_name = oil_reference_relative_mass_flux
  []
  [layer_3_oil_darcy]
    type = ADStandardDarcyReferenceFluxMaterial
    block = '3 13'
    phase = oil
    phase_registry = phases
    pressure = oil_pressure
    pressure_enrichment = oil_pressure_enrichment
    intrinsic_density_source = material
    intrinsic_density_name = benchmark_black_oil_oil_intrinsic_density
    permeability = 1.9738466e-13
    viscosity_name = benchmark_black_oil_oil_viscosity
    relative_permeability_name = black_oil_oil_relative_permeability
    gravity = '0 0 9.80665'
    darcy_mobility_ref_name = oil_darcy_mobility
    reference_relative_mass_flux_name = oil_reference_relative_mass_flux
  []
  [layer_1_gas_darcy]
    type = ADStandardDarcyReferenceFluxMaterial
    block = '1 11'
    phase = gas
    phase_registry = phases
    pressure = oil_pressure
    pressure_enrichment = oil_pressure_enrichment
    intrinsic_density_source = material
    intrinsic_density_name = benchmark_black_oil_gas_intrinsic_density
    permeability = 4.9346165e-13
    viscosity_name = benchmark_black_oil_gas_viscosity
    relative_permeability_name = black_oil_gas_relative_permeability
    gravity = '0 0 9.80665'
    darcy_mobility_ref_name = gas_darcy_mobility
    reference_relative_mass_flux_name = gas_reference_relative_mass_flux
  []
  [layer_2_gas_darcy]
    type = ADStandardDarcyReferenceFluxMaterial
    block = 2
    phase = gas
    phase_registry = phases
    pressure = oil_pressure
    pressure_enrichment = oil_pressure_enrichment
    intrinsic_density_source = material
    intrinsic_density_name = benchmark_black_oil_gas_intrinsic_density
    permeability = 4.9346165e-14
    viscosity_name = benchmark_black_oil_gas_viscosity
    relative_permeability_name = black_oil_gas_relative_permeability
    gravity = '0 0 9.80665'
    darcy_mobility_ref_name = gas_darcy_mobility
    reference_relative_mass_flux_name = gas_reference_relative_mass_flux
  []
  [layer_3_gas_darcy]
    type = ADStandardDarcyReferenceFluxMaterial
    block = '3 13'
    phase = gas
    phase_registry = phases
    pressure = oil_pressure
    pressure_enrichment = oil_pressure_enrichment
    intrinsic_density_source = material
    intrinsic_density_name = benchmark_black_oil_gas_intrinsic_density
    permeability = 1.9738466e-13
    viscosity_name = benchmark_black_oil_gas_viscosity
    relative_permeability_name = black_oil_gas_relative_permeability
    gravity = '0 0 9.80665'
    darcy_mobility_ref_name = gas_darcy_mobility
    reference_relative_mass_flux_name = gas_reference_relative_mass_flux
  []

  [zero_component_fraction]
    type = ADGenericConstantMaterial
    prop_names = zero_component_fraction
    prop_values = '0'
  []
  [water_component_flux]
    type = ADRegisteredPhaseComponentFluxMaterial
    phase_registry = phases
    phases = 'oil gas water'
    component = 0
    phase_reference_relative_mass_flux_names = 'oil_reference_relative_mass_flux gas_reference_relative_mass_flux water_reference_relative_mass_flux'
    phase_component_mass_fraction_names = 'zero_component_fraction zero_component_fraction benchmark_black_oil_water_component_mass_fraction_in_water'
    reference_component_flux_name = water_reference_component_flux
    reference_component_source_name = unused_water_source
  []
  [oil_component_flux]
    type = ADRegisteredPhaseComponentFluxMaterial
    phase_registry = phases
    phases = 'oil gas water'
    component = 1
    phase_reference_relative_mass_flux_names = 'oil_reference_relative_mass_flux gas_reference_relative_mass_flux water_reference_relative_mass_flux'
    phase_component_mass_fraction_names = 'benchmark_black_oil_oil_component_mass_fraction_in_oil zero_component_fraction zero_component_fraction'
    reference_component_flux_name = oil_reference_component_flux
    reference_component_source_name = unused_oil_source
  []
  [gas_component_flux]
    type = ADRegisteredPhaseComponentFluxMaterial
    phase_registry = phases
    phases = 'oil gas water'
    component = 2
    phase_reference_relative_mass_flux_names = 'oil_reference_relative_mass_flux gas_reference_relative_mass_flux water_reference_relative_mass_flux'
    phase_component_mass_fraction_names = 'benchmark_black_oil_gas_component_mass_fraction_in_oil benchmark_black_oil_gas_component_mass_fraction_in_gas zero_component_fraction'
    reference_component_flux_name = gas_reference_component_flux
    reference_component_source_name = unused_gas_source
  []

  [inactive_well_sources]
    type = ADGenericConstantMaterial
    block = '1 2 3'
    prop_names = 'spe1_well_water_reference_component_source spe1_well_oil_reference_component_source spe1_well_gas_reference_component_source'
    prop_values = '0 0 0'
  []
  [injector_relative_permeability]
    type = ADGenericConstantMaterial
    block = 11
    prop_names = 'injector_water_relative_permeability injector_oil_relative_permeability injector_gas_relative_permeability'
    prop_values = '0 0 1'
  []
  [injector]
    type = ADBlackOilPeacemanWellMaterial
    block = 11
    pressure_source = material
    water_pressure_name = spe1_oil_pressure_total
    oil_pressure_name = spe1_oil_pressure_total
    gas_pressure_name = spe1_oil_pressure_total
    mobility_source = relative_permeability_viscosity
    water_relative_permeability_name = injector_water_relative_permeability
    oil_relative_permeability_name = injector_oil_relative_permeability
    gas_relative_permeability_name = injector_gas_relative_permeability
    water_viscosity_name = benchmark_black_oil_water_viscosity
    oil_viscosity_name = benchmark_black_oil_oil_viscosity
    gas_viscosity_name = benchmark_black_oil_gas_viscosity
    water_fvf_name = benchmark_black_oil_water_formation_volume_factor
    oil_fvf_name = benchmark_black_oil_oil_formation_volume_factor
    gas_fvf_name = benchmark_black_oil_gas_formation_volume_factor
    solution_gas_oil_ratio_name = benchmark_black_oil_solution_gas_oil_ratio
    well_index = 2.8317755055348615e-12
    control_mode = scalar_bhp
    bottom_hole_pressure_variable = injector_bhp_scalar
    injection_phase = gas
    target_surface_rate = -32.774128
    completion_reference_volume = 566336.9318400001
    water_surface_density = 1033.0307029866894
    oil_surface_density = 859.5507446467011
    gas_surface_density = 0.8537840978320755
    property_prefix = spe1_well
  []
  [producer]
    type = ADBlackOilPeacemanWellMaterial
    block = 13
    pressure_source = material
    water_pressure_name = spe1_oil_pressure_total
    oil_pressure_name = spe1_oil_pressure_total
    gas_pressure_name = spe1_oil_pressure_total
    mobility_source = relative_permeability_viscosity
    water_relative_permeability_name = black_oil_water_relative_permeability
    oil_relative_permeability_name = black_oil_oil_relative_permeability
    gas_relative_permeability_name = black_oil_gas_relative_permeability
    water_viscosity_name = benchmark_black_oil_water_viscosity
    oil_viscosity_name = benchmark_black_oil_oil_viscosity
    gas_viscosity_name = benchmark_black_oil_gas_viscosity
    water_fvf_name = benchmark_black_oil_water_formation_volume_factor
    oil_fvf_name = benchmark_black_oil_oil_formation_volume_factor
    gas_fvf_name = benchmark_black_oil_gas_formation_volume_factor
    solution_gas_oil_ratio_name = benchmark_black_oil_solution_gas_oil_ratio
    well_index = 2.8317755055348615e-12
    control_mode = scalar_bhp
    bottom_hole_pressure_variable = producer_bhp_scalar
    target_surface_rate = 0.03680261456666667
    completion_reference_volume = 1415842.3296
    water_surface_density = 1033.0307029866894
    oil_surface_density = 859.5507446467011
    gas_surface_density = 0.8537840978320755
    property_prefix = spe1_well
  []
[]

[Kernels]
  [water_balance]
    type = ADEnrichedGalerkinScalarBalance
    variable = water_saturation
    reference_component_storage_rate_name = benchmark_black_oil_water_reference_component_storage_rate
    reference_flux_name = water_reference_component_flux
    source_name = spe1_well_water_reference_component_source
  []
  [oil_balance]
    type = ADEnrichedGalerkinScalarBalance
    variable = oil_pressure
    enrichment = oil_pressure_enrichment
    reference_component_storage_rate_name = benchmark_black_oil_oil_reference_component_storage_rate
    reference_flux_name = oil_reference_component_flux
    source_name = spe1_well_oil_reference_component_source
  []
  [oil_enrichment_balance]
    type = ADEnrichedGalerkinScalarEnrichmentBalance
    variable = oil_pressure_enrichment
    backbone = oil_pressure
    reference_component_storage_rate_name = benchmark_black_oil_oil_reference_component_storage_rate
    source_name = spe1_well_oil_reference_component_source
    # Fix only the redundant global P1/P0 decomposition; all constitutive
    # objects consume the reconstructed total pressure.
    anchor_coefficient = 1e-12
  []
  [gas_balance]
    type = ADEnrichedGalerkinScalarBalance
    variable = gas_saturation
    reference_component_storage_rate_name = benchmark_black_oil_gas_reference_component_storage_rate
    reference_flux_name = gas_reference_component_flux
    source_name = spe1_well_gas_reference_component_source
  []
  [dissolved_gas_history]
    type = ADMaterialPropertyResidual
    variable = solution_gas_oil_ratio
    property = benchmark_black_oil_gas_appearance_complementarity_residual
  []
[]

[DGKernels]
  [oil_enrichment_flux]
    type = ADEnrichedGalerkinFluxDG
    variable = oil_pressure_enrichment
    reference_flux_name = oil_reference_component_flux
    mobility_name = oil_darcy_mobility
    epsilon = -1
    sigma = 10
  []
  [oil_backbone_symmetry]
    type = ADEnrichedGalerkinSymmetryDG
    variable = oil_pressure
    enrichment = oil_pressure_enrichment
    mobility_name = oil_darcy_mobility
    epsilon = -1
  []
[]

[ScalarKernels]
  [injector_control]
    type = BlackOilNodalWellControl
    variable = injector_bhp_scalar
    boundary = spe1_injector_completion_nodes
    pressure = oil_pressure
    surface_rate = injector_gas_surface_rate
    surface_productivity = injector_gas_surface_productivity
    target_surface_rate = -32.774128
    apply_bhp_limit = true
    bhp_limit_type = maximum
    bhp_limit = 62149342.24061635
  []
  [producer_control]
    type = BlackOilNodalWellControl
    variable = producer_bhp_scalar
    boundary = spe1_producer_completion_nodes
    pressure = oil_pressure
    surface_rate = producer_oil_surface_rate
    surface_productivity = producer_oil_surface_productivity
    target_surface_rate = 0.03680261456666667
    apply_bhp_limit = true
    bhp_limit_type = minimum
    bhp_limit = 6894757.293168
  []
[]

[Postprocessors]
  [average_oil_pressure]
    type = ADElementAverageMaterialProperty
    mat_prop = spe1_oil_pressure_total
  []
  [average_water_saturation]
    type = ElementAverageValue
    variable = water_saturation
  []
  [average_gas_saturation]
    type = ElementAverageValue
    variable = gas_saturation
  []
  [minimum_gas_saturation]
    type = ElementExtremeValue
    variable = gas_saturation
    value_type = min
  []
  [maximum_gas_saturation]
    type = ElementExtremeValue
    variable = gas_saturation
    value_type = max
  []
  [average_solution_gas_oil_ratio]
    type = ElementAverageValue
    variable = solution_gas_oil_ratio
  []
  [water_storage_rate_integral]
    type = ADElementIntegralMaterialProperty
    mat_prop = benchmark_black_oil_water_reference_component_storage_rate
  []
  [oil_storage_rate_integral]
    type = ADElementIntegralMaterialProperty
    mat_prop = benchmark_black_oil_oil_reference_component_storage_rate
  []
  [gas_storage_rate_integral]
    type = ADElementIntegralMaterialProperty
    mat_prop = benchmark_black_oil_gas_reference_component_storage_rate
  []
  [water_source_integral]
    type = ADElementIntegralMaterialProperty
    mat_prop = spe1_well_water_reference_component_source
  []
  [oil_source_integral]
    type = ADElementIntegralMaterialProperty
    mat_prop = spe1_well_oil_reference_component_source
  []
  [gas_source_integral]
    type = ADElementIntegralMaterialProperty
    mat_prop = spe1_well_gas_reference_component_source
  []
  [water_global_balance]
    type = LinearCombinationPostprocessor
    pp_names = 'water_storage_rate_integral water_source_integral'
    pp_coefs = '1 -1'
  []
  [oil_global_balance]
    type = LinearCombinationPostprocessor
    pp_names = 'oil_storage_rate_integral oil_source_integral'
    pp_coefs = '1 -1'
  []
  [gas_global_balance]
    type = LinearCombinationPostprocessor
    pp_names = 'gas_storage_rate_integral gas_source_integral'
    pp_coefs = '1 -1'
  []
  [injector_gas_surface_rate]
    type = ADElementAverageMaterialProperty
    block = 11
    mat_prop = spe1_well_gas_surface_rate
    execute_on = 'INITIAL LINEAR TIMESTEP_END'
  []
  [injector_cell_pressure]
    type = ADElementAverageMaterialProperty
    block = 11
    mat_prop = spe1_oil_pressure_total
  []
  [producer_cell_pressure]
    type = ADElementAverageMaterialProperty
    block = 13
    mat_prop = spe1_oil_pressure_total
  []
  [injector_water_surface_rate]
    type = ADElementAverageMaterialProperty
    block = 11
    mat_prop = spe1_well_water_surface_rate
    execute_on = 'INITIAL LINEAR TIMESTEP_END'
  []
  [injector_oil_surface_rate]
    type = ADElementAverageMaterialProperty
    block = 11
    mat_prop = spe1_well_oil_surface_rate
    execute_on = 'INITIAL LINEAR TIMESTEP_END'
  []
  [producer_oil_surface_rate]
    type = ADElementAverageMaterialProperty
    block = 13
    mat_prop = spe1_well_oil_surface_rate
    execute_on = 'INITIAL LINEAR TIMESTEP_END'
  []
  [producer_water_surface_rate]
    type = ADElementAverageMaterialProperty
    block = 13
    mat_prop = spe1_well_water_surface_rate
    execute_on = 'INITIAL LINEAR TIMESTEP_END'
  []
  [producer_gas_surface_rate]
    type = ADElementAverageMaterialProperty
    block = 13
    mat_prop = spe1_well_gas_surface_rate
    execute_on = 'INITIAL LINEAR TIMESTEP_END'
  []
  [field_gas_oil_ratio]
    type = ParsedPostprocessor
    expression = 'q_g/q_o'
    pp_names = 'producer_gas_surface_rate producer_oil_surface_rate'
    pp_symbols = 'q_g q_o'
  []
  [injected_gas_surface_rate]
    type = LinearCombinationPostprocessor
    pp_names = 'injector_gas_surface_rate'
    pp_coefs = '-1'
  []
  [injected_gas_surface_volume]
    type = ImplicitEulerTimeIntegratedPostprocessor
    value = injected_gas_surface_rate
  []
  [produced_oil_surface_volume]
    type = ImplicitEulerTimeIntegratedPostprocessor
    value = producer_oil_surface_rate
  []
  [produced_gas_surface_volume]
    type = ImplicitEulerTimeIntegratedPostprocessor
    value = producer_gas_surface_rate
  []
  [produced_water_surface_volume]
    type = ImplicitEulerTimeIntegratedPostprocessor
    value = producer_water_surface_rate
  []
  [gas_saturation_1_1_1]
    type = PointValue
    variable = gas_saturation
    point = '152.4 152.4 2540.508'
  []
  [gas_saturation_1_1_2]
    type = PointValue
    variable = gas_saturation
    point = '152.4 152.4 2548.128'
  []
  [gas_saturation_1_1_3]
    type = PointValue
    variable = gas_saturation
    point = '152.4 152.4 2560.32'
  []
  [gas_saturation_10_1_1]
    type = PointValue
    variable = gas_saturation
    point = '2895.6 152.4 2540.508'
  []
  [gas_saturation_10_1_2]
    type = PointValue
    variable = gas_saturation
    point = '2895.6 152.4 2548.128'
  []
  [gas_saturation_10_1_3]
    type = PointValue
    variable = gas_saturation
    point = '2895.6 152.4 2560.32'
  []
  [gas_saturation_10_10_1]
    type = PointValue
    variable = gas_saturation
    point = '2895.6 2895.6 2540.508'
  []
  [gas_saturation_10_10_2]
    type = PointValue
    variable = gas_saturation
    point = '2895.6 2895.6 2548.128'
  []
  [gas_saturation_10_10_3]
    type = PointValue
    variable = gas_saturation
    point = '2895.6 2895.6 2560.32'
  []
  [injector_gas_surface_productivity]
    type = ADElementAverageMaterialProperty
    block = 11
    mat_prop = spe1_well_control_surface_productivity
    execute_on = 'INITIAL LINEAR TIMESTEP_END'
    outputs = none
  []
  [producer_oil_surface_productivity]
    type = ADElementAverageMaterialProperty
    block = 13
    mat_prop = spe1_well_control_surface_productivity
    execute_on = 'INITIAL LINEAR TIMESTEP_END'
    outputs = none
  []
  [injector_bhp]
    type = ADElementAverageMaterialProperty
    block = 11
    mat_prop = spe1_well_effective_bottom_hole_pressure
  []
  [producer_bhp]
    type = ADElementAverageMaterialProperty
    block = 13
    mat_prop = spe1_well_effective_bottom_hole_pressure
  []
[]

[Executioner]
  type = Transient
  scheme = implicit-euler
  solve_type = NEWTON
  dt = 86400
  nl_abs_tol = 1e-8
  nl_rel_tol = 1e-10
  nl_max_its = 40
  petsc_options_iname = '-pc_type -pc_factor_mat_solver_package'
  petsc_options_value = 'lu mumps'
[]

[Outputs]
  csv = true
[]
