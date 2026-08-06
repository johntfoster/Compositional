!include ../../../input/includes/mesh/spe2_rz_q2_quad9.i

[Variables]
  [oil_pressure]
    family = LAGRANGE
    order = FIRST
    initial_condition = 0
  []
  [producer_bhp_scalar]
    family = SCALAR
    order = FIRST
    initial_condition = 24804155.647622354
    scaling = 1e-7
  []
[]

!include ../../../input/includes/fields/spe2_producer_control.i
!include ../../../input/includes/schedules/spe2_oil_rate_schedule.i

[Materials]
  [spe2_background_test_state]
    type = ADGenericConstantMaterial
    block = '1 2 3 4 5 6 7 8 9 10 11 12 13 14 15'
    prop_names = spe2_background_marker
    prop_values = 0
  []
  [spe2_completion_test_state]
    type = ADGenericConstantMaterial
    block = '107 108'
    prop_names = 'spe2_water_pressure spe2_oil_pressure_total spe2_gas_pressure spe2_black_oil_water_relative_permeability spe2_black_oil_oil_relative_permeability spe2_black_oil_gas_relative_permeability benchmark_black_oil_water_viscosity benchmark_black_oil_oil_viscosity benchmark_black_oil_gas_viscosity benchmark_black_oil_water_formation_volume_factor benchmark_black_oil_oil_formation_volume_factor benchmark_black_oil_gas_formation_volume_factor benchmark_black_oil_solution_gas_oil_ratio benchmark_black_oil_oil_intrinsic_density'
    prop_values = '25000000 25000000 25000000 0 1 0 0.001 0.001 0.001 1 1.1 1 0 900'
  []
[]

!include ../../../input/includes/materials/spe2_producer_well.i

[Kernels]
  [prescribed_oil_pressure]
    type = ADReaction
    variable = oil_pressure
  []
[]

!include ../../../input/includes/operators/spe2_producer_control.i

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



