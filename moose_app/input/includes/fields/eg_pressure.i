[Variables]
  [p]
    family = LAGRANGE
    order = FIRST
    scaling = 1
  []
  [p_enr]
    family = MONOMIAL
    order = CONSTANT
    initial_condition = 0
    scaling = 1
  []
[]

[AuxVariables]
  [p_total]
    family = MONOMIAL
    order = FIRST
  []
[]
