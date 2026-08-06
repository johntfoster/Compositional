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

[Problem]
  solve = false
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
  [radial_displacement]
    type = ParsedFunction
    expression = '0.1*x'
  []
  [axial_displacement]
    type = ParsedFunction
    expression = '-0.1*y'
  []
  [lambda_r]
    type = ParsedFunction
    expression = '1.1'
  []
  [lambda_z]
    type = ParsedFunction
    expression = '0.9'
  []
  [jacobian]
    type = ParsedFunction
    expression = '1.089'
  []
  [inverse_lambda_r]
    type = ParsedFunction
    expression = '1/1.1'
  []
  [inverse_lambda_z]
    type = ParsedFunction
    expression = '1/0.9'
  []
  [zero]
    type = ParsedFunction
    expression = '0'
  []
[]

[ICs]
  [ur]
    type = FunctionIC
    variable = ur
    function = radial_displacement
  []
  [uz]
    type = FunctionIC
    variable = uz
    function = axial_displacement
  []
[]

[Materials]
  [axisymmetric_reference_kinematics]
    type = ADAxisymmetricSolidReferenceKinematics
    radial_displacement = ur
    axial_displacement = uz
  []
[]

[Postprocessors]
  [F_rr_l2]
    type = ADMaterialRankTwoComponentL2Error
    property = solid_reference_F
    row = 0
    column = 0
    function = lambda_r
  []
  [F_zz_l2]
    type = ADMaterialRankTwoComponentL2Error
    property = solid_reference_F
    row = 1
    column = 1
    function = lambda_z
  []
  [F_tt_l2]
    type = ADMaterialRankTwoComponentL2Error
    property = solid_reference_F
    row = 2
    column = 2
    function = lambda_r
  []
  [J_l2]
    type = ADMaterialScalarL2Error
    property = solid_reference_J
    function = jacobian
  []
  [J_dot_l2]
    type = ADMaterialScalarL2Error
    property = solid_reference_J_dot
    function = zero
  []
  [F_inv_rr_l2]
    type = ADMaterialRankTwoComponentL2Error
    property = solid_reference_F_inv
    row = 0
    column = 0
    function = inverse_lambda_r
  []
  [F_inv_zz_l2]
    type = ADMaterialRankTwoComponentL2Error
    property = solid_reference_F_inv
    row = 1
    column = 1
    function = inverse_lambda_z
  []
  [F_inv_tt_l2]
    type = ADMaterialRankTwoComponentL2Error
    property = solid_reference_F_inv
    row = 2
    column = 2
    function = inverse_lambda_r
  []
[]

[Executioner]
  type = Steady
[]

[Outputs]
  csv = true
[]
