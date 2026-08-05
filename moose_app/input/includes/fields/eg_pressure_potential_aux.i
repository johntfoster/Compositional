[AuxVariables]
  [pressure_potential]
    family = LAGRANGE
    order = FIRST
  []
  [pressure_potential_enr]
    family = MONOMIAL
    order = CONSTANT
  []
  [pressure_potential_total]
    family = MONOMIAL
    order = FIRST
  []
[]
