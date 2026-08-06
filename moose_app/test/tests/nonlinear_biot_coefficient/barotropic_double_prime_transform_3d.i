mesh_nx := 1
mesh_ny := 1
mesh_nz := 1
stretch := 1.05
pressure := 2.0

!include ../../../input/includes/mesh/generated_3d_q2.i
!include ../../../input/includes/fields/solid_q2_aux_3d.i

[AuxVariables]
  [p]
    family = LAGRANGE
    order = FIRST
  []
  [p_enr]
    family = MONOMIAL
    order = CONSTANT
  []
[]

[Functions]
  [ux_exact]
    type = ParsedFunction
    expression = '(${stretch}-1)*x'
  []
  [uy_exact]
    type = ParsedFunction
    expression = '(${stretch}-1)*y'
  []
  [uz_exact]
    type = ParsedFunction
    expression = '(${stretch}-1)*z'
  []
[]

[ICs]
  [ux_ic]
    type = FunctionIC
    variable = ux
    function = ux_exact
  []
  [uy_ic]
    type = FunctionIC
    variable = uy
    function = uy_exact
  []
  [uz_ic]
    type = FunctionIC
    variable = uz
    function = uz_exact
  []
  [p_ic]
    type = ConstantIC
    variable = p
    value = ${pressure}
  []
  [p_enr_ic]
    type = ConstantIC
    variable = p_enr
    value = 0
  []
[]

!include ../../../input/includes/materials/solid_kinematics_3d.i

[Materials]
  [double_prime_stress]
    type = ADHydrostaticBarotropicSkeletonStressMaterial
    equivalent_pressure = p
    equivalent_pressure_enrichment = p_enr
    shear_modulus = 3
    lame_lambda = 5
    mineral_bulk_modulus = 20
    reference_solid_volume_fraction = 0.8
  []
  [biot_transform]
    type = ADReferenceSolidStressMaterial
    equivalent_pressure = p
    equivalent_pressure_enrichment = p_enr
    biot_coefficient = 0.65
  []
[]

[Postprocessors]
  [jacobian]
    type = ADElementAverageMaterialProperty
    mat_prop = solid_reference_J
    execute_on = INITIAL
  []
  [mineral_effective_pressure]
    type = ADElementAverageMaterialProperty
    mat_prop = solid_mineral_effective_pressure
    execute_on = INITIAL
  []
  [mineral_effective_pressure_jacobian_derivative]
    type = ADElementAverageMaterialProperty
    mat_prop = solid_mineral_effective_pressure_jacobian_derivative
    execute_on = INITIAL
  []
  [double_prime_xx]
    type = ADMaterialTensorAverage
    rank_two_tensor = solid_effective_first_piola
    index_i = 0
    index_j = 0
    use_displaced_mesh = false
    execute_on = INITIAL
  []
  [prime_xx]
    type = ADMaterialTensorAverage
    rank_two_tensor = solid_prime_first_piola
    index_i = 0
    index_j = 0
    use_displaced_mesh = false
    execute_on = INITIAL
  []
  [total_xx]
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
