[Mesh]
  type = GeneratedMesh
  dim = 1
  nx = 2
[]

[Variables]
  [reference_storage]
  []
[]

[AuxVariables]
  [solid_fraction]
  []
  [fluid_fraction]
  []
[]

[Functions]
  [zero]
    type = ParsedFunction
    expression = '0'
  []
  [reference_storage_exact]
    type = ParsedFunction
    expression = '1.4'
  []
  [solid_fraction_exact]
    type = ParsedFunction
    expression = '0.35'
  []
  [fluid_fraction_exact]
    type = ParsedFunction
    expression = '0.65'
  []
[]

[ICs]
  [reference_storage_ic]
    type = FunctionIC
    variable = reference_storage
    function = reference_storage_exact
  []
  [solid_fraction_ic]
    type = FunctionIC
    variable = solid_fraction
    function = solid_fraction_exact
  []
  [fluid_fraction_ic]
    type = FunctionIC
    variable = fluid_fraction
    function = fluid_fraction_exact
  []
[]

[Materials]
  [kinematic_constants]
    type = ADGenericConstantMaterial
    prop_names = 'solid_reference_J solid_reference_J_dot'
    prop_values = '2 0'
  []
  [reference_primary]
    type = ADSolidPhaseMassVolumeMaterial
    reference_component_storage = reference_storage
    solid_intrinsic_density = 2
    reference_component_storage_name = reference_primary_storage
    reference_component_storage_rate_name = reference_primary_storage_rate
    reference_component_balance_residual_name = reference_primary_balance_residual
    phase_volume_constraint_residual_name = reference_primary_volume_residual
    current_solid_volume_fraction_name = reference_primary_solid_fraction
    current_fluid_volume_fraction_name = reference_primary_porosity
    current_fluid_volume_fraction_rate_name = reference_primary_porosity_rate
  []
  [spatial_primary]
    type = ADSolidPhaseMassVolumeMaterial
    solid_volume_fraction = solid_fraction
    fluid_volume_fraction = fluid_fraction
    solid_intrinsic_density = 2
    reference_component_storage_name = spatial_primary_storage
    reference_component_storage_rate_name = spatial_primary_storage_rate
    reference_component_balance_residual_name = spatial_primary_balance_residual
    phase_volume_constraint_residual_name = spatial_primary_volume_residual
    current_solid_volume_fraction_name = spatial_primary_solid_fraction
    current_fluid_volume_fraction_name = spatial_primary_porosity
    current_fluid_volume_fraction_rate_name = spatial_primary_porosity_rate
  []
[]

[Kernels]
  [reference_storage_time]
    type = TimeDerivative
    variable = reference_storage
  []
[]

[Postprocessors]
  [reference_storage_l2]
    type = ADMaterialScalarL2Error
    property = reference_primary_storage
    function = reference_storage_exact
    execute_on = INITIAL
  []
  [reference_solid_fraction_l2]
    type = ADMaterialScalarL2Error
    property = reference_primary_solid_fraction
    function = solid_fraction_exact
    execute_on = INITIAL
  []
  [reference_porosity_l2]
    type = ADMaterialScalarL2Error
    property = reference_primary_porosity
    function = fluid_fraction_exact
    execute_on = INITIAL
  []
  [reference_balance_l2]
    type = ADMaterialScalarL2Error
    property = reference_primary_balance_residual
    function = zero
    execute_on = INITIAL
  []
  [reference_volume_l2]
    type = ADMaterialScalarL2Error
    property = reference_primary_volume_residual
    function = zero
    execute_on = INITIAL
  []
  [spatial_storage_l2]
    type = ADMaterialScalarL2Error
    property = spatial_primary_storage
    function = reference_storage_exact
    execute_on = INITIAL
  []
  [spatial_solid_fraction_l2]
    type = ADMaterialScalarL2Error
    property = spatial_primary_solid_fraction
    function = solid_fraction_exact
    execute_on = INITIAL
  []
  [spatial_porosity_l2]
    type = ADMaterialScalarL2Error
    property = spatial_primary_porosity
    function = fluid_fraction_exact
    execute_on = INITIAL
  []
  [spatial_balance_l2]
    type = ADMaterialScalarL2Error
    property = spatial_primary_balance_residual
    function = zero
    execute_on = INITIAL
  []
  [spatial_volume_l2]
    type = ADMaterialScalarL2Error
    property = spatial_primary_volume_residual
    function = zero
    execute_on = INITIAL
  []
[]

[Executioner]
  type = Transient
  dt = 1
  num_steps = 0
[]

[Outputs]
  csv = true
  execute_on = INITIAL
[]
