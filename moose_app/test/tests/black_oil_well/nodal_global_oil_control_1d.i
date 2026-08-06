[Mesh]
  [line]
    type = GeneratedMeshGenerator
    dim = 1
    nx = 1
  []
  [completion_nodes]
    type = ExtraNodesetGenerator
    input = line
    new_boundary = completion_nodes
    nodes = '0 1'
  []
  final_generator = completion_nodes
[]

[Variables]
  [oil_pressure]
    family = LAGRANGE
    order = FIRST
    initial_condition = 110
  []
  [well_bhp]
    family = SCALAR
    order = FIRST
    initial_condition = 100
  []
[]

[Materials]
  [well_state]
    type = ADGenericConstantMaterial
    prop_names = 'water_pressure oil_pressure_property gas_pressure water_mobility oil_mobility gas_mobility water_fvf oil_fvf gas_fvf solution_gas_oil_ratio'
    prop_values = '100 110 120 1 2 3 2 4 0.5 5'
  []
  [well]
    type = ADBlackOilPeacemanWellMaterial
    water_pressure_name = water_pressure
    oil_pressure_name = oil_pressure_property
    gas_pressure_name = gas_pressure
    water_mobility_name = water_mobility
    oil_mobility_name = oil_mobility
    gas_mobility_name = gas_mobility
    water_fvf_name = water_fvf
    oil_fvf_name = oil_fvf
    gas_fvf_name = gas_fvf
    solution_gas_oil_ratio_name = solution_gas_oil_ratio
    well_index = 2
    control_mode = scalar_bhp
    bottom_hole_pressure_variable = well_bhp
    target_surface_rate = 20
    completion_reference_volume = 10
    water_surface_density = 1000
    oil_surface_density = 800
    gas_surface_density = 1.2
  []
[]

[BCs]
  [left_pressure]
    type = DirichletBC
    variable = oil_pressure
    boundary = left
    value = 110
  []
  [right_pressure]
    type = DirichletBC
    variable = oil_pressure
    boundary = right
    value = 110
  []
[]

[Kernels]
  [pressure_reaction]
    type = Reaction
    variable = oil_pressure
  []
[]

[ScalarKernels]
  [well_control]
    type = BlackOilNodalWellControl
    variable = well_bhp
    boundary = completion_nodes
    pressure = oil_pressure
    surface_rate = oil_surface_rate
    surface_productivity = oil_surface_productivity
    target_surface_rate = 20
  []
[]

[Postprocessors]
  [oil_surface_rate]
    type = ADElementAverageMaterialProperty
    mat_prop = black_oil_well_oil_surface_rate
    execute_on = 'INITIAL LINEAR TIMESTEP_END'
  []
  [oil_surface_productivity]
    type = ADElementAverageMaterialProperty
    mat_prop = black_oil_well_control_surface_productivity
    execute_on = 'INITIAL LINEAR TIMESTEP_END'
    outputs = none
  []
  [effective_bhp]
    type = ADElementAverageMaterialProperty
    mat_prop = black_oil_well_effective_bottom_hole_pressure
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
