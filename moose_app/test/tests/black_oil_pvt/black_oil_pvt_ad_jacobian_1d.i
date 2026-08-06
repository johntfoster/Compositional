mesh_nx := 2

!include ../../../input/includes/mesh/generated_1d_q2.i

[Variables]
  [pressure]
    family = LAGRANGE
    order = SECOND
  []
[]

[AuxVariables]
  [porosity]
  []
  [water_saturation]
  []
  [gas_saturation]
  []
[]

[Functions]
  [pressure_initial]
    type = ParsedFunction
    expression = '125'
  []
  [pressure_exact]
    type = ParsedFunction
    expression = '150'
  []
  [porosity_exact]
    type = ParsedFunction
    expression = '0.2'
  []
  [water_saturation_exact]
    type = ParsedFunction
    expression = '0.2'
  []
  [gas_saturation_exact]
    type = ParsedFunction
    expression = '0.3'
  []
[]

[ICs]
  [pressure_ic]
    type = FunctionIC
    variable = pressure
    function = pressure_initial
  []
  [porosity_ic]
    type = FunctionIC
    variable = porosity
    function = porosity_exact
  []
  [water_saturation_ic]
    type = FunctionIC
    variable = water_saturation
    function = water_saturation_exact
  []
  [gas_saturation_ic]
    type = FunctionIC
    variable = gas_saturation
    function = gas_saturation_exact
  []
[]

[Materials]
  [unit_jacobian]
    type = ADGenericConstantMaterial
    prop_names = 'solid_reference_J solid_reference_J_dot'
    prop_values = '1 0'
  []
  [black_oil_pvt]
    type = ADBlackOilPVTMaterial
    pressure = pressure
    porosity = porosity
    water_saturation = water_saturation
    gas_saturation = gas_saturation
    pressure_points = '100 200'
    water_formation_volume_factor_values = '1 1.1'
    oil_formation_volume_factor_values = '1.2 1.4'
    gas_formation_volume_factor_values = '0.01 0.02'
    solution_gas_oil_ratio_values = '50 100'
    water_surface_density = 1000
    oil_surface_density = 800
    gas_surface_density = 1.2
  []
  [water_fvf_residual]
    type = ADParsedMaterial
    material_property_names = black_oil_water_formation_volume_factor
    property_name = water_fvf_residual
    expression = 'black_oil_water_formation_volume_factor-1.05'
  []
[]

[Kernels]
  [pressure_from_pvt_table]
    type = ADMaterialPropertyResidual
    variable = pressure
    property = water_fvf_residual
  []
[]

[Postprocessors]
  [pressure_l2]
    type = ElementL2Error
    variable = pressure
    function = pressure_exact
    execute_on = TIMESTEP_END
  []
[]

[Executioner]
  type = Steady
  solve_type = NEWTON
  nl_abs_tol = 1e-12
  nl_rel_tol = 1e-12
[]

[Outputs]
  csv = true
[]
