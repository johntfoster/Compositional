# Use this type for phase-appearance/disappearance models. It retains the
# manuscript active-phase closure and returns zero flux when rho_f or k_rf vanishes.
[Materials]
  [transforming_phase_darcy]
    type = ADPhaseTransformingDarcyReferenceFluxMaterial
    phase = fluid
    phase_registry = phases
    pressure = pressure
    pressure_enrichment = pressure_enrichment
    intrinsic_density_source = material
    intrinsic_density_name = fluid_intrinsic_density
    bulk_density_name = fluid_bulk_density
    conversion_source_name = fluid_phase_current_conversion_source
    phase_active_name = fluid_active
    tau = tau
    tau_enrichment = tau_enrichment
    solid_displacements = 'ux uy uz'
    permeability = 1e-12
    viscosity_name = fluid_viscosity
    relative_permeability_name = fluid_relative_permeability
    gravity = '0 0 -9.80665'
    darcy_mobility_ref_name = fluid_conversion_corrected_pressure_mobility
    combined_resistance_name = fluid_conversion_corrected_resistance
    resistance_denominator_name = fluid_conversion_corrected_denominator
    spatial_relative_mass_flux_name = fluid_spatial_relative_mass_flux
    reference_relative_mass_flux_name = fluid_reference_relative_mass_flux
  []
[]

