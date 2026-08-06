!include spe1_transient_storage_rates_1d.i

[Functions]
  [oil_pressure_initial_spatial]
    type = ParsedFunction
    expression = '4800+10*x'
  []
  [solution_gas_oil_ratio_initial_spatial]
    type = ParsedFunction
    expression = '1.27+0.000348*(4800+10*x-4014.7)'
  []
  [zero]
    type = ParsedFunction
    expression = '0'
  []
[]

[AuxVariables]
  [water_storage_rate_aux]
    family = MONOMIAL
    order = CONSTANT
  []
  [oil_storage_rate_aux]
    family = MONOMIAL
    order = CONSTANT
  []
  [gas_storage_rate_aux]
    family = MONOMIAL
    order = CONSTANT
  []
  [water_source_aux]
    family = MONOMIAL
    order = CONSTANT
  []
  [oil_source_aux]
    family = MONOMIAL
    order = CONSTANT
  []
  [gas_source_aux]
    family = MONOMIAL
    order = CONSTANT
  []
[]

[UserObjects]
  [phases]
    type = PhaseRegistry
    phases = 'matrix oil gas water'
    reference_phase = matrix
    momentum_models = 'reference relative_flux relative_flux relative_flux'
  []
[]

[Materials]
  [solid_reference_inverse]
    type = ADGenericConstantRankTwoTensor
    tensor_name = solid_reference_F_inv
    tensor_values = '1 0 0 0 1 0 0 0 1'
  []
  [solid_reference_jacobian_inverse]
    type = ADGenericConstantRankTwoTensor
    tensor_name = solid_reference_J_F_inv
    tensor_values = '1 0 0 0 1 0 0 0 1'
  []
  [relative_permeability]
    type = ADBlackOilRelativePermeabilityMaterial
    water_saturation = water_saturation
    gas_saturation = gas_saturation
    water_saturation_points = '0.12 0.3 1'
    water_relative_permeability_values = '0 0.02 1e-5'
    oil_water_relative_permeability_values = '1 0.98 0'
    gas_saturation_points = '0 0.1 0.88'
    gas_relative_permeability_values = '0 0.005 0.984'
    oil_gas_relative_permeability_values = '1 0.99 0'
  []
  [completion_state]
    type = ADGenericConstantMaterial
    prop_names = 'black_oil_water_pressure black_oil_oil_pressure black_oil_gas_pressure black_oil_water_well_mobility black_oil_oil_well_mobility black_oil_gas_well_mobility'
    prop_values = '4800 4800 4800 0.01 0.1 0.1'
  []
  [water_darcy]
    type = ADStandardDarcyReferenceFluxMaterial
    phase = water
    phase_registry = phases
    pressure = oil_pressure
    intrinsic_density_source = material
    intrinsic_density_name = benchmark_black_oil_water_intrinsic_density
    permeability = 1e-6
    viscosity_name = benchmark_black_oil_water_viscosity
    relative_permeability_name = black_oil_water_relative_permeability
    darcy_mobility_ref_name = water_darcy_mobility
    reference_relative_mass_flux_name = water_reference_relative_mass_flux
  []
  [oil_darcy]
    type = ADStandardDarcyReferenceFluxMaterial
    phase = oil
    phase_registry = phases
    pressure = oil_pressure
    intrinsic_density_source = material
    intrinsic_density_name = benchmark_black_oil_oil_intrinsic_density
    permeability = 1e-6
    viscosity_name = benchmark_black_oil_oil_viscosity
    relative_permeability_name = black_oil_oil_relative_permeability
    darcy_mobility_ref_name = oil_darcy_mobility
    reference_relative_mass_flux_name = oil_reference_relative_mass_flux
  []
  [gas_darcy]
    type = ADStandardDarcyReferenceFluxMaterial
    phase = gas
    phase_registry = phases
    pressure = oil_pressure
    intrinsic_density_source = material
    intrinsic_density_name = benchmark_black_oil_gas_intrinsic_density
    permeability = 1e-6
    viscosity_name = benchmark_black_oil_gas_viscosity
    relative_permeability_name = black_oil_gas_relative_permeability
    darcy_mobility_ref_name = gas_darcy_mobility
    reference_relative_mass_flux_name = gas_reference_relative_mass_flux
  []
  [zero_component_fraction]
    type = ADGenericConstantMaterial
    prop_names = zero_component_fraction
    prop_values = '0'
  []
  [water_component_flux]
    type = ADRegisteredPhaseComponentFluxMaterial
    phase_registry = phases
    phases = 'oil gas water'
    component = 0
    phase_reference_relative_mass_flux_names = 'oil_reference_relative_mass_flux gas_reference_relative_mass_flux water_reference_relative_mass_flux'
    phase_component_mass_fraction_names = 'zero_component_fraction zero_component_fraction benchmark_black_oil_water_component_mass_fraction_in_water'
    reference_component_flux_name = water_reference_component_flux
    reference_component_source_name = unused_water_source
  []
  [oil_component_flux]
    type = ADRegisteredPhaseComponentFluxMaterial
    phase_registry = phases
    phases = 'oil gas water'
    component = 1
    phase_reference_relative_mass_flux_names = 'oil_reference_relative_mass_flux gas_reference_relative_mass_flux water_reference_relative_mass_flux'
    phase_component_mass_fraction_names = 'benchmark_black_oil_oil_component_mass_fraction_in_oil zero_component_fraction zero_component_fraction'
    reference_component_flux_name = oil_reference_component_flux
    reference_component_source_name = unused_oil_source
  []
  [gas_component_flux]
    type = ADRegisteredPhaseComponentFluxMaterial
    phase_registry = phases
    phases = 'oil gas water'
    component = 2
    phase_reference_relative_mass_flux_names = 'oil_reference_relative_mass_flux gas_reference_relative_mass_flux water_reference_relative_mass_flux'
    phase_component_mass_fraction_names = 'benchmark_black_oil_gas_component_mass_fraction_in_oil benchmark_black_oil_gas_component_mass_fraction_in_gas zero_component_fraction'
    reference_component_flux_name = gas_reference_component_flux
    reference_component_source_name = unused_gas_source
  []
  [gas_injector]
    type = ADBlackOilPeacemanWellMaterial
    water_pressure_name = black_oil_water_pressure
    oil_pressure_name = black_oil_oil_pressure
    gas_pressure_name = black_oil_gas_pressure
    water_mobility_name = black_oil_water_well_mobility
    oil_mobility_name = black_oil_oil_well_mobility
    gas_mobility_name = black_oil_gas_well_mobility
    water_fvf_name = benchmark_black_oil_water_formation_volume_factor
    oil_fvf_name = benchmark_black_oil_oil_formation_volume_factor
    gas_fvf_name = benchmark_black_oil_gas_formation_volume_factor
    solution_gas_oil_ratio_name = benchmark_black_oil_saturated_solution_gas_oil_ratio
    well_index = 1
    control_mode = gas_surface_rate
    injection_phase = gas
    target_surface_rate = -1e-4
    completion_reference_volume = 1
    water_surface_density = 64.49
    oil_surface_density = 53.66
    gas_surface_density = 0.0533
  []
[]

[Kernels]
  [water_balance]
    source_name = black_oil_well_water_reference_component_source
    reference_flux_name = water_reference_component_flux
  []
  [oil_balance]
    source_name = black_oil_well_oil_reference_component_source
    reference_flux_name = oil_reference_component_flux
  []
  [oil_enrichment_balance]
    source_name = black_oil_well_oil_reference_component_source
  []
  [gas_balance]
    source_name = black_oil_well_gas_reference_component_source
    reference_flux_name = gas_reference_component_flux
  []
[]

[AuxKernels]
  [water_storage_rate_aux_kernel]
    type = ADMaterialRealAux
    variable = water_storage_rate_aux
    property = benchmark_black_oil_water_reference_component_storage_rate
    execute_on = TIMESTEP_END
  []
  [oil_storage_rate_aux_kernel]
    type = ADMaterialRealAux
    variable = oil_storage_rate_aux
    property = benchmark_black_oil_oil_reference_component_storage_rate
    execute_on = TIMESTEP_END
  []
  [gas_storage_rate_aux_kernel]
    type = ADMaterialRealAux
    variable = gas_storage_rate_aux
    property = benchmark_black_oil_gas_reference_component_storage_rate
    execute_on = TIMESTEP_END
  []
  [water_source_aux_kernel]
    type = ADMaterialRealAux
    variable = water_source_aux
    property = black_oil_well_water_reference_component_source
    execute_on = TIMESTEP_END
  []
  [oil_source_aux_kernel]
    type = ADMaterialRealAux
    variable = oil_source_aux
    property = black_oil_well_oil_reference_component_source
    execute_on = TIMESTEP_END
  []
  [gas_source_aux_kernel]
    type = ADMaterialRealAux
    variable = gas_source_aux
    property = black_oil_well_gas_reference_component_source
    execute_on = TIMESTEP_END
  []
[]

[Postprocessors]
  inactive = 'oil_pressure_l2 solution_gas_oil_ratio_l2 water_saturation_l2 gas_saturation_l2 water_storage_rate_l2 oil_storage_rate_l2 gas_storage_rate_l2'

  [water_storage_rate_integral]
    type = ElementIntegralVariablePostprocessor
    variable = water_storage_rate_aux
  []
  [oil_storage_rate_integral]
    type = ElementIntegralVariablePostprocessor
    variable = oil_storage_rate_aux
  []
  [gas_storage_rate_integral]
    type = ElementIntegralVariablePostprocessor
    variable = gas_storage_rate_aux
  []
  [water_source_integral]
    type = ElementIntegralVariablePostprocessor
    variable = water_source_aux
  []
  [oil_source_integral]
    type = ElementIntegralVariablePostprocessor
    variable = oil_source_aux
  []
  [gas_source_integral]
    type = ElementIntegralVariablePostprocessor
    variable = gas_source_aux
  []
  [water_left_flux]
    type = ADSideIntegralMaterialProperty
    boundary = left
    property = water_reference_component_flux
    component = 0
  []
  [water_right_flux]
    type = ADSideIntegralMaterialProperty
    boundary = right
    property = water_reference_component_flux
    component = 0
  []
  [oil_left_flux]
    type = ADSideIntegralMaterialProperty
    boundary = left
    property = oil_reference_component_flux
    component = 0
  []
  [oil_right_flux]
    type = ADSideIntegralMaterialProperty
    boundary = right
    property = oil_reference_component_flux
    component = 0
  []
  [gas_left_flux]
    type = ADSideIntegralMaterialProperty
    boundary = left
    property = gas_reference_component_flux
    component = 0
  []
  [gas_right_flux]
    type = ADSideIntegralMaterialProperty
    boundary = right
    property = gas_reference_component_flux
    component = 0
  []
  [water_global_balance]
    type = LinearCombinationPostprocessor
    pp_names = 'water_storage_rate_integral water_source_integral'
    pp_coefs = '1 -1'
  []
  [oil_global_balance]
    type = LinearCombinationPostprocessor
    pp_names = 'oil_storage_rate_integral oil_source_integral'
    pp_coefs = '1 -1'
  []
  [gas_global_balance]
    type = LinearCombinationPostprocessor
    pp_names = 'gas_storage_rate_integral gas_source_integral'
    pp_coefs = '1 -1'
  []
  [water_component_flux_l2]
    type = ADMaterialVectorL2Error
    property = water_reference_component_flux
    gradient_function = zero
  []
  [oil_component_flux_l2]
    type = ADMaterialVectorL2Error
    property = oil_reference_component_flux
    gradient_function = zero
  []
  [gas_component_flux_l2]
    type = ADMaterialVectorL2Error
    property = gas_reference_component_flux
    gradient_function = zero
  []
[]
