[AuxVariables]
  [pressure_oil]
    family = LAGRANGE
    order = FIRST
  []
  [pressure_oil_enr]
    family = MONOMIAL
    order = CONSTANT
  []
  [pressure_oil_total]
    family = MONOMIAL
    order = FIRST
  []
  [pressure_gas]
    family = LAGRANGE
    order = FIRST
  []
  [pressure_gas_enr]
    family = MONOMIAL
    order = CONSTANT
  []
  [pressure_gas_total]
    family = MONOMIAL
    order = FIRST
  []
  [pressure_water]
    family = LAGRANGE
    order = FIRST
  []
  [pressure_water_enr]
    family = MONOMIAL
    order = CONSTANT
  []
  [pressure_water_total]
    family = MONOMIAL
    order = FIRST
  []
[]
