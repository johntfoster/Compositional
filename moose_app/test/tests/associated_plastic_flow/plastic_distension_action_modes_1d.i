[Mesh]
  type = GeneratedMesh
  dim = 1
  nx = 4
[]

[Variables]
  [Ap00]
  []
  [ap]
  []
[]

[ICs]
  [Ap00_ic]
    type = ConstantIC
    variable = Ap00
    value = 1
  []
  [ap_ic]
    type = ConstantIC
    variable = ap
    value = 1
  []
[]

[Functions]
  [Ap00_exact]
    type = ParsedFunction
    expression = '1/(1-0.1*t)'
  []
  [ap_exact]
    type = ParsedFunction
    expression = '1/(1-0.2*t)'
  []
[]

[Materials]
  [tensor_rate]
    type = ADGenericConstantRankTwoTensor
    tensor_name = selected_tensor_log_rate
    tensor_values = '0.1 0 0  0 0 0  0 0 0'
  []
  [scalar_rate]
    type = ADGenericConstantMaterial
    prop_names = selected_scalar_log_rate
    prop_values = 0.2
  []
[]

[Physics]
  [PlasticDistension]
    [tensor_choice]
      mode = tensor
      tensor_variables = Ap00
      tensor_log_rate_name = selected_tensor_log_rate
    []
    [scalar_choice]
      mode = scalar
      scalar_variable = ap
      scalar_log_rate_name = selected_scalar_log_rate
    []
  []
[]

[Postprocessors]
  [Ap00_l2]
    type = ElementL2Error
    variable = Ap00
    function = Ap00_exact
  []
  [ap_l2]
    type = ElementL2Error
    variable = ap
    function = ap_exact
  []
[]

[Executioner]
  type = Transient
  solve_type = NEWTON
  scheme = implicit-euler
  dt = 0.1
  num_steps = 1
  nl_abs_tol = 1e-12
  nl_rel_tol = 1e-12
[]

[Outputs]
  csv = true
[]
