[AuxVariables]
  [pressure0]
    family = LAGRANGE
    order = FIRST
  []
  [pressure0_enr]
    family = MONOMIAL
    order = CONSTANT
  []
  [pressure0_total]
    family = MONOMIAL
    order = FIRST
  []
  [pressure1]
    family = LAGRANGE
    order = FIRST
  []
  [pressure1_enr]
    family = MONOMIAL
    order = CONSTANT
  []
  [pressure1_total]
    family = MONOMIAL
    order = FIRST
  []
[]
