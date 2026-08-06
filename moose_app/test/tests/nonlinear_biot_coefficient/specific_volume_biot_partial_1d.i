mesh_nx := 4

!include ../../../input/includes/mesh/generated_1d_q2.i
!include ../../../input/includes/fields/solid_q2_aux_1d.i
!include ../../../input/includes/fields/eg_equivalent_pressure_aux.i

[Functions]
  [zero]
    type = ParsedFunction
    expression = '0'
  []
  [ux_exact]
    type = ParsedFunction
    expression = '0.1*x*x'
  []
  [pressure_exact]
    type = ParsedFunction
    expression = '1+0.3*x'
  []
  [biot_exact]
    type = ParsedFunction
    expression = '0.73-0.021*x'
  []
  [density_exact]
    type = ParsedFunction
    expression = '1/(2*(1+0.2*(0.2*x)+0.05*(1+0.3*x)+0.07*(1+0.2*x)*(1+0.3*x)))'
  []
  [partial_total_gap_exact]
    type = ParsedFunction
    expression = '0.18+0.021*x'
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
  [solid_specific_volume]
    type = ADDerivativeParsedMaterial
    material_property_names = 'solid_reference_J equivalent_pressure_total'
    property_name = solid_intrinsic_specific_volume
    constant_names = 'v0 a c d'
    constant_expressions = '2 0.2 0.05 0.07'
    expression = 'v0*(1+a*(solid_reference_J-1)+c*equivalent_pressure_total+d*solid_reference_J*equivalent_pressure_total)'
    additional_derivative_symbols = 'solid_reference_J'
    derivative_order = 2
    enable_jit = true
  []
  [solid_biot]
    type = ADSkeletonSpecificVolumeBiotMaterial
    intrinsic_specific_volume_name = solid_intrinsic_specific_volume
    reference_specific_volume = 2
  []
  [biot_fd]
    type = ADParsedMaterial
    material_property_names = 'solid_reference_J equivalent_pressure_total'
    property_name = solid_biot_fixed_pressure_fd
    constant_names = 'v0 a c d h'
    constant_expressions = '2 0.2 0.05 0.07 1e-6'
    expression = '1-((v0*(1+a*((solid_reference_J+h)-1)+c*equivalent_pressure_total+d*(solid_reference_J+h)*equivalent_pressure_total)-v0*(1+a*((solid_reference_J-h)-1)+c*equivalent_pressure_total+d*(solid_reference_J-h)*equivalent_pressure_total))/(2*h))/v0'
  []
  [biot_minus_fd]
    type = ADParsedMaterial
    material_property_names = 'solid_biot_coefficient solid_biot_fixed_pressure_fd'
    property_name = solid_biot_minus_fd
    expression = 'solid_biot_coefficient-solid_biot_fixed_pressure_fd'
  []
  [biot_total_path]
    type = ADParsedMaterial
    material_property_names = 'solid_reference_J equivalent_pressure_total'
    property_name = solid_biot_total_path
    constant_names = 'a c d dpdJ'
    constant_expressions = '0.2 0.05 0.07 1.5'
    expression = '1-(a+d*equivalent_pressure_total+(c+d*solid_reference_J)*dpdJ)'
  []
  [biot_minus_total_path]
    type = ADParsedMaterial
    material_property_names = 'solid_biot_coefficient solid_biot_total_path'
    property_name = solid_biot_minus_total_path
    expression = 'solid_biot_coefficient-solid_biot_total_path'
  []
[]

[Postprocessors]
  [biot_l2]
    type = ADMaterialScalarL2Error
    property = solid_biot_coefficient
    function = biot_exact
    execute_on = INITIAL
  []
  [fd_l2]
    type = ADMaterialScalarL2Error
    property = solid_biot_minus_fd
    function = zero
    execute_on = INITIAL
  []
  [density_l2]
    type = ADMaterialScalarL2Error
    property = solid_intrinsic_skeleton_density
    function = density_exact
    execute_on = INITIAL
  []
  [partial_total_gap_l2]
    type = ADMaterialScalarL2Error
    property = solid_biot_minus_total_path
    function = partial_total_gap_exact
    execute_on = INITIAL
  []
[]

!include ../../../input/includes/executioner/steady_material.i
!include ../../../input/includes/outputs/csv.i
