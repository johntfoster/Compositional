!include peaceman_bhp_component_sources_1d.i

[Variables]
  [water_pressure_variable]
  []
  [oil_pressure_variable]
  []
  [gas_pressure_variable]
  []
[]

[ICs]
  [water_pressure_ic]
    type = ConstantIC
    variable = water_pressure_variable
    value = 100
  []
  [oil_pressure_ic]
    type = ConstantIC
    variable = oil_pressure_variable
    value = 110
  []
  [gas_pressure_ic]
    type = ConstantIC
    variable = gas_pressure_variable
    value = 120
  []
[]

[Materials]
  [well]
    pressure_source = coupled
    water_pressure = water_pressure_variable
    oil_pressure = oil_pressure_variable
    gas_pressure = gas_pressure_variable
  []
[]
