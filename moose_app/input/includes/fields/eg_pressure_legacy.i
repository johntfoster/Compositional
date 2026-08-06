[Variables]
  [pressure]
    family = LAGRANGE
    order = FIRST
    scaling = 1
  []
  [pressure_enr]
    family = MONOMIAL
    order = CONSTANT
    initial_condition = 0
    scaling = 1
  []
[]

[AuxVariables]
  [pressure_total]
    family = MONOMIAL
    order = FIRST
  []
[]
