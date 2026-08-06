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
  [water_pressure_difference]
  []
  [gas_pressure_difference]
  []
[]

[Functions]
  [water_saturation_exact]
    type = ParsedFunction
    expression = '0.2+0.1*t'
  []
  [gas_saturation_exact]
    type = ParsedFunction
    expression = '0.15-0.05*t'
  []
  [water_pressure_difference_exact]
    type = ParsedFunction
    expression = '-2.825'
  []
  [gas_pressure_difference_exact]
    type = ParsedFunction
    expression = '-1.6'
  []
  [water_stored_exact]
    type = ParsedFunction
    expression = '-4'
  []
  [gas_stored_exact]
    type = ParsedFunction
    expression = '0.5'
  []
  [water_force_exact]
    type = ParsedFunction
    expression = '0.175'
  []
  [gas_force_exact]
    type = ParsedFunction
    expression = '-0.1'
  []
  [water_electrical_exact]
    type = ParsedFunction
    expression = '1'
  []
  [gas_electrical_exact]
    type = ParsedFunction
    expression = '-2'
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
  [water_pressure_difference]
    type = FunctionIC
    variable = water_pressure_difference
    function = water_pressure_difference_exact
  []
  [gas_pressure_difference]
    type = FunctionIC
    variable = gas_pressure_difference
    function = gas_pressure_difference_exact
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
  [electrical_enthalpy_differences]
    type = ADGenericConstantMaterial
    prop_names = 'water_electrical_enthalpy_difference gas_electrical_enthalpy_difference'
    prop_values = '1 -2'
  []
  [saturation_onsager]
    type = ADSaturationOnsagerForceMaterial
    independent_phase_names = 'water gas'
    saturation_rate_names = 'water_saturation_total_dot gas_saturation_total_dot'
    resistance_matrix = '2 0.5 0.5 3'
  []
  [phase_pressure_differences]
    type = ADBlackOilPhasePressureDifferenceMaterial
    water_pressure_difference = water_pressure_difference
    gas_pressure_difference = gas_pressure_difference
    water_saturation_name = water_saturation_total
    gas_saturation_name = gas_saturation_total
    water_saturation_points = '0.22 0.30 0.40 0.50 0.60 0.80 0.90 1.00'
    water_oil_capillary_pressure_values = '7 4 3 2.5 2 1 0.5 0'
    gas_saturation_points = '0 0.04 0.10 0.20 0.30 0.40 0.50 0.60 0.70 0.78'
    gas_oil_capillary_pressure_values = '0 0.2 0.5 1 1.5 2 2.5 3 3.5 3.9'
    water_electrical_enthalpy_difference_name = water_electrical_enthalpy_difference
    gas_electrical_enthalpy_difference_name = gas_electrical_enthalpy_difference
    water_saturation_force_difference_name = saturation_onsager_water_force_difference
    gas_saturation_force_difference_name = saturation_onsager_gas_force_difference
    property_prefix = all_terms_pressure
  []
[]

[Kernels]
  [water_saturation_null]
    type = NullKernel
    variable = water_saturation
  []
  [gas_saturation_null]
    type = NullKernel
    variable = gas_saturation
  []
  [water_pressure_difference_closure]
    type = ADMaterialPropertyResidual
    variable = water_pressure_difference
    property = all_terms_pressure_water_pressure_difference_closure_residual
  []
  [gas_pressure_difference_closure]
    type = ADMaterialPropertyResidual
    variable = gas_pressure_difference
    property = all_terms_pressure_gas_pressure_difference_closure_residual
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
  [water_pressure_difference_l2]
    type = ElementL2Error
    variable = water_pressure_difference
    function = water_pressure_difference_exact
  []
  [gas_pressure_difference_l2]
    type = ElementL2Error
    variable = gas_pressure_difference
    function = gas_pressure_difference_exact
  []
  [water_stored_l2]
    type = ADMaterialScalarL2Error
    property = all_terms_pressure_water_stored_surface_energy_difference
    function = water_stored_exact
  []
  [gas_stored_l2]
    type = ADMaterialScalarL2Error
    property = all_terms_pressure_gas_stored_surface_energy_difference
    function = gas_stored_exact
  []
  [water_force_l2]
    type = ADMaterialScalarL2Error
    property = all_terms_pressure_water_saturation_force_difference
    function = water_force_exact
  []
  [gas_force_l2]
    type = ADMaterialScalarL2Error
    property = all_terms_pressure_gas_saturation_force_difference
    function = gas_force_exact
  []
  [water_electrical_l2]
    type = ADMaterialScalarL2Error
    property = all_terms_pressure_water_electrical_enthalpy_difference
    function = water_electrical_exact
  []
  [gas_electrical_l2]
    type = ADMaterialScalarL2Error
    property = all_terms_pressure_gas_electrical_enthalpy_difference
    function = gas_electrical_exact
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
