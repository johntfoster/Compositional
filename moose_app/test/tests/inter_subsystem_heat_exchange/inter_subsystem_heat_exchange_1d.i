[Mesh]
  type = GeneratedMesh
  dim = 1
  nx = 1
[]

[Problem]
  solve = false
[]

[AuxVariables]
  [theta_f]
  []
  [theta_s]
  []
[]

[ICs]
  [theta_f_ic]
    type = ConstantIC
    variable = theta_f
    value = 300
  []
  [theta_s_ic]
    type = ConstantIC
    variable = theta_s
    value = 330
  []
[]

[Functions]
  [fluid_source_exact]
    type = ConstantFunction
    value = 60
  []
  [solid_source_exact]
    type = ConstantFunction
    value = -60
  []
  [zero]
    type = ConstantFunction
    value = 0
  []
  [entropy_exact]
    type = ConstantFunction
    value = 0.01818181818181818
  []
[]

[Materials]
  [heat_exchange]
    type = ADInterSubsystemHeatExchangeMaterial
    fluid_temperature = theta_f
    solid_temperature = theta_s
    heat_transfer_coefficient = 2
  []
[]

[Postprocessors]
  [fluid_source_l2]
    type = ADMaterialScalarL2Error
    property = fluid_solid_heat_exchange_fluid_source
    function = fluid_source_exact
  []
  [solid_source_l2]
    type = ADMaterialScalarL2Error
    property = fluid_solid_heat_exchange_solid_source
    function = solid_source_exact
  []
  [cancellation_l2]
    type = ADMaterialScalarL2Error
    property = fluid_solid_heat_exchange_cancellation
    function = zero
  []
  [entropy_l2]
    type = ADMaterialScalarL2Error
    property = fluid_solid_heat_exchange_entropy_production
    function = entropy_exact
  []
[]

[Executioner]
  type = Steady
[]

[Outputs]
  csv = true
[]
