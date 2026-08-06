# SPE2 completion well indices use
#   WI = 2*pi*(kh)/(ln(r_e/r_w)+skin),
# with r_e=0.84 ft, r_w=0.25 ft, and the published kh values 6200 and
# 480 md-ft. The completion reference volume is the exact first-cell annular
# volume pi*(2^2-0.25^2)*8 ft^3 converted to SI.
[Materials]
  [spe2_completion_7_well]
    type = ADBlackOilPeacemanWellMaterial
    block = 107
    pressure_source = material
    water_pressure_name = spe2_water_pressure
    oil_pressure_name = spe2_oil_pressure_total
    gas_pressure_name = spe2_gas_pressure
    mobility_source = relative_permeability_viscosity
    water_relative_permeability_name = spe2_black_oil_water_relative_permeability
    oil_relative_permeability_name = spe2_black_oil_oil_relative_permeability
    gas_relative_permeability_name = spe2_black_oil_gas_relative_permeability
    water_viscosity_name = benchmark_black_oil_water_viscosity
    oil_viscosity_name = benchmark_black_oil_oil_viscosity
    gas_viscosity_name = benchmark_black_oil_gas_viscosity
    water_fvf_name = benchmark_black_oil_water_formation_volume_factor
    oil_fvf_name = benchmark_black_oil_oil_formation_volume_factor
    gas_fvf_name = benchmark_black_oil_gas_formation_volume_factor
    solution_gas_oil_ratio_name = benchmark_black_oil_solution_gas_oil_ratio
    well_index = 9.669153485643503e-12
    control_mode = scalar_bhp
    bottom_hole_pressure_variable = producer_bhp_scalar
    target_surface_rate = 0
    apply_datum_correction = true
    wellbore_density_source = material
    wellbore_density_name = benchmark_black_oil_oil_intrinsic_density
    completion_depth = 2776.728
    bhp_datum_depth = 2776.728
    gravity_magnitude = 9.80665
    completion_reference_volume = 2.802239912627076
    water_surface_density = 1009.4835618269682
    oil_surface_density = 720.8308518282064
    gas_surface_density = 1.124496128852002
    property_prefix = spe2_completion_7
  []
  [spe2_completion_8_well]
    type = ADBlackOilPeacemanWellMaterial
    block = 108
    pressure_source = material
    water_pressure_name = spe2_water_pressure
    oil_pressure_name = spe2_oil_pressure_total
    gas_pressure_name = spe2_gas_pressure
    mobility_source = relative_permeability_viscosity
    water_relative_permeability_name = spe2_black_oil_water_relative_permeability
    oil_relative_permeability_name = spe2_black_oil_oil_relative_permeability
    gas_relative_permeability_name = spe2_black_oil_gas_relative_permeability
    water_viscosity_name = benchmark_black_oil_water_viscosity
    oil_viscosity_name = benchmark_black_oil_oil_viscosity
    gas_viscosity_name = benchmark_black_oil_gas_viscosity
    water_fvf_name = benchmark_black_oil_water_formation_volume_factor
    oil_fvf_name = benchmark_black_oil_oil_formation_volume_factor
    gas_fvf_name = benchmark_black_oil_gas_formation_volume_factor
    solution_gas_oil_ratio_name = benchmark_black_oil_solution_gas_oil_ratio
    well_index = 7.485796246949808e-13
    control_mode = scalar_bhp
    bottom_hole_pressure_variable = producer_bhp_scalar
    target_surface_rate = 0
    apply_datum_correction = true
    wellbore_density_source = material
    wellbore_density_name = benchmark_black_oil_oil_intrinsic_density
    completion_depth = 2779.1664
    bhp_datum_depth = 2776.728
    gravity_magnitude = 9.80665
    completion_reference_volume = 2.802239912627076
    water_surface_density = 1009.4835618269682
    oil_surface_density = 720.8308518282064
    gas_surface_density = 1.124496128852002
    property_prefix = spe2_completion_8
  []
[]
