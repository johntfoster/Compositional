[Kernels]
  [solid_x]
    type = ADReferenceSolidMomentum
    variable = ux
    component = 0
    reference_body_force = body_x
  []
[]

[BCs]
  [ux_dirichlet]
    type = FunctionDirichletBC
    variable = ux
    boundary = ${all_boundaries}
    function = ux_exact
  []
[]
