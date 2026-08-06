[Mesh]
  [mesh]
    type = GeneratedMeshGenerator
    dim = 2
    nx = 1
    ny = 1
    elem_type = QUAD9
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
  [uy]
    family = LAGRANGE
    order = SECOND
  []
  [tau]
    family = LAGRANGE
    order = FIRST
  []
[]

[Functions]
  [tau]
    type = ParsedFunction
    expression = 'x-y'
  []
  [expected_flux]
    type = ParsedFunction
    expression = '-1.1428571428571428*x-4.125*y'
  []
  [mobility_x]
    type = ConstantFunction
    value = 1.4285714285714286
  []
  [mobility_y]
    type = ConstantFunction
    value = 1.875
  []
  [mobility_z]
    type = ConstantFunction
    value = 2.2222222222222222
  []
  [resistance_x]
    type = ConstantFunction
    value = 0.35
  []
  [resistance_y]
    type = ConstantFunction
    value = 0.26666666666666667
  []
  [resistance_z]
    type = ConstantFunction
    value = 0.225
  []
  [denominator_x]
    type = ConstantFunction
    value = 0.35
  []
  [denominator_y]
    type = ConstantFunction
    value = 0.4
  []
  [denominator_z]
    type = ConstantFunction
    value = 0.45
  []
[]

[ICs]
  [tau]
    type = FunctionIC
    variable = tau
    function = tau
  []
[]

[UserObjects]
  [phases]
    type = PhaseRegistry
    phases = 'matrix water'
    reference_phase = matrix
    momentum_models = 'reference relative_flux'
  []
[]

[Materials]
  [kinematics]
    type = ADSolidReferenceKinematics
    displacements = 'ux uy'
  []
  [permeability]
    type = ADGenericConstantRankTwoTensor
    tensor_name = test_permeability
    tensor_values = '2 0 0 0 3 0 0 0 4'
  []
  [pressure_gradient]
    type = ADGenericConstantVectorMaterial
    prop_names = test_pressure_gradient
    prop_values = '1 2 0'
  []
  [phase_scalars]
    type = ADGenericConstantMaterial
    prop_names = 'test_intrinsic_density test_bulk_density test_conversion_source test_phase_active test_relative_permeability'
    prop_values = '2 1 0.1 1 0.5'
  []
  [darcy]
    type = ADPhaseTransformingPressureGradientDarcyReferenceFluxMaterial
    phase = water
    phase_registry = phases
    phase_pressure_gradient_name = test_pressure_gradient
    intrinsic_density_source = material
    intrinsic_density_name = test_intrinsic_density
    bulk_density_name = test_bulk_density
    conversion_source_name = test_conversion_source
    phase_active_name = test_phase_active
    relative_permeability_name = test_relative_permeability
    tau = tau
    solid_displacements = 'ux uy'
    permeability_name = test_permeability
    viscosity = 1
    darcy_mobility_ref_name = test_mobility
    combined_resistance_name = test_mean_resistance
    resistance_denominator_name = test_mean_denominator
    combined_resistance_tensor_name = test_resistance_tensor
    resistance_denominator_tensor_name = test_denominator_tensor
    spatial_relative_mass_flux_name = test_spatial_flux
    reference_relative_mass_flux_name = test_reference_flux
  []
[]

[Postprocessors]
  [reference_flux_l2]
    type = ADMaterialVectorL2Error
    property = test_reference_flux
    gradient_function = expected_flux
  []
  [mobility_x_l2]
    type = ADMaterialRankTwoComponentL2Error
    property = test_mobility
    row = 0
    column = 0
    function = mobility_x
  []
  [mobility_y_l2]
    type = ADMaterialRankTwoComponentL2Error
    property = test_mobility
    row = 1
    column = 1
    function = mobility_y
  []
  [mobility_z_l2]
    type = ADMaterialRankTwoComponentL2Error
    property = test_mobility
    row = 2
    column = 2
    function = mobility_z
  []
  [resistance_x_l2]
    type = ADMaterialRankTwoComponentL2Error
    property = test_resistance_tensor
    row = 0
    column = 0
    function = resistance_x
  []
  [resistance_y_l2]
    type = ADMaterialRankTwoComponentL2Error
    property = test_resistance_tensor
    row = 1
    column = 1
    function = resistance_y
  []
  [resistance_z_l2]
    type = ADMaterialRankTwoComponentL2Error
    property = test_resistance_tensor
    row = 2
    column = 2
    function = resistance_z
  []
  [denominator_x_l2]
    type = ADMaterialRankTwoComponentL2Error
    property = test_denominator_tensor
    row = 0
    column = 0
    function = denominator_x
  []
  [denominator_y_l2]
    type = ADMaterialRankTwoComponentL2Error
    property = test_denominator_tensor
    row = 1
    column = 1
    function = denominator_y
  []
  [denominator_z_l2]
    type = ADMaterialRankTwoComponentL2Error
    property = test_denominator_tensor
    row = 2
    column = 2
    function = denominator_z
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
