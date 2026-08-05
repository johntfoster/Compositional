[AuxVariables]
  [pressure]
    family = LAGRANGE
    order = FIRST
  []
  [pressure_enr]
    family = MONOMIAL
    order = CONSTANT
  []
  [pressure_total]
    family = MONOMIAL
    order = FIRST
  []
[]
