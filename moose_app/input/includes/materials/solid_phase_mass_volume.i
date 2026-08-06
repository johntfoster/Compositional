[Materials]
  [matrix_mass_and_volume]
    type = ADSolidPhaseMassVolumeMaterial
    reference_component_storage = matrix_reference_component_storage
    # SPE1 provides no grain-density datum. A quartz-like 2650 kg/m^3 is an
    # explicit untuned mechanics/gravity specialization.
    solid_intrinsic_density = 2650
  []
[]
