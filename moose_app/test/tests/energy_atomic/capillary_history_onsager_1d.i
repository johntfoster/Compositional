[Mesh]
  type = GeneratedMesh
  dim = 1
  nx = 2
[]

[Variables]
  [history]
    family = LAGRANGE
    order = FIRST
  []
[]

[Functions]
  [history_exact]
    type = ParsedFunction
    expression = '1-t'
  []
  [zero]
    type = ParsedFunction
    expression = '0'
  []
  [rate_exact]
    type = ParsedFunction
    expression = '-1'
  []
  [dissipation_exact]
    type = ParsedFunction
    expression = '1.2'
  []
  [entropy_exact]
    type = ParsedFunction
    expression = '0.004'
  []
[]

[ICs]
  [history_ic]
    type = ConstantIC
    variable = history
    value = 1
  []
[]

[Materials]
  [constants]
    type = ADGenericConstantMaterial
    prop_names = 'fluid_fraction fluid_temperature gamma_history_derivative'
    prop_values = '0.6 300 2'
  []
  [history_onsager]
    type = ADCapillaryHistoryOnsagerMaterial
    history_variables = history
    history_derivative_names = gamma_history_derivative
    history_mobilities = '0.5'
    porosity_name = fluid_fraction
    fluid_temperature_name = fluid_temperature
  []
[]

[Kernels]
  [history_equation]
    type = ADMaterialPropertyResidual
    variable = history
    property = capillary_history_rate_residual_0
  []
[]

[Postprocessors]
  [history_error]
    type = ElementL2Error
    variable = history
    function = history_exact
  []
  [predicted_rate_error]
    type = ADMaterialScalarL2Error
    property = capillary_history_predicted_rate_0
    function = rate_exact
  []
  [rate_residual_error]
    type = ADMaterialScalarL2Error
    property = capillary_history_rate_residual_0
    function = zero
  []
  [dissipation_error]
    type = ADMaterialScalarL2Error
    property = capillary_history_dissipation_rate
    function = dissipation_exact
  []
  [predicted_dissipation_error]
    type = ADMaterialScalarL2Error
    property = capillary_history_predicted_dissipation_rate
    function = dissipation_exact
  []
  [entropy_production_error]
    type = ADMaterialScalarL2Error
    property = capillary_history_entropy_production_rate
    function = entropy_exact
  []
[]

[Executioner]
  type = Transient
  solve_type = NEWTON
  scheme = implicit-euler
  dt = 0.1
  end_time = 0.1
  nl_abs_tol = 1e-13
  nl_rel_tol = 1e-13
[]

[Outputs]
  console = true
  csv = true
[]
