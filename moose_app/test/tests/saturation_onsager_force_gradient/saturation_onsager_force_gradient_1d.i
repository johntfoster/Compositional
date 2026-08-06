[Mesh]
  [line]
    type = GeneratedMeshGenerator
    dim = 1
    nx = 1
    elem_type = EDGE2
  []
[]

[Variables]
  [water_saturation]
    family = LAGRANGE
    order = FIRST
  []
  [gas_saturation]
    family = LAGRANGE
    order = FIRST
  []
[]

[Functions]
  [water_saturation]
    type = ParsedFunction
    expression = '0.2+0.1*t*x'
  []
  [gas_saturation]
    type = ParsedFunction
    expression = '0.3-0.05*t*x'
  []
  [water_force]
    type = ParsedFunction
    expression = '0.175*x+0.095*x^2'
  []
  [gas_force]
    type = ParsedFunction
    expression = '-0.1*x'
  []
  [dissipation]
    type = ParsedFunction
    expression = '0.0225*x^2+0.0095*x^3'
  []
  [minimum_eigenvalue]
    type = ParsedFunction
    expression = '0.5*((2+x)+(3+0.2*x)-sqrt(((2+x)-(3+0.2*x))^2+4*(0.5+0.1*x)^2))'
  []
  [T00]
    type = ParsedFunction
    expression = '2+x'
  []
  [T01]
    type = ParsedFunction
    expression = '0.5+0.1*x'
  []
  [T10]
    type = ParsedFunction
    expression = '0.5+0.1*x'
  []
  [T11]
    type = ParsedFunction
    expression = '3+0.2*x'
  []
  [T10_bad]
    type = ParsedFunction
    expression = '0.6+0.1*x'
  []
  [one]
    type = ConstantFunction
    value = 1
  []
  [two]
    type = ConstantFunction
    value = 2
  []
  [one_tenth]
    type = ConstantFunction
    value = 0.1
  []
  [one_fifth]
    type = ConstantFunction
    value = 0.2
  []
  [zero]
    type = ConstantFunction
    value = 0
  []
[]

[ICs]
  [water_saturation]
    type = FunctionIC
    variable = water_saturation
    function = water_saturation
  []
  [gas_saturation]
    type = FunctionIC
    variable = gas_saturation
    function = gas_saturation
  []
[]

[Materials]
  [water_saturation_reconstruction]
    type = ADEGReconstructedScalarMaterial
    backbone = water_saturation
    field_name = test_water_saturation
  []
  [gas_saturation_reconstruction]
    type = ADEGReconstructedScalarMaterial
    backbone = gas_saturation
    field_name = test_gas_saturation
  []
  [water_saturation_rate_gradient]
    type = ADEGScalarRateGradientMaterial
    backbone = water_saturation
    total_rate_gradient_name = test_water_saturation_total_dot_gradient
  []
  [gas_saturation_rate_gradient]
    type = ADEGScalarRateGradientMaterial
    backbone = gas_saturation
    total_rate_gradient_name = test_gas_saturation_total_dot_gradient
  []
  [resistance_properties]
    type = ADGenericFunctionMaterial
    prop_names = 'test_T00 test_T01 test_T10 test_T11'
    prop_values = 'T00 T01 T10 T11'
  []
  [resistance_gradients]
    type = ADGenericFunctionVectorMaterial
    prop_names = 'test_grad_T00 test_grad_T01 test_grad_T10 test_grad_T11'
    prop_values = 'one zero zero one_tenth zero zero one_tenth zero zero one_fifth zero zero'
  []
  [saturation_onsager]
    type = ADSaturationOnsagerForceMaterial
    independent_phase_names = 'water gas'
    saturation_rate_names = 'test_water_saturation_total_dot test_gas_saturation_total_dot'
    resistance_property_names = 'test_T00 test_T01 test_T10 test_T11'
    property_prefix = test_saturation_onsager
  []
  [saturation_onsager_gradients]
    type = ADSaturationOnsagerForceGradientMaterial
    independent_phase_names = 'water gas'
    saturation_rate_names = 'test_water_saturation_total_dot test_gas_saturation_total_dot'
    saturation_rate_gradient_names = 'test_water_saturation_total_dot_gradient test_gas_saturation_total_dot_gradient'
    resistance_property_names = 'test_T00 test_T01 test_T10 test_T11'
    resistance_gradient_property_names = 'test_grad_T00 test_grad_T01 test_grad_T10 test_grad_T11'
    property_prefix = test_saturation_onsager
  []
[]

[Kernels]
  [water_reaction]
    type = ADReaction
    variable = water_saturation
  []
  [gas_reaction]
    type = ADReaction
    variable = gas_saturation
  []
[]

[BCs]
  [water_saturation]
    type = FunctionDirichletBC
    variable = water_saturation
    boundary = 'left right'
    function = water_saturation
  []
  [gas_saturation]
    type = FunctionDirichletBC
    variable = gas_saturation
    boundary = 'left right'
    function = gas_saturation
  []
[]

[Postprocessors]
  [water_force_value_l2]
    type = ADMaterialScalarL2Error
    property = test_saturation_onsager_water_force_difference
    function = water_force
  []
  [gas_force_value_l2]
    type = ADMaterialScalarL2Error
    property = test_saturation_onsager_gas_force_difference
    function = gas_force
  []
  [water_force_gradient_l2]
    type = ADMaterialVectorL2Error
    property = test_saturation_onsager_water_force_difference_gradient
    gradient_function = water_force
  []
  [gas_force_gradient_l2]
    type = ADMaterialVectorL2Error
    property = test_saturation_onsager_gas_force_difference_gradient
    gradient_function = gas_force
  []
  [dissipation_l2]
    type = ADMaterialScalarL2Error
    property = test_saturation_onsager_dissipation_rate
    function = dissipation
  []
  [entropy_production_l2]
    type = ADMaterialScalarL2Error
    property = test_saturation_onsager_entropy_production_rate
    function = dissipation
  []
  [minimum_eigenvalue_l2]
    type = ADMaterialScalarL2Error
    property = test_saturation_onsager_minimum_resistance_eigenvalue
    function = minimum_eigenvalue
  []
[]

[Executioner]
  type = Transient
  solve_type = NEWTON
  dt = 1
  num_steps = 1
  nl_rel_tol = 1e-12
  nl_abs_tol = 1e-13
[]

[Outputs]
  csv = true
[]
