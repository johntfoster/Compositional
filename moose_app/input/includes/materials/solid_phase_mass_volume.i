[Materials]
  [matrix_mass_and_volume]
    type = ADSolidPhaseMassVolumeMaterial
    solid_volume_fraction = matrix_volume_fraction
    fluid_volume_fraction = porosity
    # A constant density factors from the source-free balance, so rho_s=1
    # stores and conserves the normalized matrix constituent J phi_s.
    solid_intrinsic_density = 1
  []
[]
