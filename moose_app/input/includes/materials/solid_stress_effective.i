[Materials]
  [effective_stress]
    type = ADCompressibleNeoHookeanReferenceStressMaterial
    shear_modulus = ${solid_shear_modulus}
    lame_lambda = ${solid_lame_lambda}
  []
  [total_stress]
    type = ADReferenceSolidStressMaterial
    biot_coefficient = 0
  []
[]
