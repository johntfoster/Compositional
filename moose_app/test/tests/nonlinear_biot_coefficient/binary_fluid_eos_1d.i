mesh_nx := 1

!include ../../../input/includes/mesh/generated_1d_q2.i
!include ../../../input/includes/fields/solid_q2_aux_1d.i

[AuxVariables]
  [phi_s]
    family = LAGRANGE
    order = SECOND
  []
[]

[Functions]
  [ux_exact]
    type = ParsedFunction
    expression = '0.1*x'
  []
[]

[ICs]
  [ux_ic]
    type = FunctionIC
    variable = ux
    function = ux_exact
  []
  [phi_ic]
    type = ConstantIC
    variable = phi_s
    value = 0.6
  []
[]

!include ../../../input/includes/materials/solid_kinematics_1d.i

[Materials]
  [pressure_state]
    type = ADGenericConstantMaterial
    prop_names = 'p_total p_total_dot'
    prop_values = '2 0'
  []
  [ideal_gas_storage]
    type = ADBinaryFluidStorageMaterial
    solid_volume_fraction = phi_s
    fluid_eos = ideal_gas
    reference_density = 1
    reference_absolute_pressure = 4
    intrinsic_density_name = ideal_gas_density
    reference_component_accumulation_name = ideal_gas_accumulation
    reference_component_storage_rate_name = ideal_gas_storage_rate
  []
  [constant_bulk_storage]
    type = ADBinaryFluidStorageMaterial
    solid_volume_fraction = phi_s
    fluid_eos = constant_bulk_modulus
    reference_density = 2
    bulk_modulus = 4
    intrinsic_density_name = constant_bulk_density
    reference_component_accumulation_name = constant_bulk_accumulation
    reference_component_storage_rate_name = constant_bulk_storage_rate
  []
[]

[Postprocessors]
  [jacobian]
    type = ADElementAverageMaterialProperty
    mat_prop = solid_reference_J
    execute_on = TIMESTEP_END
  []
  [ideal_gas_density]
    type = ADElementAverageMaterialProperty
    mat_prop = ideal_gas_density
    execute_on = TIMESTEP_END
  []
  [ideal_gas_accumulation]
    type = ADElementAverageMaterialProperty
    mat_prop = ideal_gas_accumulation
    execute_on = TIMESTEP_END
  []
  [ideal_gas_storage_rate]
    type = ADElementAverageMaterialProperty
    mat_prop = ideal_gas_storage_rate
    execute_on = TIMESTEP_END
  []
  [constant_bulk_density]
    type = ADElementAverageMaterialProperty
    mat_prop = constant_bulk_density
    execute_on = TIMESTEP_END
  []
  [constant_bulk_accumulation]
    type = ADElementAverageMaterialProperty
    mat_prop = constant_bulk_accumulation
    execute_on = TIMESTEP_END
  []
  [constant_bulk_storage_rate]
    type = ADElementAverageMaterialProperty
    mat_prop = constant_bulk_storage_rate
    execute_on = TIMESTEP_END
  []
[]

[Problem]
  solve = false
[]

[Executioner]
  type = Transient
  start_time = 0
  end_time = 1
  dt = 1
[]

[Outputs]
  console = true
  csv = true
  execute_on = TIMESTEP_END
[]
