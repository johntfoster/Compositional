mesh_nx := 1
strain_amp := 1e-2
drained_to_grain_bulk_ratio := 0.4
finite_deformation_curvature := 0.12
fluid_pore_volume_fraction := 0.2
grain_bulk_modulus := 10
fluid_bulk_modulus := 7
solid_shear_modulus := 3
solid_lame_lambda := 5
pressure_value := 0.75

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
    expression = '${strain_amp}*x'
  []
  [pressure_exact]
    type = ParsedFunction
    expression = '${pressure_value}'
  []
  [phi_exact]
    type = ParsedFunction
    expression = '(1+${drained_to_grain_bulk_ratio}*((1+${strain_amp})-1)+${finite_deformation_curvature}*((1+${strain_amp})-1)^2)/(1+${strain_amp})'
  []
  [biot_finite_exact]
    type = ParsedFunction
    expression = '1-(${drained_to_grain_bulk_ratio}+2*${finite_deformation_curvature}*((1+${strain_amp})-1))'
  []
  [biot_small_strain_exact]
    type = ParsedFunction
    expression = '1-${drained_to_grain_bulk_ratio}'
  []
  [density_exact]
    type = ParsedFunction
    expression = '1/(1+${drained_to_grain_bulk_ratio}*${strain_amp}+${finite_deformation_curvature}*${strain_amp}^2)'
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
  [solid_volume_constraint]
    type = ADDerivativeParsedMaterial
    coupled_variables = 'phi_state'
    material_property_names = 'solid_reference_J equivalent_pressure_total solid_component_reference_accumulation_0'
    property_name = solid_volume_constraint
    constant_names = 'ratio curve'
    constant_expressions = '${drained_to_grain_bulk_ratio} ${finite_deformation_curvature}'
    expression = 'solid_reference_J*phi_state-solid_component_reference_accumulation_0*(1+ratio*(solid_reference_J-1)+curve*(solid_reference_J-1)^2+0*equivalent_pressure_total)'
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
  [effective_stress]
    type = ADCompressibleNeoHookeanReferenceStressMaterial
    shear_modulus = ${solid_shear_modulus}
    lame_lambda = ${solid_lame_lambda}
  []
  [total_stress]
    type = ADReferenceSolidStressMaterial
    equivalent_pressure = equivalent_pressure
    equivalent_pressure_enrichment = equivalent_pressure_enr
    biot_coefficient_name = solid_biot_coefficient
  []
  [biot_fd]
    type = ADParsedMaterial
    material_property_names = 'solid_reference_J'
    property_name = solid_biot_fixed_pressure_fd
    constant_names = 'ratio curve h'
    constant_expressions = '${drained_to_grain_bulk_ratio} ${finite_deformation_curvature} 1e-6'
    expression = '1-(((1+ratio*((solid_reference_J+h)-1)+curve*((solid_reference_J+h)-1)^2)-(1+ratio*((solid_reference_J-h)-1)+curve*((solid_reference_J-h)-1)^2))/(2*h))'
  []
  [biot_minus_fd]
    type = ADParsedMaterial
    material_property_names = 'solid_biot_coefficient solid_biot_fixed_pressure_fd'
    property_name = solid_biot_minus_fd
    expression = 'solid_biot_coefficient-solid_biot_fixed_pressure_fd'
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
  [biot_storage_inverse]
    type = ADParsedMaterial
    material_property_names = 'solid_biot_coefficient'
    property_name = biot_storage_inverse
    constant_names = 'phi_f grain_bulk fluid_bulk'
    constant_expressions = '${fluid_pore_volume_fraction} ${grain_bulk_modulus} ${fluid_bulk_modulus}'
    expression = '(solid_biot_coefficient-phi_f)/grain_bulk+phi_f/fluid_bulk'
  []
  [biot_storage_identity_residual]
    type = ADParsedMaterial
    material_property_names = 'solid_biot_coefficient biot_storage_inverse'
    property_name = biot_storage_identity_residual
    constant_names = 'phi_f grain_bulk fluid_bulk'
    constant_expressions = '${fluid_pore_volume_fraction} ${grain_bulk_modulus} ${fluid_bulk_modulus}'
    expression = 'biot_storage_inverse-((solid_biot_coefficient-phi_f)/grain_bulk+phi_f/fluid_bulk)'
  []
  [biot_storage_inverse_minus_small_strain]
    type = ADParsedMaterial
    material_property_names = 'biot_storage_inverse'
    property_name = biot_storage_inverse_minus_small_strain
    constant_names = 'ratio phi_f grain_bulk fluid_bulk'
    constant_expressions = '${drained_to_grain_bulk_ratio} ${fluid_pore_volume_fraction} ${grain_bulk_modulus} ${fluid_bulk_modulus}'
    expression = 'biot_storage_inverse-((1-ratio-phi_f)/grain_bulk+phi_f/fluid_bulk)'
  []
  [undrained_storage_residual]
    type = ADParsedMaterial
    material_property_names = 'solid_biot_coefficient biot_storage_inverse'
    property_name = undrained_storage_residual
    constant_names = 'vol_rate'
    constant_expressions = '1'
    expression = 'biot_storage_inverse*(-solid_biot_coefficient*vol_rate/biot_storage_inverse)+solid_biot_coefficient*vol_rate'
  []
  [undrained_response_minus_small_strain]
    type = ADParsedMaterial
    material_property_names = 'solid_biot_coefficient biot_storage_inverse'
    property_name = undrained_response_minus_small_strain
    constant_names = 'ratio phi_f grain_bulk fluid_bulk'
    constant_expressions = '${drained_to_grain_bulk_ratio} ${fluid_pore_volume_fraction} ${grain_bulk_modulus} ${fluid_bulk_modulus}'
    expression = '(-solid_biot_coefficient/biot_storage_inverse)-(-(1-ratio)/((1-ratio-phi_f)/grain_bulk+phi_f/fluid_bulk))'
  []
[]

[Postprocessors]
  [biot_l2]
    type = ADMaterialScalarL2Error
    property = solid_biot_coefficient
    function = biot_finite_exact
    execute_on = INITIAL
  []
  [biot_small_strain_l2]
    type = ADMaterialScalarL2Error
    property = solid_biot_coefficient
    function = biot_small_strain_exact
    execute_on = INITIAL
  []
  [biot_fd_l2]
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
  [storage_identity_l2]
    type = ADMaterialScalarL2Error
    property = biot_storage_identity_residual
    function = zero
    execute_on = INITIAL
  []
  [storage_inverse_small_strain_l2]
    type = ADMaterialScalarL2Error
    property = biot_storage_inverse_minus_small_strain
    function = zero
    execute_on = INITIAL
  []
  [undrained_storage_l2]
    type = ADMaterialScalarL2Error
    property = undrained_storage_residual
    function = zero
    execute_on = INITIAL
  []
  [undrained_response_small_strain_l2]
    type = ADMaterialScalarL2Error
    property = undrained_response_minus_small_strain
    function = zero
    execute_on = INITIAL
  []
  [biot_average]
    type = ADElementAverageMaterialProperty
    mat_prop = solid_biot_coefficient
    execute_on = INITIAL
  []
  [biot_min]
    type = ADElementExtremeMaterialProperty
    mat_prop = solid_biot_coefficient
    value_type = min
    execute_on = INITIAL
  []
  [biot_max]
    type = ADElementExtremeMaterialProperty
    mat_prop = solid_biot_coefficient
    value_type = max
    execute_on = INITIAL
  []
  [total_piola_xx]
    type = ADMaterialTensorAverage
    rank_two_tensor = reference_solid_total_first_piola
    index_i = 0
    index_j = 0
    use_displaced_mesh = false
    execute_on = INITIAL
  []
[]

!include ../../../input/includes/executioner/steady_material.i
!include ../../../input/includes/outputs/csv.i
