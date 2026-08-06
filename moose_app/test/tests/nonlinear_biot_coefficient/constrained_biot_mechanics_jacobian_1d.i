mesh_nx := 2

!include ../../../input/includes/mesh/generated_1d_q2.i
!include ../../../input/includes/fields/solid_q2_1d.i
!include ../../../input/includes/fields/eg_pressure.i

[Variables]
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
  [ux_initial]
    type = ParsedFunction
    expression = '0.02*x*(1-x)'
  []
  [pressure_initial]
    type = ParsedFunction
    expression = '0.25+0.03*x'
  []
  [phi_initial]
    type = ParsedFunction
    expression = '0.24+0.01*x'
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
  [phi_ic]
    type = FunctionIC
    variable = phi_state
    function = phi_initial
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
    material_property_names = 'solid_reference_J p_total solid_component_reference_accumulation_0'
    property_name = solid_volume_constraint
    constant_names = 'q a c d'
    constant_expressions = '0.2 0.05 0.04 0.09'
    expression = 'solid_reference_J*phi_state-solid_component_reference_accumulation_0*solid_reference_J*(q+a*(solid_reference_J-1)+c*p_total+d*solid_reference_J*p_total)'
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
  [solid_volume_constraint]
    type = ADMaterialPropertyResidual
    variable = phi_state
    property = solid_volume_constraint
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
