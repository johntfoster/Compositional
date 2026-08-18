# Cell-centered, phase-upwind SPE1 Case 1 benchmark path in SI units.
!include spe1_case1_fixed_skeleton_transient.i

[Variables]
  active = 'oil_pressure solution_gas_oil_ratio water_saturation gas_saturation injector_bhp_scalar producer_bhp_scalar'
[]

[Materials]
  active = 'reference_kinematics reference_inverse reference_jacobian_inverse fixed_skeleton_porosity oil_pressure_reconstruction water_saturation_reconstruction gas_saturation_reconstruction spe1_pvt spe1_relative_permeability zero_component_fraction inactive_well_sources injector_zero_relative_permeability injector_gas_relative_permeability injector producer spe1_permeability_high spe1_permeability_low spe1_permeability_middle'
  [fixed_skeleton_porosity]
    type = ADGenericConstantMaterial
    prop_names = 'solid_current_porosity solid_current_porosity_dot'
    prop_values = '0.3 0'
  []
  [injector_zero_relative_permeability]
    type = ADGenericConstantMaterial
    block = 11
    prop_names = 'injector_water_relative_permeability injector_oil_relative_permeability'
    prop_values = '0 0'
  []
  [injector_gas_relative_permeability]
    type = ADParsedMaterial
    block = 11
    material_property_names = black_oil_gas_relative_permeability
    property_name = injector_gas_relative_permeability
    # Bootstrap the initially absent gas phase without replacing the official
    # SGOF mobility after gas appears in the injection completion.
    expression = '0.5*(black_oil_gas_relative_permeability+0.1+sqrt((black_oil_gas_relative_permeability-0.1)^2+1e-8))'
  []
  [spe1_permeability_high]
    type = ADGenericConstantMaterial
    block = '1 11'
    prop_names = spe1_absolute_permeability
    prop_values = 4.9346165e-13
  []
  [spe1_permeability_low]
    type = ADGenericConstantMaterial
    block = 2
    prop_names = spe1_absolute_permeability
    prop_values = 4.9346165e-14
  []
  [spe1_permeability_middle]
    type = ADGenericConstantMaterial
    block = '3 13'
    prop_names = spe1_absolute_permeability
    prop_values = 1.9738466e-13
  []
[]

[Kernels]
  active = ''
[]

[DGKernels]
  active = ''
[]

[ScalarKernels]
  active = 'injector_scalar_coverage producer_scalar_coverage'
  [injector_scalar_coverage]
    type = NullScalarKernel
    variable = injector_bhp_scalar
    jacobian_fill = 0
  []
  [producer_scalar_coverage]
    type = NullScalarKernel
    variable = producer_bhp_scalar
    jacobian_fill = 0
  []
[]

[FVKernels]
  [dissolved_gas_history]
    # SPE1 Case 1 prescribes DRSDT=0: pressure-driven exsolution may reduce
    # dissolved gas, but later pressure recovery cannot redissolve free gas.
    type = FVMaterialPropertyResidual
    variable = solution_gas_oil_ratio
    property = benchmark_black_oil_gas_appearance_complementarity_residual
  []
  [water_storage]
    type = FVBlackOilComponentBalance
    variable = water_saturation
    reference_component_storage_rate_name = benchmark_black_oil_water_reference_component_storage_rate
    reference_component_source_name = spe1_well_water_reference_component_source
  []
  [oil_storage]
    type = FVBlackOilComponentBalance
    variable = oil_pressure
    reference_component_storage_rate_name = benchmark_black_oil_oil_reference_component_storage_rate
    reference_component_source_name = spe1_well_oil_reference_component_source
  []
  [gas_storage]
    type = FVBlackOilComponentBalance
    variable = gas_saturation
    reference_component_storage_rate_name = benchmark_black_oil_gas_reference_component_storage_rate
    reference_component_source_name = spe1_well_gas_reference_component_source
  []

  [water_flux]
    type = FVBlackOilPhaseUpwindComponentFlux
    variable = water_saturation
    phase_pressure_names = 'spe1_oil_pressure_total spe1_oil_pressure_total spe1_oil_pressure_total'
    phase_intrinsic_density_names = 'benchmark_black_oil_oil_intrinsic_density benchmark_black_oil_gas_intrinsic_density benchmark_black_oil_water_intrinsic_density'
    phase_viscosity_names = 'benchmark_black_oil_oil_viscosity benchmark_black_oil_gas_viscosity benchmark_black_oil_water_viscosity'
    phase_relative_permeability_names = 'black_oil_oil_relative_permeability black_oil_gas_relative_permeability black_oil_water_relative_permeability'
    phase_component_mass_fraction_names = 'zero_component_fraction zero_component_fraction benchmark_black_oil_water_component_mass_fraction_in_water'
    permeability_name = spe1_absolute_permeability
    gravity = '0 0 9.80665'
  []
  [oil_flux]
    type = FVBlackOilPhaseUpwindComponentFlux
    variable = oil_pressure
    phase_pressure_names = 'spe1_oil_pressure_total spe1_oil_pressure_total spe1_oil_pressure_total'
    phase_intrinsic_density_names = 'benchmark_black_oil_oil_intrinsic_density benchmark_black_oil_gas_intrinsic_density benchmark_black_oil_water_intrinsic_density'
    phase_viscosity_names = 'benchmark_black_oil_oil_viscosity benchmark_black_oil_gas_viscosity benchmark_black_oil_water_viscosity'
    phase_relative_permeability_names = 'black_oil_oil_relative_permeability black_oil_gas_relative_permeability black_oil_water_relative_permeability'
    phase_component_mass_fraction_names = 'benchmark_black_oil_oil_component_mass_fraction_in_oil zero_component_fraction zero_component_fraction'
    permeability_name = spe1_absolute_permeability
    gravity = '0 0 9.80665'
  []
  [gas_flux]
    type = FVBlackOilPhaseUpwindComponentFlux
    variable = gas_saturation
    phase_pressure_names = 'spe1_oil_pressure_total spe1_oil_pressure_total spe1_oil_pressure_total'
    phase_intrinsic_density_names = 'benchmark_black_oil_oil_intrinsic_density benchmark_black_oil_gas_intrinsic_density benchmark_black_oil_water_intrinsic_density'
    phase_viscosity_names = 'benchmark_black_oil_oil_viscosity benchmark_black_oil_gas_viscosity benchmark_black_oil_water_viscosity'
    phase_relative_permeability_names = 'black_oil_oil_relative_permeability black_oil_gas_relative_permeability black_oil_water_relative_permeability'
    phase_component_mass_fraction_names = 'benchmark_black_oil_gas_component_mass_fraction_in_oil benchmark_black_oil_gas_component_mass_fraction_in_gas zero_component_fraction'
    permeability_name = spe1_absolute_permeability
    gravity = '0 0 9.80665'
  []

  [injector_control]
    type = FVBlackOilWellControl
    variable = oil_pressure
    block = 11
    bottom_hole_pressure = injector_bhp_scalar
    surface_rate_name = spe1_well_gas_surface_rate
    target_surface_rate = -32.774128
    apply_bhp_limit = true
    bhp_limit_type = maximum
    bhp_limit = 62149342.24061635
  []
  [producer_control]
    type = FVBlackOilWellControl
    variable = oil_pressure
    block = 13
    bottom_hole_pressure = producer_bhp_scalar
    surface_rate_name = spe1_well_oil_surface_rate
    target_surface_rate = 0.03680261456666667
    apply_bhp_limit = true
    bhp_limit_type = minimum
    bhp_limit = 6894757.293168
  []
[]
