mesh_nx := 4

!include ../../../input/includes/mesh/generated_1d_q2.i
!include ../../../input/includes/fields/solid_q2_aux_1d.i
!include ../../../input/includes/fields/eg_equivalent_pressure_aux.i

[AuxVariables]
  [phi_state]
    family = LAGRANGE
    order = SECOND
  []
[]

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
  [phi_exact]
    type = ParsedFunction
    expression = '0.23+0.019*x'
  []
  [biot_exact]
    type = ParsedFunction
    expression = '0.72-0.029*x'
  []
  [density_exact]
    type = ParsedFunction
    expression = '1/((1+0.2*x)*(0.23+0.019*x))'
  []
  [partial_total_gap_exact]
    type = ParsedFunction
    expression = '0.045+0.009*x'
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
  [phi_ic]
    type = FunctionIC
    variable = phi_state
    function = phi_exact
  []
[]

!include ../../../input/includes/materials/solid_kinematics_1d.i
!include ../../../input/includes/materials/eg_equivalent_pressure_reconstruction.i

[Materials]
  [solid_component_reference_accumulation_0]
    type = ADGenericConstantMaterial
    prop_names = 'solid_component_reference_accumulation_0'
    prop_values = '1'
  []
  [solid_volume_fraction]
    type = ADDerivativeParsedMaterial
    coupled_variables = 'phi_state'
    material_property_names = 'solid_reference_J'
    property_name = solid_volume_fraction
    expression = 'phi_state+0*solid_reference_J'
    additional_derivative_symbols = 'solid_reference_J'
    derivative_order = 2
    enable_jit = true
  []
  [solid_grain_specific_volume_eos]
    type = ADDerivativeParsedMaterial
    material_property_names = 'solid_reference_J equivalent_pressure_total'
    property_name = solid_grain_specific_volume_eos
    constant_names = 'q a d'
    constant_expressions = '0.2 0.05 0.03'
    expression = 'solid_reference_J*(q+a*(solid_reference_J-1)+d*equivalent_pressure_total)'
    additional_derivative_symbols = 'solid_reference_J'
    derivative_order = 2
    enable_jit = true
  []
  [solid_volume_constraint]
    type = ADDerivativeParsedMaterial
    coupled_variables = 'phi_state'
    material_property_names = 'solid_reference_J equivalent_pressure_total solid_component_reference_accumulation_0'
    property_name = solid_volume_constraint
    constant_names = 'q a d'
    constant_expressions = '0.2 0.05 0.03'
    expression = 'solid_reference_J*phi_state-solid_component_reference_accumulation_0*solid_reference_J*(q+a*(solid_reference_J-1)+d*equivalent_pressure_total)'
    additional_derivative_symbols = 'solid_reference_J'
    derivative_order = 2
    enable_jit = true
  []
  [solid_biot]
    type = ADConstrainedSkeletonBiotMaterial
    constraint_residual_names = 'solid_volume_constraint'
    implicit_state_symbols = 'phi_state'
    aggregate_solid_volume_fraction_name = solid_volume_fraction
    skeleton_component_reference_accumulation_names = 'solid_component_reference_accumulation_0'
    reference_specific_volume = 1
  []
  [biot_fd]
    type = ADParsedMaterial
    material_property_names = 'solid_reference_J equivalent_pressure_total'
    property_name = solid_biot_fixed_pressure_fd
    constant_names = 'q a d h'
    constant_expressions = '0.2 0.05 0.03 1e-6'
    expression = '1-(((solid_reference_J+h)*(q+a*((solid_reference_J+h)-1)+d*equivalent_pressure_total)-(solid_reference_J-h)*(q+a*((solid_reference_J-h)-1)+d*equivalent_pressure_total))/(2*h))'
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
    constant_names = 'q a d dpdJ'
    constant_expressions = '0.2 0.05 0.03 1.5'
    expression = '1-(q+a*(solid_reference_J-1)+d*equivalent_pressure_total+solid_reference_J*(a+d*dpdJ))'
  []
  [biot_minus_total_path]
    type = ADParsedMaterial
    material_property_names = 'solid_biot_coefficient solid_biot_total_path'
    property_name = solid_biot_minus_total_path
    expression = 'solid_biot_coefficient-solid_biot_total_path'
  []
  [reference_accumulation_consistency]
    type = ADParsedMaterial
    material_property_names = 'solid_intrinsic_specific_volume solid_reference_J solid_volume_fraction solid_component_reference_accumulation_0'
    property_name = constrained_reference_accumulation_consistency_residual
    expression = 'solid_intrinsic_specific_volume-solid_reference_J*solid_volume_fraction/solid_component_reference_accumulation_0'
  []
  [intrinsic_density_specific_volume_inverse_consistency]
    type = ADParsedMaterial
    material_property_names = 'solid_intrinsic_skeleton_density solid_intrinsic_specific_volume'
    property_name = intrinsic_density_specific_volume_inverse_consistency_residual
    expression = 'solid_intrinsic_skeleton_density*solid_intrinsic_specific_volume-1'
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
  [constraint_l2]
    type = ADMaterialScalarL2Error
    property = solid_biot_constraint_norm
    function = zero
    execute_on = INITIAL
  []
  [reference_accumulation_consistency_l2]
    type = ADMaterialScalarL2Error
    property = constrained_reference_accumulation_consistency_residual
    function = zero
    execute_on = INITIAL
  []
  [intrinsic_density_specific_volume_inverse_consistency_l2]
    type = ADMaterialScalarL2Error
    property = intrinsic_density_specific_volume_inverse_consistency_residual
    function = zero
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
