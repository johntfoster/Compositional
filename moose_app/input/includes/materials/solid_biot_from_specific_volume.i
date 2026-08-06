[Materials]
  [solid_biot]
    type = ADSkeletonSpecificVolumeBiotMaterial
    intrinsic_specific_volume_name = ${solid_intrinsic_specific_volume_name}
    reference_specific_volume = ${solid_reference_specific_volume}
    jacobian_symbol = ${solid_biot_jacobian_symbol}
    fixed_pressure_symbol = ${solid_biot_fixed_pressure_symbol}
    biot_coefficient_name = ${solid_biot_coefficient_name}
  []
[]
