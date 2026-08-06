# P2 CG projection rows for the independently assembled water/oil and gas/oil
# pressure identities. These are constitutive closure equations, not transport.
[Kernels]
  [spe2_water_oil_pressure_difference_closure]
    type = ADMaterialPropertyResidual
    variable = water_oil_pressure_difference
    property = spe2_phase_pressure_water_pressure_difference_closure_residual
  []
  [spe2_gas_oil_pressure_difference_closure]
    type = ADMaterialPropertyResidual
    variable = gas_oil_pressure_difference
    property = spe2_phase_pressure_gas_pressure_difference_closure_residual
  []
[]
