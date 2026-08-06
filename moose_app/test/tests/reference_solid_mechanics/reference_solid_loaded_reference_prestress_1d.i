mesh_nx := 4

!include ../../../input/includes/mesh/generated_1d_q2.i
!include ../../../input/includes/fields/solid_q2_1d.i
!include ../../../input/includes/fields/eg_equivalent_pressure_aux.i

[Functions]
  [initial_pressure]
    type = ParsedFunction
    expression = '2+x'
  []
  [zero]
    type = ParsedFunction
    expression = '0'
  []
[]

[ICs]
  [pressure_ic]
    type = FunctionIC
    variable = equivalent_pressure
    function = initial_pressure
  []
  [pressure_enrichment_ic]
    type = ConstantIC
    variable = equivalent_pressure_enr
    value = 0
  []
[]

!include ../../../input/includes/materials/solid_kinematics_1d.i
!include ../../../input/includes/materials/eg_equivalent_pressure_reconstruction.i

[Materials]
  [effective_stress]
    type = ADCompressibleNeoHookeanReferenceStressMaterial
    shear_modulus = 3
    lame_lambda = 5
  []
  [loaded_reference_prestress]
    type = ADGenericFunctionRankTwoTensor
    tensor_functions = 'initial_pressure zero zero zero initial_pressure zero zero zero initial_pressure'
    tensor_name = loaded_reference_prestress
  []
  [total_stress]
    type = ADReferenceSolidStressMaterial
    equivalent_pressure_total_name = equivalent_pressure_total
    biot_coefficient = 1
    reference_prestress_name = loaded_reference_prestress
  []
[]

[Kernels]
  [solid_x]
    type = ADReferenceSolidMomentum
    variable = ux
    component = 0
  []
[]

[BCs]
  [left_pin]
    type = DirichletBC
    variable = ux
    boundary = left
    value = 0
  []
[]

[Postprocessors]
  [ux_l2]
    type = ElementL2Norm
    variable = ux
  []
  [total_stress_xx_l2]
    type = ADMaterialRankTwoComponentL2Error
    property = reference_solid_total_first_piola
    row = 0
    column = 0
    function = zero
  []
[]

!include ../../../input/includes/executioner/steady_newton.i
!include ../../../input/includes/outputs/csv.i
