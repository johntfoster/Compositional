[Mesh]
  coord_type = RZ
  [annulus]
    type = GeneratedMeshGenerator
    dim = 2
    nx = 1
    ny = 1
    xmin = 1
    xmax = 2
    ymin = 0
    ymax = 1
    elem_type = QUAD8
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
    expression = '0.1*t*x'
  []
  [exact_uz]
    type = ParsedFunction
    expression = '-0.05*t*y'
  []
  [exact_jacobian]
    type = ParsedFunction
    expression = '(1+0.1*t)^2*(1-0.05*t)'
  []
  [exact_jacobian_rate]
    type = ParsedFunction
    expression = '2*0.1*(1+0.1*t)*(1-0.05*t)-0.05*(1+0.1*t)^2'
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
[]

[Kernels]
  [ur_reaction]
    type = ADReaction
    variable = ur
  []
  [uz_reaction]
    type = ADReaction
    variable = uz
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
  [J_l2]
    type = ADMaterialScalarL2Error
    property = solid_reference_J
    function = exact_jacobian
  []
  [J_dot_l2]
    type = ADMaterialScalarL2Error
    property = solid_reference_J_dot
    function = exact_jacobian_rate
  []
[]

[Executioner]
  type = Transient
  solve_type = NEWTON
  dt = 0.5
  end_time = 1
  nl_rel_tol = 1e-12
  nl_abs_tol = 1e-13
[]

[Outputs]
  csv = true
[]
