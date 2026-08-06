[Materials]
  [effective_stress]
    type = ADCompressibleNeoHookeanReferenceStressMaterial
    shear_modulus = ${solid_shear_modulus}
    lame_lambda = ${solid_lame_lambda}
  []
  [total_stress]
    type = ADReferenceSolidStressMaterial
    equivalent_pressure = equivalent_pressure
    equivalent_pressure_enrichment = equivalent_pressure_enr
    biot_coefficient_name = ${solid_biot_coefficient_name}
  []
[]
