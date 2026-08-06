[Kernels]
  [solid_x]
    type = ADReferenceSolidMomentum
    variable = ux
    component = 0
    reference_body_force = body_x
  []
  [solid_y]
    type = ADReferenceSolidMomentum
    variable = uy
    component = 1
    reference_body_force = body_y
  []
[]

[BCs]
  [ux_dirichlet]
    type = FunctionDirichletBC
    variable = ux
    boundary = ${all_boundaries}
    function = ux_exact
  []
  [uy_dirichlet]
    type = FunctionDirichletBC
    variable = uy
    boundary = ${all_boundaries}
    function = uy_exact
  []
[]
