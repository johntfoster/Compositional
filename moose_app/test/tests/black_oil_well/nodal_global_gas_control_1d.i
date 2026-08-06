!include nodal_global_oil_control_1d.i

[Postprocessors]
  [gas_surface_rate]
    type = ADElementAverageMaterialProperty
    mat_prop = black_oil_well_gas_surface_rate
    execute_on = 'INITIAL LINEAR TIMESTEP_END'
  []
  [gas_surface_productivity]
    type = ADElementAverageMaterialProperty
    mat_prop = black_oil_well_control_surface_productivity
    execute_on = 'INITIAL LINEAR TIMESTEP_END'
    outputs = none
  []
[]
