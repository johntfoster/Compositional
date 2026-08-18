mesh_nx := 2

!include ../../../input/includes/mesh/generated_1d_q2.i
!include ../../../input/includes/fields/solid_q2_aux_1d.i

[AuxVariables]
  [oil_pressure]
  []
  [solution_gas_oil_ratio]
  []
  [porosity]
  []
  [water_saturation]
  []
  [gas_saturation]
  []
[]

[Functions]
  [zero]
    type = ParsedFunction
    expression = '0'
  []
  [oil_pressure_exact]
    type = ParsedFunction
    expression = '4800'
  []
  [solution_gas_oil_ratio_exact]
    type = ParsedFunction
    expression = '1.27'
  []
  [left_extreme_solution_gas_oil_ratio]
    type = ParsedFunction
    expression = '1.0'
  []
  [oversaturated_solution_gas_oil_ratio]
    type = ParsedFunction
    expression = '1.6'
  []
  [porosity_exact]
    type = ParsedFunction
    expression = '0.3'
  []
  [water_saturation_exact]
    type = ParsedFunction
    expression = '0.12'
  []
  [water_fvf_exact]
    type = ParsedFunction
    expression = '1.0353880649286518'
  []
  [water_viscosity_exact]
    type = ParsedFunction
    expression = '0.318'
  []
  [gas_fvf_exact]
    type = ParsedFunction
    expression = '0.678080891130411'
  []
  [gas_viscosity_exact]
    type = ParsedFunction
    expression = '0.030074087169528165'
  []
  [oil_fvf_exact]
    type = ParsedFunction
    expression = '1.6756656833074408'
  []
  [oil_viscosity_exact]
    type = ParsedFunction
    expression = '0.537863727373857'
  []
  [left_extreme_oil_fvf_exact]
    type = ParsedFunction
    expression = '1.5540450460172681'
  []
  [left_extreme_oil_viscosity_exact]
    type = ParsedFunction
    expression = '0.6417927211216924'
  []
  [saturated_solution_gas_oil_ratio_exact]
    type = ParsedFunction
    expression = '1.5432844'
  []
  [undersaturation_gap_exact]
    type = ParsedFunction
    expression = '0.2732844'
  []
  [left_extreme_undersaturation_gap_exact]
    type = ParsedFunction
    expression = '0.5432844'
  []
  [active_gas_saturation]
    type = ParsedFunction
    expression = '0.1'
  []
  [negative_gas_saturation]
    type = ParsedFunction
    expression = '-0.1'
  []
  [cap_branch_complementarity_exact]
    type = ParsedFunction
    expression = '-0.1'
  []
  [saturated_solution_gas_oil_ratio_state]
    type = ParsedFunction
    expression = '1.5432844'
  []
  [saturated_oil_fvf_exact]
    type = ParsedFunction
    expression = '1.7969549138405854'
  []
  [saturated_oil_viscosity_exact]
    type = ParsedFunction
    expression = '0.4615658791296567'
  []
[]

[ICs]
  [ux_ic]
    type = FunctionIC
    variable = ux
    function = zero
  []
  [oil_pressure_ic]
    type = FunctionIC
    variable = oil_pressure
    function = oil_pressure_exact
  []
  [solution_gas_oil_ratio_ic]
    type = FunctionIC
    variable = solution_gas_oil_ratio
    function = solution_gas_oil_ratio_exact
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
    function = zero
  []
[]

!include ../../../input/includes/materials/solid_kinematics_1d.i

[Materials]
  [spe1_pvt]
    type = ADBlackOilBenchmarkPVTMaterial
    oil_pressure = oil_pressure
    solution_gas_oil_ratio = solution_gas_oil_ratio
    porosity = porosity
    water_saturation = water_saturation
    gas_saturation = gas_saturation
    water_reference_pressure = 4017.55
    water_reference_fvf = 1.038
    water_compressibility = 3.22e-6
    water_reference_viscosity = 0.318
    water_viscosibility = 0
    gas_pressure_points = '14.7 264.7 514.7 1014.7 2014.7 2514.7 3014.7 4014.7 5014.7 9014.7'
    gas_fvf_values = '166.666 12.093 6.274 3.197 1.614 1.294 1.080 0.811 0.649 0.386'
    gas_viscosity_values = '0.008 0.0096 0.0112 0.014 0.0189 0.0208 0.0228 0.0268 0.0309 0.047'
    oil_solution_gas_oil_ratio_points = '0.001 0.0905 0.18 0.371 0.636 0.775 0.93 1.27 1.618'
    oil_bubble_pressure_points = '14.7 264.7 514.7 1014.7 2014.7 2514.7 3014.7 4014.7 5014.7'
    oil_branch_offsets = '0 1 2 3 4 5 6 7 9 11'
    oil_pressure_points = '14.7 264.7 514.7 1014.7 2014.7 2514.7 3014.7 4014.7 9014.7 5014.7 9014.7'
    oil_fvf_values = '1.062 1.15 1.207 1.295 1.435 1.5 1.565 1.695 1.579 1.827 1.737'
    oil_viscosity_values = '1.04 0.975 0.91 0.83 0.695 0.641 0.594 0.51 0.74 0.449 0.631'
    saturated_oil_fvf_values = '1.062 1.15 1.207 1.295 1.435 1.5 1.565 1.695 1.827'
    saturated_oil_viscosity_values = '1.04 0.975 0.91 0.83 0.695 0.641 0.594 0.51 0.449'
    water_surface_density = 64.49
    oil_surface_density = 53.66
    gas_surface_density = 0.0533
  []
[]

[Postprocessors]
  [water_fvf_l2]
    type = ADMaterialScalarL2Error
    property = benchmark_black_oil_water_formation_volume_factor
    function = water_fvf_exact
    execute_on = INITIAL
  []
  [water_viscosity_l2]
    type = ADMaterialScalarL2Error
    property = benchmark_black_oil_water_viscosity
    function = water_viscosity_exact
    execute_on = INITIAL
  []
  [gas_fvf_l2]
    type = ADMaterialScalarL2Error
    property = benchmark_black_oil_gas_formation_volume_factor
    function = gas_fvf_exact
    execute_on = INITIAL
  []
  [gas_viscosity_l2]
    type = ADMaterialScalarL2Error
    property = benchmark_black_oil_gas_viscosity
    function = gas_viscosity_exact
    execute_on = INITIAL
  []
  [oil_fvf_l2]
    type = ADMaterialScalarL2Error
    property = benchmark_black_oil_oil_formation_volume_factor
    function = oil_fvf_exact
    execute_on = INITIAL
  []
  [oil_viscosity_l2]
    type = ADMaterialScalarL2Error
    property = benchmark_black_oil_oil_viscosity
    function = oil_viscosity_exact
    execute_on = INITIAL
  []
  [saturated_solution_gas_oil_ratio_l2]
    type = ADMaterialScalarL2Error
    property = benchmark_black_oil_saturated_solution_gas_oil_ratio
    function = saturated_solution_gas_oil_ratio_exact
    execute_on = INITIAL
  []
  [undersaturation_gap_l2]
    type = ADMaterialScalarL2Error
    property = benchmark_black_oil_undersaturation_gap
    function = undersaturation_gap_exact
    execute_on = INITIAL
  []
  [gas_appearance_complementarity_l2]
    type = ADMaterialScalarL2Error
    property = benchmark_black_oil_gas_appearance_complementarity_residual
    function = zero
    execute_on = INITIAL
  []
[]

[Problem]
  solve = false
[]

[Executioner]
  type = Steady
[]

[Outputs]
  csv = true
[]
