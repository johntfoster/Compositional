[Mesh]
  coord_type = RZ
  [annulus]
    type = GeneratedMeshGenerator
    dim = 2
    nx = 2
    ny = 2
    xmin = 1
    xmax = 2
    ymin = 0
    ymax = 1
    elem_type = QUAD9
  []
[]

[Variables]
  [ur]
    family = LAGRANGE
    order = SECOND
  []
  [uz]
    family = LAGRANGE
    order = SECOND
  []
[]

[Functions]
  [exact_ur]
    type = ParsedFunction
    expression = '0.1*x'
  []
  [exact_uz]
    type = ParsedFunction
    expression = '-0.05*y'
  []
[]

[ICs]
  [ur]
    type = FunctionIC
    variable = ur
    function = exact_ur
  []
  [uz]
    type = FunctionIC
    variable = uz
    function = exact_uz
  []
[]

[Materials]
  [axisymmetric_reference_kinematics]
    type = ADAxisymmetricSolidReferenceKinematics
    radial_displacement = ur
    axial_displacement = uz
  []
  [effective_stress]
    type = ADCompressibleNeoHookeanReferenceStressMaterial
    shear_modulus = 4
    lame_lambda = 6
  []
  [total_stress]
    type = ADReferenceSolidStressMaterial
    biot_coefficient = 0
  []
[]

[Kernels]
  [radial_momentum]
    type = ADAxisymmetricReferenceSolidMomentum
    variable = ur
    component = 0
  []
  [axial_momentum]
    type = ADAxisymmetricReferenceSolidMomentum
    variable = uz
    component = 1
  []
[]

[BCs]
  [ur]
    type = FunctionDirichletBC
    variable = ur
    boundary = 'left right bottom top'
    function = exact_ur
  []
  [uz]
    type = FunctionDirichletBC
    variable = uz
    boundary = 'left right bottom top'
    function = exact_uz
  []
[]

[Postprocessors]
  [ur_l2]
    type = ElementL2Error
    variable = ur
    function = exact_ur
  []
  [uz_l2]
    type = ElementL2Error
    variable = uz
    function = exact_uz
  []
[]

[Executioner]
  type = Steady
  solve_type = NEWTON
  petsc_options_iname = '-pc_type -pc_factor_mat_solver_type'
  petsc_options_value = 'lu superlu_dist'
  nl_rel_tol = 1e-12
  nl_abs_tol = 1e-13
[]

[Outputs]
  csv = true
[]
