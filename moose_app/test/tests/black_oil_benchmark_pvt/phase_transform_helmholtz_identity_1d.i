[Mesh]
  type = GeneratedMesh
  dim = 1
  nx = 2
[]

[Variables]
  [dissolved_gas_mass_fraction]
  []
[]

[ICs]
  [dissolved_gas_mass_fraction]
    type = ConstantIC
    variable = dissolved_gas_mass_fraction
    value = 0.15
  []
[]

[Functions]
  [zero]
    type = ParsedFunction
    expression = '0'
  []
  [dissolved_gas_mass_fraction_exact]
    type = ParsedFunction
    expression = '0.2'
  []
  [oil_phase_specific_helmholtz_exact]
    type = ParsedFunction
    expression = '7.5'
  []
  [gas_phase_specific_helmholtz_exact]
    type = ParsedFunction
    expression = '-164993'
  []
  [dissolved_mu_exact]
    type = ParsedFunction
    expression = '9999.5'
  []
  [free_mu_exact]
    type = ParsedFunction
    expression = '10007'
  []
  [affinity_exact]
    type = ParsedFunction
    expression = '-7.5'
  []
  [mass_fraction_rs_derivative_exact]
    type = ParsedFunction
    expression = '0.0016'
  []
[]

[Materials]
  [synthetic_state]
    type = ADGenericConstantMaterial
    prop_names = 'oil_intrinsic_density gas_intrinsic_density oil_bulk_density gas_bulk_density oil_pressure gas_pressure'
    prop_values = '800 40 400 0 8e6 7e6'
  []
  [oil_component_mass_fraction]
    type = ADParsedMaterial
    coupled_variables = dissolved_gas_mass_fraction
    property_name = oil_component_mass_fraction
    expression = '1-dissolved_gas_mass_fraction'
  []
  [undersaturation_gap]
    type = ADParsedMaterial
    coupled_variables = dissolved_gas_mass_fraction
    property_name = undersaturation_gap
    expression = '800*0.3/(2*0.7)-800*dissolved_gas_mass_fraction/(2*(1-dissolved_gas_mass_fraction))'
  []
  [phase_transform_thermodynamics]
    type = ADBlackOilPhaseTransformationThermodynamicsMaterial
    undersaturation_gap_name = undersaturation_gap
    oil_component_mass_fraction_name = oil_component_mass_fraction
    dissolved_gas_mass_fraction_name = dissolved_gas_mass_fraction_property
    oil_intrinsic_density_name = oil_intrinsic_density
    gas_intrinsic_density_name = gas_intrinsic_density
    oil_bulk_density_name = oil_bulk_density
    gas_bulk_density_name = gas_bulk_density
    oil_pressure_name = oil_pressure
    gas_pressure_name = gas_pressure
    solution_gas_oil_ratio_scale = 100
    chemical_stiffness = 100
    oil_surface_density = 800
    gas_surface_density = 2
    oil_reference_specific_helmholtz = 7
    property_prefix = phase_transform
  []
  [dissolved_gas_mass_fraction_property]
    type = ADParsedMaterial
    coupled_variables = dissolved_gas_mass_fraction
    property_name = dissolved_gas_mass_fraction_property
    expression = 'dissolved_gas_mass_fraction'
  []
  [independent_oil_helmholtz]
    type = ADDerivativeParsedMaterial
    coupled_variables = dissolved_gas_mass_fraction
    property_name = independent_oil_helmholtz
    expression = '7+0.5*100*(0.3-dissolved_gas_mass_fraction)^2'
    derivative_order = 1
  []
  [helmholtz_identities]
    type = ADParsedMaterial
    material_property_names = 'dpsi_deta:=dindependent_oil_helmholtz/ddissolved_gas_mass_fraction projected_dpsi_deta:=phase_transform_oil_helmholtz_gas_mass_fraction_derivative psi:=phase_transform_oil_phase_specific_helmholtz independent_oil_helmholtz'
    property_name = helmholtz_derivative_identity
    expression = 'dpsi_deta-projected_dpsi_deta'
  []
  [oil_helmholtz_identity]
    type = ADParsedMaterial
    material_property_names = 'psi:=phase_transform_oil_phase_specific_helmholtz independent_oil_helmholtz'
    property_name = oil_helmholtz_identity
    expression = 'psi-independent_oil_helmholtz'
  []
  [mass_fraction_residual]
    type = ADParsedMaterial
    coupled_variables = dissolved_gas_mass_fraction
    property_name = mass_fraction_residual
    expression = 'dissolved_gas_mass_fraction-0.2'
  []
[]

[Kernels]
  [mass_fraction]
    type = ADMaterialPropertyResidual
    variable = dissolved_gas_mass_fraction
    property = mass_fraction_residual
  []
[]

[Postprocessors]
  [dissolved_gas_mass_fraction_l2]
    type = ElementL2Error
    variable = dissolved_gas_mass_fraction
    function = dissolved_gas_mass_fraction_exact
  []
  [oil_phase_specific_helmholtz_l2]
    type = ADMaterialScalarL2Error
    property = phase_transform_oil_phase_specific_helmholtz
    function = oil_phase_specific_helmholtz_exact
  []
  [gas_phase_specific_helmholtz_l2]
    type = ADMaterialScalarL2Error
    property = phase_transform_gas_phase_specific_helmholtz
    function = gas_phase_specific_helmholtz_exact
  []
  [dissolved_mu_l2]
    type = ADMaterialScalarL2Error
    property = phase_transform_dissolved_gas_neutral_mu
    function = dissolved_mu_exact
  []
  [free_mu_l2]
    type = ADMaterialScalarL2Error
    property = phase_transform_free_gas_neutral_mu
    function = free_mu_exact
  []
  [affinity_l2]
    type = ADMaterialScalarL2Error
    property = phase_transform_dissolved_to_free_affinity
    function = affinity_exact
  []
  [mass_fraction_rs_derivative_l2]
    type = ADMaterialScalarL2Error
    property = phase_transform_dissolved_gas_mass_fraction_rs_derivative
    function = mass_fraction_rs_derivative_exact
  []
  [helmholtz_derivative_identity_l2]
    type = ADMaterialScalarL2Error
    property = helmholtz_derivative_identity
    function = zero
  []
  [oil_helmholtz_identity_l2]
    type = ADMaterialScalarL2Error
    property = oil_helmholtz_identity
    function = zero
  []
  [normalization_residual_l2]
    type = ADMaterialScalarL2Error
    property = phase_transform_mass_fraction_normalization_residual
    function = zero
  []
  [oil_pressure_storage_residual_l2]
    type = ADMaterialScalarL2Error
    property = phase_transform_oil_pressure_storage_residual
    function = zero
  []
  [oil_projection_residual_l2]
    type = ADMaterialScalarL2Error
    property = phase_transform_oil_composition_projection_residual
    function = zero
  []
  [oil_gas_euler_residual_l2]
    type = ADMaterialScalarL2Error
    property = phase_transform_oil_gas_euler_residual
    function = zero
  []
  [gas_pressure_storage_residual_l2]
    type = ADMaterialScalarL2Error
    property = phase_transform_gas_pressure_storage_residual
    function = zero
  []
  [gas_euler_residual_l2]
    type = ADMaterialScalarL2Error
    property = phase_transform_gas_euler_residual
    function = zero
  []
[]

[Executioner]
  type = Steady
  solve_type = NEWTON
[]

[Outputs]
  csv = true
[]
