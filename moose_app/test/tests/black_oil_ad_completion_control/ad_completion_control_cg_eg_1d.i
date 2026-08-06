[Mesh]
  [two_blocks]
    type = CartesianMeshGenerator
    dim = 1
    dx = '1 1'
    ix = '1 1'
    subdomain_id = '1 2'
  []
  [all_nodes]
    type = ExtraNodesetGenerator
    input = two_blocks
    new_boundary = all_nodes
    nodes = '0 1 2'
  []
  final_generator = all_nodes
[]

[Variables]
  [oil_pressure]
    family = LAGRANGE
    order = FIRST
  []
  [oil_pressure_enrichment]
    family = MONOMIAL
    order = CONSTANT
  []
  [datum_bhp]
    family = SCALAR
    order = FIRST
    initial_condition = 90
  []
  [total_oil_rate]
    family = SCALAR
    order = FIRST
    initial_condition = 40
  []
[]

[Functions]
  [oil_pressure]
    type = ParsedFunction
    expression = '115+10*x'
  []
[]

[ICs]
  [oil_pressure]
    type = FunctionIC
    variable = oil_pressure
    function = oil_pressure
  []
[]

[Materials]
  [reconstructed_oil_pressure]
    type = ADParsedMaterial
    coupled_variables = 'oil_pressure oil_pressure_enrichment'
    property_name = reconstructed_oil_pressure
    expression = 'oil_pressure+oil_pressure_enrichment'
  []
  [completion_state]
    type = ADGenericConstantMaterial
    prop_names = 'water_mobility oil_mobility gas_mobility water_fvf oil_fvf gas_fvf solution_gas_oil_ratio'
    prop_values = '0 1 0 1 1 1 0'
  []
  [completion_1_well]
    type = ADBlackOilPeacemanWellMaterial
    block = 1
    pressure_source = material
    water_pressure_name = reconstructed_oil_pressure
    oil_pressure_name = reconstructed_oil_pressure
    gas_pressure_name = reconstructed_oil_pressure
    water_mobility_name = water_mobility
    oil_mobility_name = oil_mobility
    gas_mobility_name = gas_mobility
    water_fvf_name = water_fvf
    oil_fvf_name = oil_fvf
    gas_fvf_name = gas_fvf
    solution_gas_oil_ratio_name = solution_gas_oil_ratio
    well_index = 2
    control_mode = scalar_bhp
    bottom_hole_pressure_variable = datum_bhp
    target_surface_rate = 0
    apply_datum_correction = true
    wellbore_density = 1
    gravity_magnitude = 1
    completion_depth = 100
    bhp_datum_depth = 90
    completion_reference_volume = 1
    water_surface_density = 1000
    oil_surface_density = 800
    gas_surface_density = 1
    property_prefix = completion_1
  []
  [completion_2_well]
    type = ADBlackOilPeacemanWellMaterial
    block = 2
    pressure_source = material
    water_pressure_name = reconstructed_oil_pressure
    oil_pressure_name = reconstructed_oil_pressure
    gas_pressure_name = reconstructed_oil_pressure
    water_mobility_name = water_mobility
    oil_mobility_name = oil_mobility
    gas_mobility_name = gas_mobility
    water_fvf_name = water_fvf
    oil_fvf_name = oil_fvf
    gas_fvf_name = gas_fvf
    solution_gas_oil_ratio_name = solution_gas_oil_ratio
    well_index = 3
    control_mode = scalar_bhp
    bottom_hole_pressure_variable = datum_bhp
    target_surface_rate = 0
    apply_datum_correction = true
    wellbore_density = 1
    gravity_magnitude = 1
    completion_depth = 110
    bhp_datum_depth = 90
    completion_reference_volume = 1
    water_surface_density = 1000
    oil_surface_density = 800
    gas_surface_density = 1
    property_prefix = completion_2
  []
[]

[Kernels]
  [pressure_reaction]
    type = ADReaction
    variable = oil_pressure
  []
  [enrichment_reaction]
    type = ADReaction
    variable = oil_pressure_enrichment
  []
  [completion_1_enrichment]
    type = ADBodyForce
    variable = oil_pressure_enrichment
    block = 1
    value = 5
  []
  [completion_2_enrichment]
    type = ADBodyForce
    variable = oil_pressure_enrichment
    block = 2
    value = -5
  []
  [completion_1_rate_constraint]
    type = ADBlackOilCompletionRateConstraint
    variable = oil_pressure
    block = 1
    well_rate = total_oil_rate
    surface_rate_name = completion_1_oil_surface_rate
    completion_reference_volume = 1
    well_rate_fraction = 0.5
  []
  [completion_2_rate_constraint]
    type = ADBlackOilCompletionRateConstraint
    variable = oil_pressure
    block = 2
    well_rate = total_oil_rate
    surface_rate_name = completion_2_oil_surface_rate
    completion_reference_volume = 1
    well_rate_fraction = 0.5
  []
[]

[BCs]
  [prescribed_pressure]
    type = FunctionDirichletBC
    variable = oil_pressure
    boundary = all_nodes
    function = oil_pressure
  []
[]

[ScalarKernels]
  [total_oil_rate_coverage]
    # The element-integrated AD constraint owns this scalar equation. This
    # zero object exposes that ownership to MOOSE's generic coverage audit.
    type = NullScalarKernel
    variable = total_oil_rate
  []
  [rate_bhp_control]
    type = ADBlackOilRateBHPComplementarity
    variable = datum_bhp
    well_rate = total_oil_rate
    target_surface_rate = 50
  []
[]

[Postprocessors]
  [completion_1_oil_surface_rate]
    type = ADElementAverageMaterialProperty
    block = 1
    mat_prop = completion_1_oil_surface_rate
    execute_on = 'INITIAL LINEAR TIMESTEP_END'
  []
  [completion_2_oil_surface_rate]
    type = ADElementAverageMaterialProperty
    block = 2
    mat_prop = completion_2_oil_surface_rate
    execute_on = 'INITIAL LINEAR TIMESTEP_END'
  []
  [reported_datum_bhp]
    type = ScalarVariable
    variable = datum_bhp
  []
  [reported_total_oil_rate]
    type = ScalarVariable
    variable = total_oil_rate
  []
  [completion_1_enrichment_value]
    type = ElementAverageValue
    variable = oil_pressure_enrichment
    block = 1
  []
  [completion_2_enrichment_value]
    type = ElementAverageValue
    variable = oil_pressure_enrichment
    block = 2
  []
[]

[Executioner]
  type = Steady
  solve_type = NEWTON
  nl_abs_tol = 1e-12
  nl_rel_tol = 1e-12
  petsc_options_iname = '-pc_type -pc_factor_mat_solver_package'
  petsc_options_value = 'lu mumps'
[]

[Outputs]
  csv = true
[]

