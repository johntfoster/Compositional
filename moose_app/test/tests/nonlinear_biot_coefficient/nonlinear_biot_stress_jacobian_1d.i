mesh_nx := 2

!include ../../../input/includes/mesh/generated_1d_q2.i
!include ../../../input/includes/fields/solid_q2_1d.i
!include ../../../input/includes/fields/eg_pressure.i

[Functions]
  [zero]
    type = ParsedFunction
    expression = '0'
  []
  [ux_initial]
    type = ParsedFunction
    expression = '0.02*x*(1-x)'
  []
  [pressure_initial]
    type = ParsedFunction
    expression = '0.25'
  []
[]

[ICs]
  [ux_ic]
    type = FunctionIC
    variable = ux
    function = ux_initial
  []
  [p_ic]
    type = FunctionIC
    variable = p
    function = pressure_initial
  []
[]

!include ../../../input/includes/materials/solid_kinematics_1d.i
!include ../../../input/includes/materials/eg_pressure_reconstruction.i

[Materials]
  [effective_stress]
    type = ADCompressibleNeoHookeanReferenceStressMaterial
    shear_modulus = 0.3
    lame_lambda = 0.5
  []
  [solid_specific_volume]
    type = ADDerivativeParsedMaterial
    material_property_names = 'solid_reference_J p_total'
    property_name = solid_intrinsic_specific_volume
    constant_names = 'v0 a c d'
    constant_expressions = '2 0.17 0.04 0.09'
    expression = 'v0*(1+a*(solid_reference_J-1)+c*p_total+d*solid_reference_J*p_total)'
    additional_derivative_symbols = 'solid_reference_J'
    derivative_order = 2
    enable_jit = true
  []
  [solid_biot]
    type = ADSkeletonSpecificVolumeBiotMaterial
    intrinsic_specific_volume_name = solid_intrinsic_specific_volume
    jacobian_symbol = solid_reference_J
    fixed_pressure_symbol = p_total
    reference_specific_volume = 2
  []
  [total_stress]
    type = ADReferenceSolidStressMaterial
    equivalent_pressure = p
    equivalent_pressure_enrichment = p_enr
    biot_coefficient_name = solid_biot_coefficient
  []
  [p_constraint]
    type = ADParsedMaterial
    material_property_names = 'p_total'
    property_name = p_constraint_residual
    constant_names = 'p_ref'
    constant_expressions = '0.25'
    expression = 'p_total-p_ref'
  []
[]

[Kernels]
  [solid_x]
    type = ADReferenceSolidMomentum
    variable = ux
    component = 0
  []
  [p_backbone]
    type = ADEnrichedGalerkinMaterialPropertyResidual
    variable = p
    property = p_constraint_residual
  []
  [p_enrichment]
    type = ADEnrichedGalerkinMaterialPropertyResidual
    variable = p_enr
    property = p_constraint_residual
    anchor_coefficient = 1
    anchor_value = 0
  []
[]

[BCs]
  [ux_bc]
    type = FunctionDirichletBC
    variable = ux
    boundary = 'left right'
    function = zero
  []
[]

[Executioner]
  type = Steady
  solve_type = NEWTON
  nl_abs_tol = 1e-12
[]

[Outputs]
  console = false
[]
