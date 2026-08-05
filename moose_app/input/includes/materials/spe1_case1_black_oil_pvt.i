# Official SPE1 Case 1 PVTW, PVDG, PVTO, DENSITY, SWOF, and SGOF data in SI units.
[Materials]
  [spe1_pvt]
    type = ADBlackOilBenchmarkPVTMaterial
    compute_storage_rates = true
    use_pressure_dependent_rock_porosity = ${spe1_use_pressure_dependent_rock_porosity}
    # ROCK reference pressure: 14.7 psia.
    rock_reference_pressure = 101352.9322095696
    rock_compressibility = 4.351132216757741e-10
    oil_pressure_name = spe1_oil_pressure_total
    oil_pressure_rate_name = spe1_oil_pressure_total_dot
    solution_gas_oil_ratio = solution_gas_oil_ratio
    porosity = porosity
    water_saturation_name = spe1_water_saturation_total
    water_saturation_rate_name = spe1_water_saturation_total_dot
    gas_saturation_name = spe1_gas_saturation_total
    gas_saturation_rate_name = spe1_gas_saturation_total_dot
    reject_oversaturated_state = false
    # Bound nonlinear trial pressures to the official table interval while
    # retaining the unmodified converged solution inside that interval.
    out_of_range_policy = clamp
    # SPE1 Case 1 prescribes DRSDT=0.  Free gas therefore retains the
    # undersaturated PVTO history branch instead of forcing saturated PVTO.
    equilibrate_solution_gas_with_free_gas = false
    solution_gas_oil_ratio_scale = 226.19666048237477
    maximum_solution_gas_oil_ratio = 226.19666048237477
    solution_gas_transition_width = 0.5
    enforce_nonincreasing_solution_gas = true
    water_reference_pressure = 27700032.163167097
    water_reference_fvf = 1.038
    water_compressibility = 4.670215154912982e-10
    water_reference_viscosity = 0.000318
    water_viscosibility = 0
    gas_pressure_points = '101352.9322095696 1825042.2555015695 3548731.57879357 6996110.22537757 13890867.51854557 17338246.16512957 20785624.81171357 27680382.104881566 34575139.39804956 62154168.570721574'
    gas_fvf_values = '0.9357601458333333 0.06789715625 0.03522589583333333 0.017949822916666667 0.0090619375 0.007265270833333334 0.00606375 0.004553427083333334 0.0036438645833333336 0.0021672291666666667'
    gas_viscosity_values = '8e-6 9.6e-6 1.12e-5 1.4e-5 1.89e-5 2.08e-5 2.28e-5 2.68e-5 3.09e-5 4.7e-5'
    oil_solution_gas_oil_ratio_points = '0.17810760667903527 16.11873840445269 32.05936920222634 66.07792207792208 113.27643784786642 138.03339517625233 165.6400742115028 226.19666048237477 288.1781076066791'
    oil_bubble_pressure_points = '101352.9322095696 1825042.2555015695 3548731.57879357 6996110.22537757 13890867.51854557 17338246.16512957 20785624.81171357 27680382.104881566 34575139.39804956'
    oil_branch_offsets = '0 1 2 3 4 5 6 7 9 11'
    oil_pressure_points = '101352.9322095696 1825042.2555015695 3548731.57879357 6996110.22537757 13890867.51854557 17338246.16512957 20785624.81171357 27680382.104881566 62154168.570721574 34575139.39804956 62154168.570721574'
    oil_fvf_values = '1.062 1.15 1.207 1.295 1.435 1.5 1.565 1.695 1.579 1.827 1.737'
    oil_viscosity_values = '0.00104 0.000975 0.00091 0.00083 0.000695 0.000641 0.000594 0.00051 0.00074 0.000449 0.000631'
    saturated_oil_fvf_values = '1.062 1.15 1.207 1.295 1.435 1.5 1.565 1.695 1.827'
    saturated_oil_viscosity_values = '0.00104 0.000975 0.00091 0.00083 0.000695 0.000641 0.000594 0.00051 0.000449'
    water_surface_density = 1033.0307029866894
    oil_surface_density = 859.5507446467011
    gas_surface_density = 0.8537840978320755
  []

  [spe1_relative_permeability]
    type = ADBlackOilRelativePermeabilityMaterial
    water_saturation_name = spe1_water_saturation_total
    gas_saturation_name = spe1_gas_saturation_total
    water_saturation_points = '0.12 0.18 0.24 0.30 0.36 0.42 0.48 0.54 0.60 0.66 0.72 0.78 0.84 0.91 1.0'
    water_relative_permeability_values = '0 4.64876033057851e-8 1.86e-7 4.18388429752066e-7 7.43801652892562e-7 1.16219008264463e-6 1.67355371900826e-6 2.27789256198347e-6 2.97520661157025e-6 3.7654958677686e-6 4.64876033057851e-6 5.625e-6 6.69421487603306e-6 8.05914256198347e-6 1e-5'
    oil_water_relative_permeability_values = '1 1 0.997 0.98 0.7 0.35 0.2 0.09 0.021 0.01 0.001 0.0001 0 0 0'
    gas_saturation_points = '0 0.001 0.02 0.05 0.12 0.2 0.25 0.3 0.4 0.45 0.5 0.6 0.7 0.85 0.88'
    gas_relative_permeability_values = '0 0 0 0.005 0.025 0.075 0.125 0.19 0.41 0.6 0.72 0.87 0.94 0.98 0.984'
    oil_gas_relative_permeability_values = '1 1 0.997 0.98 0.7 0.35 0.2 0.09 0.021 0.01 0.001 0.0001 0 0 0'
  []
[]
