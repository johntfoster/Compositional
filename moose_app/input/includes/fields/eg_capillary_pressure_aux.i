[AuxVariables]
  [capillary_pressure]
    family = LAGRANGE
    order = FIRST
  []
  [capillary_pressure_enr]
    family = MONOMIAL
    order = CONSTANT
  []
  [capillary_pressure_total]
    family = MONOMIAL
    order = FIRST
  []
[]
