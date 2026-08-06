mesh_nx := 2

!include ../../../input/includes/mesh/generated_1d_q2.i
!include ../../../input/includes/fields/solid_q2_aux_1d.i
!include ../../../input/includes/fields/eg_equivalent_pressure_aux.i

[Functions]
  [ux_exact]
    type = ParsedFunction
    expression = '0.001*x'
  []
  [pressure_exact]
    type = ParsedFunction
    expression = '1+0.1*x'
  []
  [biot_exact]
    type = ParsedFunction
    expression = '0.6'
  []
[]

[ICs]
  [ux_ic]
    type = FunctionIC
    variable = ux
    function = ux_exact
  []
  [pressure_ic]
    type = FunctionIC
    variable = equivalent_pressure
    function = pressure_exact
  []
  [pressure_enr_ic]
    type = ConstantIC
    variable = equivalent_pressure_enr
    value = 0
  []
[]

!include ../../../input/includes/materials/solid_kinematics_1d.i
!include ../../../input/includes/materials/eg_equivalent_pressure_reconstruction.i

[Materials]
  [small_strain_specific_volume]
    type = ADDerivativeParsedMaterial
    material_property_names = 'solid_reference_J equivalent_pressure_total'
    property_name = solid_intrinsic_specific_volume
    constant_names = 'v0 K Ks'
    constant_expressions = '2 2 5'
    expression = 'v0*(1+(K/Ks)*(solid_reference_J-1)+0.03*equivalent_pressure_total)'
    additional_derivative_symbols = 'solid_reference_J'
    derivative_order = 2
    enable_jit = true
  []
  [solid_biot]
    type = ADSkeletonSpecificVolumeBiotMaterial
    intrinsic_specific_volume_name = solid_intrinsic_specific_volume
    reference_specific_volume = 2
  []
[]

[Postprocessors]
  [biot_l2]
    type = ADMaterialScalarL2Error
    property = solid_biot_coefficient
    function = biot_exact
    execute_on = INITIAL
  []
[]

!include ../../../input/includes/executioner/steady_material.i
!include ../../../input/includes/outputs/csv.i
