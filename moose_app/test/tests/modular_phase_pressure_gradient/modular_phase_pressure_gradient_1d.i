[Mesh]
  [line]
    type = GeneratedMeshGenerator
    dim = 1
    nx = 2
    elem_type = EDGE3
  []
[]

[Problem]
  solve = false
[]

[Variables]
  [ux]
    family = LAGRANGE
    order = SECOND
  []
  [oil_pressure]
    family = LAGRANGE
    order = SECOND
  []
  [water_saturation]
    family = LAGRANGE
    order = SECOND
  []
  [gas_saturation]
    family = LAGRANGE
    order = SECOND
  []
  [tau]
    family = LAGRANGE
    order = FIRST
  []
[]

[Functions]
  [oil_pressure]
    type = ParsedFunction
    expression = '10+2*x'
  []
  [water_saturation]
    type = ParsedFunction
    expression = '0.3+0.1*x'
  []
  [gas_saturation]
    type = ParsedFunction
    expression = '0.1+0.05*x'
  []
  [water_stored_difference]
    type = ParsedFunction
    expression = '-3+x'
  []
  [gas_stored_difference]
    type = ParsedFunction
    expression = '0.5+0.25*x'
  []
  [water_stored_gradient_potential]
    type = ParsedFunction
    expression = 'x'
  []
  [gas_stored_gradient_potential]
    type = ParsedFunction
    expression = '0.25*x'
  []
  [water_pressure_gradient_potential]
    type = ParsedFunction
    expression = '5.5*x'
  []
  [gas_pressure_gradient_potential]
    type = ParsedFunction
    expression = '2.25*x'
  []
  [water_flux_potential]
    type = ParsedFunction
    expression = '-11*x'
  []
[]

[ICs]
  [oil_pressure]
    type = FunctionIC
    variable = oil_pressure
    function = oil_pressure
  []
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

[UserObjects]
  [phases]
    type = PhaseRegistry
    phases = 'matrix water gas'
    reference_phase = matrix
    momentum_models = 'reference relative_flux relative_flux'
  []
[]

[Materials]
  [solid_kinematics]
    type = ADSolidReferenceKinematics
    displacements = ux
  []
  [oil_pressure_reconstruction]
    type = ADEGReconstructedScalarMaterial
    backbone = oil_pressure
    field_name = test_oil_pressure
  []
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
  [stored_capillary]
    type = ADBlackOilStoredCapillaryGradientMaterial
    water_saturation_name = test_water_saturation_total
    water_saturation_gradient_name = test_water_saturation_total_gradient
    gas_saturation_name = test_gas_saturation_total
    gas_saturation_gradient_name = test_gas_saturation_total_gradient
    water_saturation_points = '0.2 0.4'
    water_oil_capillary_pressure_values = '4 2'
    gas_saturation_points = '0 0.2'
    gas_oil_capillary_pressure_values = '0 1'
    property_prefix = test_stored
  []
  [extra_pressure_gradients]
    type = ADGenericConstantVectorMaterial
    prop_names = 'test_electrical_gradient test_saturation_force_gradient'
    prop_values = '3 0 0 -0.5 0 0'
  []
  [water_pressure_gradient]
    type = ADPhasePressureGradientAssemblerMaterial
    base_pressure_gradient_name = test_oil_pressure_total_gradient
    correction_gradient_names = 'test_stored_water_pressure_difference_gradient test_electrical_gradient test_saturation_force_gradient'
    correction_scales = '1 1 1'
    phase_pressure_gradient_name = test_water_pressure_gradient
  []
  [gas_pressure_gradient]
    type = ADPhasePressureGradientAssemblerMaterial
    base_pressure_gradient_name = test_oil_pressure_total_gradient
    correction_gradient_names = test_stored_gas_pressure_difference_gradient
    correction_scales = '1'
    phase_pressure_gradient_name = test_gas_pressure_gradient
  []
  [phase_constants]
    type = ADGenericConstantMaterial
    prop_names = 'test_intrinsic_density test_bulk_density test_conversion_source test_phase_active'
    prop_values = '2 1 0 1'
  []
  [water_flux]
    type = ADPhaseTransformingPressureGradientDarcyReferenceFluxMaterial
    phase = water
    phase_registry = phases
    phase_pressure_gradient_name = test_water_pressure_gradient
    intrinsic_density_source = material
    intrinsic_density_name = test_intrinsic_density
    bulk_density_name = test_bulk_density
    conversion_source_name = test_conversion_source
    phase_active_name = test_phase_active
    tau = tau
    solid_displacements = ux
    permeability = 1
    viscosity = 1
    reference_relative_mass_flux_name = test_water_reference_relative_mass_flux
    spatial_relative_mass_flux_name = test_water_spatial_relative_mass_flux
    darcy_mobility_ref_name = test_water_darcy_mobility
    combined_resistance_name = test_water_combined_resistance
    resistance_denominator_name = test_water_resistance_denominator
  []
[]

[Postprocessors]
  [water_stored_value_l2]
    type = ADMaterialScalarL2Error
    property = test_stored_water_pressure_difference
    function = water_stored_difference
  []
  [gas_stored_value_l2]
    type = ADMaterialScalarL2Error
    property = test_stored_gas_pressure_difference
    function = gas_stored_difference
  []
  [water_stored_gradient_l2]
    type = ADMaterialVectorL2Error
    property = test_stored_water_pressure_difference_gradient
    gradient_function = water_stored_gradient_potential
  []
  [gas_stored_gradient_l2]
    type = ADMaterialVectorL2Error
    property = test_stored_gas_pressure_difference_gradient
    gradient_function = gas_stored_gradient_potential
  []
  [water_pressure_gradient_l2]
    type = ADMaterialVectorL2Error
    property = test_water_pressure_gradient
    gradient_function = water_pressure_gradient_potential
  []
  [gas_pressure_gradient_l2]
    type = ADMaterialVectorL2Error
    property = test_gas_pressure_gradient
    gradient_function = gas_pressure_gradient_potential
  []
  [water_reference_flux_l2]
    type = ADMaterialVectorL2Error
    property = test_water_reference_relative_mass_flux
    gradient_function = water_flux_potential
  []
[]

[Executioner]
  type = Steady
[]

[Outputs]
  csv = true
[]
