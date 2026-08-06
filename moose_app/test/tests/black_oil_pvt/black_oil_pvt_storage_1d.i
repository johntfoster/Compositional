mesh_nx := 2

!include ../../../input/includes/mesh/generated_1d_q2.i
!include ../../../input/includes/fields/solid_q2_aux_1d.i

[AuxVariables]
  [pressure]
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
  [pressure_exact]
    type = ParsedFunction
    expression = '150'
  []
  [out_of_range_pressure]
    type = ParsedFunction
    expression = '250'
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
  [water_fvf_exact]
    type = ParsedFunction
    expression = '1.05'
  []
  [oil_fvf_exact]
    type = ParsedFunction
    expression = '1.3'
  []
  [gas_fvf_exact]
    type = ParsedFunction
    expression = '0.015'
  []
  [solution_gas_oil_ratio_exact]
    type = ParsedFunction
    expression = '75'
  []
  [water_viscosity_exact]
    type = ParsedFunction
    expression = '0.35'
  []
  [oil_viscosity_exact]
    type = ParsedFunction
    expression = '1.5'
  []
  [gas_viscosity_exact]
    type = ParsedFunction
    expression = '0.025'
  []
  [oil_saturation_exact]
    type = ParsedFunction
    expression = '0.5'
  []
  [water_density_exact]
    type = ParsedFunction
    expression = '1000/1.05'
  []
  [oil_density_exact]
    type = ParsedFunction
    expression = '(800+1.2*75)/1.3'
  []
  [gas_density_exact]
    type = ParsedFunction
    expression = '1.2/0.015'
  []
  [oil_component_fraction_exact]
    type = ParsedFunction
    expression = '800/(800+1.2*75)'
  []
  [gas_component_fraction_exact]
    type = ParsedFunction
    expression = '(1.2*75)/(800+1.2*75)'
  []
  [water_storage_exact]
    type = ParsedFunction
    expression = '1000*0.2*0.2/1.05'
  []
  [oil_storage_exact]
    type = ParsedFunction
    expression = '800*0.2*0.5/1.3'
  []
  [gas_storage_exact]
    type = ParsedFunction
    expression = '1.2*0.2*(0.3/0.015+75*0.5/1.3)'
  []
[]

[ICs]
  [ux_ic]
    type = FunctionIC
    variable = ux
    function = zero
  []
  [pressure_ic]
    type = FunctionIC
    variable = pressure
    function = pressure_exact
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

!include ../../../input/includes/materials/solid_kinematics_1d.i

[Materials]
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
    water_viscosity_values = '0.3 0.4'
    oil_viscosity_values = '1 2'
    gas_viscosity_values = '0.02 0.03'
    water_surface_density = 1000
    oil_surface_density = 800
    gas_surface_density = 1.2
  []
[]

[Postprocessors]
  [water_fvf_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_water_formation_volume_factor
    function = water_fvf_exact
    execute_on = INITIAL
  []
  [oil_fvf_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_oil_formation_volume_factor
    function = oil_fvf_exact
    execute_on = INITIAL
  []
  [gas_fvf_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_gas_formation_volume_factor
    function = gas_fvf_exact
    execute_on = INITIAL
  []
  [solution_gas_oil_ratio_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_solution_gas_oil_ratio
    function = solution_gas_oil_ratio_exact
    execute_on = INITIAL
  []
  [oil_saturation_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_oil_saturation
    function = oil_saturation_exact
    execute_on = INITIAL
  []
  [water_viscosity_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_water_viscosity
    function = water_viscosity_exact
    execute_on = INITIAL
  []
  [oil_viscosity_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_oil_viscosity
    function = oil_viscosity_exact
    execute_on = INITIAL
  []
  [gas_viscosity_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_gas_viscosity
    function = gas_viscosity_exact
    execute_on = INITIAL
  []
  [water_density_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_water_intrinsic_density
    function = water_density_exact
    execute_on = INITIAL
  []
  [oil_density_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_oil_intrinsic_density
    function = oil_density_exact
    execute_on = INITIAL
  []
  [gas_density_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_gas_intrinsic_density
    function = gas_density_exact
    execute_on = INITIAL
  []
  [oil_component_fraction_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_oil_component_mass_fraction_in_oil
    function = oil_component_fraction_exact
    execute_on = INITIAL
  []
  [gas_component_fraction_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_gas_component_mass_fraction_in_oil
    function = gas_component_fraction_exact
    execute_on = INITIAL
  []
  [water_current_storage_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_water_current_component_storage
    function = water_storage_exact
    execute_on = INITIAL
  []
  [oil_current_storage_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_oil_current_component_storage
    function = oil_storage_exact
    execute_on = INITIAL
  []
  [gas_current_storage_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_gas_current_component_storage
    function = gas_storage_exact
    execute_on = INITIAL
  []
  [water_reference_storage_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_water_reference_component_storage
    function = water_storage_exact
    execute_on = INITIAL
  []
  [oil_reference_storage_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_oil_reference_component_storage
    function = oil_storage_exact
    execute_on = INITIAL
  []
  [gas_reference_storage_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_gas_reference_component_storage
    function = gas_storage_exact
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
