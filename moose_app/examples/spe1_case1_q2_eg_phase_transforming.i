# Production CG/EG SPE1 acceptance deck with phase-limit-safe manuscript
# conversion resistance and q_f(grad(tau)-v_s) momentum insertion.
!include spe1_case1_q2_eg_transient.i

[Materials]
  [spe1_oil_phase_conversion_source]
    type = ADPhaseConversionSourceMaterial
    reaction_rates = gas_phase_transformation_rate
    phase_stoichiometric_mass_coefficients = '-1'
    phase_current_conversion_source_name = spe1_oil_phase_current_conversion_source
  []
  [spe1_gas_phase_conversion_source]
    type = ADPhaseConversionSourceMaterial
    reaction_rates = gas_phase_transformation_rate
    phase_stoichiometric_mass_coefficients = '1'
    phase_current_conversion_source_name = spe1_gas_phase_current_conversion_source
  []

  [layer_1_oil_darcy]
    type := ADPhaseTransformingDarcyReferenceFluxMaterial
    bulk_density_name = benchmark_black_oil_oil_bulk_phase_density
    conversion_source_name = spe1_oil_phase_current_conversion_source
    phase_active_name = benchmark_black_oil_oil_active
    tau = tau
    tau_enrichment = tau_enrichment
    solid_displacements = 'ux uy uz'
    combined_resistance_name = oil_conversion_corrected_darcy_resistance
    resistance_denominator_name = oil_conversion_corrected_darcy_denominator
    spatial_relative_mass_flux_name = oil_spatial_relative_mass_flux
  []
  [layer_2_oil_darcy]
    type := ADPhaseTransformingDarcyReferenceFluxMaterial
    bulk_density_name = benchmark_black_oil_oil_bulk_phase_density
    conversion_source_name = spe1_oil_phase_current_conversion_source
    phase_active_name = benchmark_black_oil_oil_active
    tau = tau
    tau_enrichment = tau_enrichment
    solid_displacements = 'ux uy uz'
    combined_resistance_name = oil_conversion_corrected_darcy_resistance
    resistance_denominator_name = oil_conversion_corrected_darcy_denominator
    spatial_relative_mass_flux_name = oil_spatial_relative_mass_flux
  []
  [layer_3_oil_darcy]
    type := ADPhaseTransformingDarcyReferenceFluxMaterial
    bulk_density_name = benchmark_black_oil_oil_bulk_phase_density
    conversion_source_name = spe1_oil_phase_current_conversion_source
    phase_active_name = benchmark_black_oil_oil_active
    tau = tau
    tau_enrichment = tau_enrichment
    solid_displacements = 'ux uy uz'
    combined_resistance_name = oil_conversion_corrected_darcy_resistance
    resistance_denominator_name = oil_conversion_corrected_darcy_denominator
    spatial_relative_mass_flux_name = oil_spatial_relative_mass_flux
  []
  [layer_1_gas_darcy]
    type := ADPhaseTransformingDarcyReferenceFluxMaterial
    bulk_density_name = benchmark_black_oil_gas_bulk_phase_density
    conversion_source_name = spe1_gas_phase_current_conversion_source
    phase_active_name = benchmark_black_oil_gas_active
    tau = tau
    tau_enrichment = tau_enrichment
    solid_displacements = 'ux uy uz'
    combined_resistance_name = gas_conversion_corrected_darcy_resistance
    resistance_denominator_name = gas_conversion_corrected_darcy_denominator
    spatial_relative_mass_flux_name = gas_spatial_relative_mass_flux
  []
  [layer_2_gas_darcy]
    type := ADPhaseTransformingDarcyReferenceFluxMaterial
    bulk_density_name = benchmark_black_oil_gas_bulk_phase_density
    conversion_source_name = spe1_gas_phase_current_conversion_source
    phase_active_name = benchmark_black_oil_gas_active
    tau = tau
    tau_enrichment = tau_enrichment
    solid_displacements = 'ux uy uz'
    combined_resistance_name = gas_conversion_corrected_darcy_resistance
    resistance_denominator_name = gas_conversion_corrected_darcy_denominator
    spatial_relative_mass_flux_name = gas_spatial_relative_mass_flux
  []
  [layer_3_gas_darcy]
    type := ADPhaseTransformingDarcyReferenceFluxMaterial
    bulk_density_name = benchmark_black_oil_gas_bulk_phase_density
    conversion_source_name = spe1_gas_phase_current_conversion_source
    phase_active_name = benchmark_black_oil_gas_active
    tau = tau
    tau_enrichment = tau_enrichment
    solid_displacements = 'ux uy uz'
    combined_resistance_name = gas_conversion_corrected_darcy_resistance
    resistance_denominator_name = gas_conversion_corrected_darcy_denominator
    spatial_relative_mass_flux_name = gas_spatial_relative_mass_flux
  []
[]

