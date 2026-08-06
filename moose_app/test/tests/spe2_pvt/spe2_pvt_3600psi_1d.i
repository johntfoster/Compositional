[Mesh]
  [line]
    type = GeneratedMeshGenerator
    dim = 1
    nx = 1
    elem_type = EDGE2
  []
[]

[Problem]
  solve = false
[]

[Variables]
  [oil_pressure]
  []
  [solution_gas_oil_ratio]
  []
  [water_saturation]
  []
  [gas_saturation]
  []
[]

[Functions]
  [water_fvf]
    type = ParsedFunction
    expression = '1.0033500289498194'
  []
  [water_density]
    type = ParsedFunction
    expression = '1006.1130539693795'
  []
  [oil_fvf]
    type = ParsedFunction
    expression = '1.11'
  []
  [oil_density]
    type = ParsedFunction
    expression = '900.1998906373403'
  []
  [gas_fvf]
    type = ParsedFunction
    expression = '0.0036494791666666668'
  []
  [gas_density]
    type = ParsedFunction
    expression = '308.12509881487705'
  []
  [water_viscosity]
    type = ParsedFunction
    expression = '0.00096'
  []
  [oil_viscosity]
    type = ParsedFunction
    expression = '0.00095'
  []
  [gas_viscosity]
    type = ParsedFunction
    expression = '0.000017'
  []
  [zero]
    type = ParsedFunction
    expression = '0'
  []
  [one]
    type = ParsedFunction
    expression = '1'
  []
[]

[ICs]
  [oil_pressure]
    type = ConstantIC
    variable = oil_pressure
    value = 24821126.2554048
  []
  [solution_gas_oil_ratio]
    type = ConstantIC
    variable = solution_gas_oil_ratio
    value = 247.569573283859
  []
  [water_saturation]
    type = ConstantIC
    variable = water_saturation
    value = 0.22
  []
  [gas_saturation]
    type = ConstantIC
    variable = gas_saturation
    value = 0
  []
[]

[Materials]
  [state_constants]
    type = ADGenericConstantMaterial
    prop_names = 'solid_reference_J solid_reference_J_dot solid_current_porosity solid_current_porosity_dot'
    prop_values = '1 0 0.1 0'
  []
  [oil_pressure_reconstruction]
    type = ADEGReconstructedScalarMaterial
    backbone = oil_pressure
    field_name = spe2_oil_pressure
  []
  [water_saturation_reconstruction]
    type = ADEGReconstructedScalarMaterial
    backbone = water_saturation
    field_name = spe2_water_saturation
  []
  [gas_saturation_reconstruction]
    type = ADEGReconstructedScalarMaterial
    backbone = gas_saturation
    field_name = spe2_gas_saturation
  []
[]

!include ../../../input/includes/materials/spe2_black_oil_pvt.i

[Postprocessors]
  [water_fvf_l2]
    type = ADMaterialScalarL2Error
    property = benchmark_black_oil_water_formation_volume_factor
    function = water_fvf
  []
  [water_density_l2]
    type = ADMaterialScalarL2Error
    property = benchmark_black_oil_water_intrinsic_density
    function = water_density
  []
  [oil_fvf_l2]
    type = ADMaterialScalarL2Error
    property = benchmark_black_oil_oil_formation_volume_factor
    function = oil_fvf
  []
  [oil_density_l2]
    type = ADMaterialScalarL2Error
    property = benchmark_black_oil_oil_intrinsic_density
    function = oil_density
  []
  [gas_fvf_l2]
    type = ADMaterialScalarL2Error
    property = benchmark_black_oil_gas_formation_volume_factor
    function = gas_fvf
  []
  [gas_density_l2]
    type = ADMaterialScalarL2Error
    property = benchmark_black_oil_gas_intrinsic_density
    function = gas_density
  []
  [water_viscosity_l2]
    type = ADMaterialScalarL2Error
    property = benchmark_black_oil_water_viscosity
    function = water_viscosity
  []
  [oil_viscosity_l2]
    type = ADMaterialScalarL2Error
    property = benchmark_black_oil_oil_viscosity
    function = oil_viscosity
  []
  [gas_viscosity_l2]
    type = ADMaterialScalarL2Error
    property = benchmark_black_oil_gas_viscosity
    function = gas_viscosity
  []
  [undersaturation_gap_l2]
    type = ADMaterialScalarL2Error
    property = benchmark_black_oil_undersaturation_gap
    function = zero
  []
  [water_relative_permeability_l2]
    type = ADMaterialScalarL2Error
    property = spe2_black_oil_water_relative_permeability
    function = zero
  []
  [oil_relative_permeability_l2]
    type = ADMaterialScalarL2Error
    property = spe2_black_oil_oil_relative_permeability
    function = one
  []
  [gas_relative_permeability_l2]
    type = ADMaterialScalarL2Error
    property = spe2_black_oil_gas_relative_permeability
    function = zero
  []
[]

[Executioner]
  type = Transient
  dt = 1
  num_steps = 1
[]

[Outputs]
  csv = true
[]
