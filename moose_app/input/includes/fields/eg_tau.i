[Variables]
  [tau]
    family = LAGRANGE
    order = FIRST
    scaling = 1
  []
  [tau_enr]
    family = MONOMIAL
    order = CONSTANT
    scaling = 1
  []
[]

[AuxVariables]
  [tau_total]
    family = MONOMIAL
    order = FIRST
  []
[]
