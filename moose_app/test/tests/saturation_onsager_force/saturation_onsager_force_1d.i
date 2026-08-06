[Mesh]
  type = GeneratedMesh
  dim = 1
  nx = 1
  elem_type = EDGE2
[]

[Variables]
  [water_saturation]
  []
  [gas_saturation]
  []
[]

[Functions]
  [water_saturation_exact]
    type = ParsedFunction
    expression = '0.2+0.1*t'
  []
  [gas_saturation_exact]
    type = ParsedFunction
    expression = '0.4-0.05*t'
  []
  [water_force_exact]
    type = ParsedFunction
    expression = '0.175'
  []
  [gas_force_exact]
    type = ParsedFunction
    expression = '-0.1'
  []
  [dissipation_exact]
    type = ParsedFunction
    expression = '0.0225'
  []
  [entropy_production_exact]
    type = ParsedFunction
    expression = '1.875e-5'
  []
  [minimum_eigenvalue_exact]
    type = ParsedFunction
    expression = '1.7928932188134525'
  []
[]

[ICs]
  [water_saturation]
    type = FunctionIC
    variable = water_saturation
    function = water_saturation_exact
  []
  [gas_saturation]
    type = FunctionIC
    variable = gas_saturation
    function = gas_saturation_exact
  []
[]

[Materials]
  [water_saturation_reconstruction]
    type = ADEGReconstructedScalarMaterial
    backbone = water_saturation
    field_name = water_saturation
  []
  [gas_saturation_reconstruction]
    type = ADEGReconstructedScalarMaterial
    backbone = gas_saturation
    field_name = gas_saturation
  []
  [saturation_onsager]
    type = ADSaturationOnsagerForceMaterial
    independent_phase_names = 'water gas'
    saturation_rate_names = 'water_saturation_total_dot gas_saturation_total_dot'
    resistance_matrix = '2 0.5 0.5 3'
    porosity = 0.25
    fluid_temperature = 300
  []
[]

[Kernels]
  [water_null]
    type = NullKernel
    variable = water_saturation
  []
  [gas_null]
    type = NullKernel
    variable = gas_saturation
  []
[]

[BCs]
  [water_saturation]
    type = FunctionDirichletBC
    variable = water_saturation
    boundary = 'left right'
    function = water_saturation_exact
  []
  [gas_saturation]
    type = FunctionDirichletBC
    variable = gas_saturation
    boundary = 'left right'
    function = gas_saturation_exact
  []
[]

[Postprocessors]
  [water_force_l2]
    type = ADMaterialScalarL2Error
    property = saturation_onsager_water_force_difference
    function = water_force_exact
  []
  [gas_force_l2]
    type = ADMaterialScalarL2Error
    property = saturation_onsager_gas_force_difference
    function = gas_force_exact
  []
  [dissipation_l2]
    type = ADMaterialScalarL2Error
    property = saturation_onsager_dissipation_rate
    function = dissipation_exact
  []
  [entropy_production_l2]
    type = ADMaterialScalarL2Error
    property = saturation_onsager_entropy_production_rate
    function = entropy_production_exact
  []
  [minimum_eigenvalue_l2]
    type = ADMaterialScalarL2Error
    property = saturation_onsager_minimum_resistance_eigenvalue
    function = minimum_eigenvalue_exact
  []
[]

[Executioner]
  type = Transient
  scheme = implicit-euler
  solve_type = NEWTON
  dt = 1
  num_steps = 1
  nl_abs_tol = 1e-12
[]

[Outputs]
  csv = true
[]
