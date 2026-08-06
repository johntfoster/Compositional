# Pick-and-choose transforming-phase momentum template.
# Required: pressure, tau, solid displacement, density, conversion source.
# Optional families: pressure offset, acceleration, electrical/Maxwell force.
[Materials]
  [transforming_phase_conversion_source]
    type = ADPhaseConversionSourceMaterial
    reaction_rates = 'reaction_rate_0'
    phase_stoichiometric_mass_coefficients = '1'
    phase_current_conversion_source_name = transforming_phase_q
  []
  [transforming_phase_darcy]
    type = ADPhaseTransformingDarcyReferenceFluxMaterial
    phase = fluid
    phase_registry = phases
    pressure = pressure
    pressure_enrichment = pressure_enrichment
    intrinsic_density_source = material
    intrinsic_density_name = fluid_intrinsic_density
    bulk_density_name = fluid_bulk_density
    conversion_source_name = transforming_phase_q
    phase_active_name = fluid_active
    tau = tau
    tau_enrichment = tau_enrichment
    solid_displacements = 'ux uy uz'
    permeability = 1e-12
    viscosity_name = fluid_viscosity
    relative_permeability_name = fluid_relative_permeability
    gravity = '0 0 -9.80665'
    # Optional pressure offset (capillarity, electrical enthalpy, or dynamic lag):
    # include_capillary_pressure = true
    # capillary_pressure = fluid_pressure_offset
    # capillary_pressure_enrichment = fluid_pressure_offset_enrichment
    # capillary_pressure_scale = 1
    # Optional inertia:
    # include_acceleration = true
    # phase_acceleration = 'fluid_acceleration_x fluid_acceleration_y fluid_acceleration_z'
    # Optional div(phi E tensor d) force assembled by a separate electrical object:
    # include_electrical_force = true
    # electrical_force_name = fluid_maxwell_force
    darcy_mobility_ref_name = fluid_conversion_corrected_pressure_mobility
    combined_resistance_name = fluid_conversion_corrected_resistance
    resistance_denominator_name = fluid_conversion_corrected_denominator
    spatial_relative_mass_flux_name = fluid_spatial_relative_mass_flux
    reference_relative_mass_flux_name = fluid_reference_relative_mass_flux
  []
[]
