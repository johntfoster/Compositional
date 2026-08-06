[Mesh]
  type = GeneratedMesh
  dim = 1
  nx = 2
  elem_type = EDGE3
[]

[Variables]
  [u]
    family = BERNSTEIN
    order = SECOND
  []
[]

[AuxVariables]
  [bound_dummy]
    family = MONOMIAL
    order = CONSTANT
  []
[]

[Kernels]
  [reaction]
    type = ADReaction
    variable = u
  []
  [negative_target]
    type = ADBodyForce
    variable = u
    value = -1
  []
[]

[Bounds]
  [u_lower]
    type = CoefficientBounds
    variable = bound_dummy
    bounded_variable = u
    bound_type = lower
    bound_value = 0
  []
[]

[Executioner]
  type = Steady
  solve_type = NEWTON
  nl_abs_tol = 1e-12
  petsc_options_iname = '-snes_type -pc_type -pc_factor_mat_solver_type'
  petsc_options_value = 'vinewtonrsls lu mumps'
[]

[Postprocessors]
  [minimum_u]
    type = ElementExtremeValue
    variable = u
    value_type = min
  []
  [average_u]
    type = ElementAverageValue
    variable = u
  []
[]

[Outputs]
  csv = true
[]
