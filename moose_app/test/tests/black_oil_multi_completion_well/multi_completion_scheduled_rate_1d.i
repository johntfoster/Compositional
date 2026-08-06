[Mesh]
  [two_blocks]
    type = CartesianMeshGenerator
    dim = 1
    dx = '1 1'
    ix = '1 1'
    subdomain_id = '1 2'
  []
  [completion_1]
    type = ExtraNodesetGenerator
    input = two_blocks
    new_boundary = completion_1
    nodes = '0 1'
  []
  [completion_2]
    type = ExtraNodesetGenerator
    input = completion_1
    new_boundary = completion_2
    nodes = '1 2'
  []
  [all_completion_nodes]
    type = ExtraNodesetGenerator
    input = completion_2
    new_boundary = all_completion_nodes
    nodes = '0 1 2'
  []
  final_generator = all_completion_nodes
[]

[Variables]
  [oil_pressure]
    family = LAGRANGE
    order = FIRST
  []
  [datum_bhp]
    family = SCALAR
    order = FIRST
    initial_condition = 90
  []
[]

[Functions]
  [oil_pressure]
    type = ParsedFunction
    expression = '115+10*x'
  []
  [scheduled_oil_rate]
    type = PiecewiseConstant
    x = '0 1.5'
    y = '50 25'
    direction = left
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
  [completion_1_state]
    type = ADGenericConstantMaterial
    block = 1
    prop_names = 'water_mobility oil_mobility gas_mobility water_fvf oil_fvf gas_fvf solution_gas_oil_ratio'
    prop_values = '0 1 0 1 1 1 0'
  []
  [completion_2_state]
    type = ADGenericConstantMaterial
    block = 2
    prop_names = 'water_mobility oil_mobility gas_mobility water_fvf oil_fvf gas_fvf solution_gas_oil_ratio'
    prop_values = '0 1 0 1 1 1 0'
  []
  [completion_1_well]
    type = ADBlackOilPeacemanWellMaterial
    block = 1
    pressure_source = coupled
    water_pressure = oil_pressure
    oil_pressure = oil_pressure
    gas_pressure = oil_pressure
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
    target_surface_rate = 50
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
    pressure_source = coupled
    water_pressure = oil_pressure
    oil_pressure = oil_pressure
    gas_pressure = oil_pressure
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
    target_surface_rate = 50
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
[]

[BCs]
  [prescribed_pressure]
    type = FunctionDirichletBC
    variable = oil_pressure
    boundary = all_completion_nodes
    function = oil_pressure
  []
[]

[ScalarKernels]
  [multi_completion_control]
    type = BlackOilMultiCompletionWellControl
    variable = datum_bhp
    boundary = all_completion_nodes
    completion_boundaries = 'completion_1 completion_2'
    pressure = oil_pressure
    surface_rates = 'completion_1_oil_surface_rate completion_2_oil_surface_rate'
    surface_productivities = 'completion_1_oil_surface_productivity completion_2_oil_surface_productivity'
    target_surface_rate = 0
    target_surface_rate_function = scheduled_oil_rate
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
  [completion_1_oil_surface_productivity]
    type = ADElementAverageMaterialProperty
    block = 1
    mat_prop = completion_1_control_surface_productivity
    execute_on = 'INITIAL LINEAR TIMESTEP_END'
    outputs = none
  []
  [completion_2_oil_surface_productivity]
    type = ADElementAverageMaterialProperty
    block = 2
    mat_prop = completion_2_control_surface_productivity
    execute_on = 'INITIAL LINEAR TIMESTEP_END'
    outputs = none
  []
  [total_oil_surface_rate]
    type = LinearCombinationPostprocessor
    pp_names = 'completion_1_oil_surface_rate completion_2_oil_surface_rate'
    pp_coefs = '1 1'
  []
  [reported_datum_bhp]
    type = ScalarVariable
    variable = datum_bhp
  []
  [completion_1_bhp]
    type = ADElementAverageMaterialProperty
    block = 1
    mat_prop = completion_1_effective_bottom_hole_pressure
  []
  [completion_2_bhp]
    type = ADElementAverageMaterialProperty
    block = 2
    mat_prop = completion_2_effective_bottom_hole_pressure
  []
  [completion_1_datum_bhp]
    type = ADElementAverageMaterialProperty
    block = 1
    mat_prop = completion_1_datum_bottom_hole_pressure
  []
  [completion_2_datum_bhp]
    type = ADElementAverageMaterialProperty
    block = 2
    mat_prop = completion_2_datum_bottom_hole_pressure
  []
  [completion_1_datum_correction]
    type = ADElementAverageMaterialProperty
    block = 1
    mat_prop = completion_1_datum_pressure_correction
  []
  [completion_2_datum_correction]
    type = ADElementAverageMaterialProperty
    block = 2
    mat_prop = completion_2_datum_pressure_correction
  []
[]

[Executioner]
  type = Transient
  start_time = 0
  end_time = 2
  dt = 1
  solve_type = NEWTON
  nl_abs_tol = 1e-12
  nl_rel_tol = 1e-12
  petsc_options_iname = '-pc_type -pc_factor_mat_solver_package'
  petsc_options_value = 'lu mumps'
[]

[Outputs]
  csv = true
[]


