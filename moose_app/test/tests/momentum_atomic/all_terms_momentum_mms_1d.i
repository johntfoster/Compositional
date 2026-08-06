mesh_nx := 8
!include ../../../input/includes/mesh/generated_1d_q2.i

[Variables]
  [phase_velocity]
    family = LAGRANGE
    order = SECOND
  []
  [ux]
    family = LAGRANGE
    order = SECOND
  []
[]

[AuxVariables]
  [bulk_density][]
  [phase_fraction][]
  [fluid_fraction][]
  [conversion_rate][]
  [tau]
    family = LAGRANGE
    order = SECOND
  []
  [equivalent_pressure]
    family = LAGRANGE
    order = SECOND
  []
  [stored_capillary]
    family = LAGRANGE
    order = SECOND
  []
  [electric_pressure]
    family = LAGRANGE
    order = SECOND
  []
  [temperature]
    family = LAGRANGE
    order = SECOND
  []
  [history_1]
    family = LAGRANGE
    order = SECOND
  []
  [history_2]
    family = LAGRANGE
    order = SECOND
  []
  [saturation_1]
    family = LAGRANGE
    order = SECOND
  []
  [saturation_2]
    family = LAGRANGE
    order = SECOND
  []
[]

[Functions]
  [phase_velocity_exact]
    type = ParsedFunction
    expression = '1+t+x^2'
  []
  [ux_exact]
    type = ParsedFunction
    expression = 't+x^2'
  []
  [x_squared]
    type = ParsedFunction
    expression = 'x^2'
  []
  [two_x_squared]
    type = ParsedFunction
    expression = '2*x^2'
  []
  [three_x_squared]
    type = ParsedFunction
    expression = '3*x^2'
  []
  [phase_stress_00]
    type = ParsedFunction
    expression = 'x^2'
  []
  [phase_maxwell_00]
    type = ParsedFunction
    expression = '2*x^2'
  []
  [overall_maxwell_00]
    type = ParsedFunction
    expression = 'x^2'
  []
  [phase_manufactured_source]
    type = ParsedFunction
    expression = '0.1-4.6*x+2*x*t+2*x^3+0.7*t+0.7*x^2'
  []
  [overall_manufactured_source]
    type = ParsedFunction
    expression = '-2*(1+(2-log(1+2*x))/(1+2*x)^2)-x'
  []
  [zero]
    type = ParsedFunction
    expression = '0'
  []
[]

[ICs]
  [phase_velocity_ic]
    type = FunctionIC
    variable = phase_velocity
    function = phase_velocity_exact
  []
  [ux_ic]
    type = FunctionIC
    variable = ux
    function = ux_exact
  []
  [bulk_density_ic]
    type = ConstantIC
    variable = bulk_density
    value = 1
  []
  [phase_fraction_ic]
    type = ConstantIC
    variable = phase_fraction
    value = 0.5
  []
  [fluid_fraction_ic]
    type = ConstantIC
    variable = fluid_fraction
    value = 0.5
  []
  [conversion_rate_ic]
    type = ConstantIC
    variable = conversion_rate
    value = 0.2
  []
[]

[Materials]
  [reference_jacobian]
    type = ADGenericConstantMaterial
    prop_names = 'solid_reference_J surface_energy_temperature_derivative
                  surface_energy_history_derivative_1 surface_energy_history_derivative_2
                  pressure_lag_1 pressure_lag_2'
    prop_values = '1 0.2 0.3 0.4 0.5 0.6'
  []
  [reference_inverse]
    type = ADGenericConstantRankTwoTensor
    tensor_name = solid_reference_F_inv
    tensor_values = '1 0 0 0 1 0 0 0 1'
  []
  [overall_kinematics]
    type = ADSolidReferenceKinematics
    displacements = ux
    deformation_gradient_name = overall_F
    jacobian_name = overall_J
    jacobian_dot_name = overall_J_dot
    inverse_deformation_gradient_name = overall_F_inv
    jacobian_inverse_deformation_gradient_name = overall_J_F_inv
  []
  [overall_neo_hookean_stress]
    type = ADCompressibleNeoHookeanReferenceStressMaterial
    deformation_gradient_name = overall_F
    jacobian_name = overall_J
    inverse_deformation_gradient_name = overall_F_inv
    effective_first_piola_name = overall_material_piola_stress
    shear_modulus = 1
    lame_lambda = 1
  []
  [phase_material_stress]
    type = ADGenericFunctionRankTwoTensor
    tensor_name = phase_material_piola_stress
    tensor_functions = 'phase_stress_00 zero zero zero zero zero zero zero zero'
  []
  [phase_maxwell_stress]
    type = ADGenericFunctionRankTwoTensor
    tensor_name = phase_maxwell_piola_stress
    tensor_functions = 'phase_maxwell_00 zero zero zero zero zero zero zero zero'
  []
  [overall_maxwell_stress]
    type = ADGenericFunctionRankTwoTensor
    tensor_name = overall_maxwell_piola_stress
    tensor_functions = 'overall_maxwell_00 zero zero zero zero zero zero zero zero'
  []
  [momentum_vector_sources]
    type = ADGenericConstantVectorMaterial
    prop_names = 'gravity_body_source pairwise_interaction_source'
    prop_values = '0.5 0 0 0.6 0 0'
  []
[]

[AuxKernels]
  [tau_prescribed]
    type = FunctionAux
    variable = tau
    function = x_squared
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [equivalent_pressure_prescribed]
    type = FunctionAux
    variable = equivalent_pressure
    function = x_squared
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [stored_capillary_prescribed]
    type = FunctionAux
    variable = stored_capillary
    function = x_squared
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [electric_pressure_prescribed]
    type = FunctionAux
    variable = electric_pressure
    function = x_squared
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [temperature_prescribed]
    type = FunctionAux
    variable = temperature
    function = x_squared
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [history_1_prescribed]
    type = FunctionAux
    variable = history_1
    function = x_squared
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [history_2_prescribed]
    type = FunctionAux
    variable = history_2
    function = two_x_squared
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [saturation_1_prescribed]
    type = FunctionAux
    variable = saturation_1
    function = x_squared
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [saturation_2_prescribed]
    type = FunctionAux
    variable = saturation_2
    function = three_x_squared
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
[]

[Kernels]
  [phase_inertia]
    type = ADPhaseMomentumInertiaTerm
    variable = phase_velocity
    component = 0
    phase_velocity = phase_velocity
    solid_displacements = ux
    bulk_density = bulk_density
  []
  [phase_material_stress]
    type = ADPhaseMomentumStressTerm
    variable = phase_velocity
    component = 0
    piola_stress_name = phase_material_piola_stress
  []
  [phase_maxwell_stress]
    type = ADPhaseMomentumStressTerm
    variable = phase_velocity
    component = 0
    piola_stress_name = phase_maxwell_piola_stress
  []
  [phase_equivalent_pressure]
    type = ADPhaseMomentumScalarGradientTerm
    variable = phase_velocity
    component = 0
    potential = equivalent_pressure
    coefficient = 0.2
  []
  [phase_stored_capillary]
    type = ADPhaseMomentumScalarGradientTerm
    variable = phase_velocity
    component = 0
    potential = stored_capillary
    coefficient = 0.3
  []
  [phase_electric_enthalpy_pressure]
    type = ADPhaseMomentumScalarGradientTerm
    variable = phase_velocity
    component = 0
    potential = electric_pressure
    coefficient = 0.4
  []
  [phase_gravity]
    type = ADPhaseMomentumVectorSourceTerm
    variable = phase_velocity
    component = 0
    source_name = gravity_body_source
  []
  [phase_pairwise_interaction]
    type = ADPhaseMomentumVectorSourceTerm
    variable = phase_velocity
    component = 0
    source_name = pairwise_interaction_source
  []
  [phase_drag]
    type = ADPhaseMomentumDragTerm
    variable = phase_velocity
    component = 0
    phase_velocity = phase_velocity
    solid_displacements = ux
    phase_fraction = phase_fraction
    viscosity = 2
    permeability = 1
  []
  [phase_conversion_insertion]
    type = ADPhaseMomentumConversionInsertionTerm
    variable = phase_velocity
    component = 0
    conversion_rate = conversion_rate
    tau = tau
    phase_velocity_component = phase_velocity
  []
  [phase_manufactured_load]
    type = ADPhaseMomentumFunctionSourceTerm
    variable = phase_velocity
    source = phase_manufactured_source
  []

  [overall_material_stress]
    type = ADPhaseMomentumStressTerm
    variable = ux
    component = 0
    piola_stress_name = overall_material_piola_stress
  []
  [overall_maxwell_stress]
    type = ADPhaseMomentumStressTerm
    variable = ux
    component = 0
    piola_stress_name = overall_maxwell_piola_stress
  []
  [overall_equivalent_pressure]
    type = ADPhaseMomentumScalarGradientTerm
    variable = ux
    component = 0
    potential = equivalent_pressure
    solid_jacobian_name = overall_J
    solid_inverse_deformation_gradient_name = overall_F_inv
  []
  [overall_thermocapillary]
    type = ADOverallMomentumThermocapillaryTerm
    variable = ux
    component = 0
    temperature = temperature
    fluid_fraction = fluid_fraction
    surface_energy_temperature_derivative_name = surface_energy_temperature_derivative
    solid_jacobian_name = overall_J
    solid_inverse_deformation_gradient_name = overall_F_inv
  []
  [overall_capillary_history]
    type = ADOverallMomentumCapillaryHistoryGradientTerm
    variable = ux
    component = 0
    history_variables = 'history_1 history_2'
    fluid_fraction = fluid_fraction
    surface_energy_history_derivative_names = 'surface_energy_history_derivative_1 surface_energy_history_derivative_2'
    solid_jacobian_name = overall_J
    solid_inverse_deformation_gradient_name = overall_F_inv
  []
  [overall_dynamic_pressure_lag]
    type = ADOverallMomentumDynamicPressureLagTerm
    variable = ux
    component = 0
    saturations = 'saturation_1 saturation_2'
    fluid_fraction = fluid_fraction
    pressure_lag_names = 'pressure_lag_1 pressure_lag_2'
    solid_jacobian_name = overall_J
    solid_inverse_deformation_gradient_name = overall_F_inv
  []
  [overall_manufactured_load]
    type = ADPhaseMomentumFunctionSourceTerm
    variable = ux
    source = overall_manufactured_source
  []
[]

[BCs]
  [phase_velocity_exact]
    type = FunctionDirichletBC
    variable = phase_velocity
    boundary = 'left right'
    function = phase_velocity_exact
  []
  [ux_exact]
    type = FunctionDirichletBC
    variable = ux
    boundary = 'left right'
    function = ux_exact
  []
[]

[Postprocessors]
  [phase_velocity_l2]
    type = ElementL2Error
    variable = phase_velocity
    function = phase_velocity_exact
  []
  [overall_displacement_l2]
    type = ElementL2Error
    variable = ux
    function = ux_exact
  []
[]

[Executioner]
  type = Transient
  solve_type = NEWTON
  automatic_scaling = false
  scheme = implicit-euler
  dt = 0.05
  end_time = 0.1
  line_search = bt
  nl_rel_tol = 1e-14
  nl_abs_tol = 1e-14
  nl_max_its = 20
  petsc_options_iname = '-pc_type -pc_factor_mat_solver_type'
  petsc_options_value = 'lu superlu_dist'
[]

[Outputs]
  csv = true
[]
