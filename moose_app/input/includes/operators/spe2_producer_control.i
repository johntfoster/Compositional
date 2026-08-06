# Each element kernel integrates one completion's AD rate into the shared
# producer_oil_rate_scalar equation. This preserves derivatives through the
# reconstructed P1+P0 pressure and every coupled PVT/saturation field.
[Kernels]
  [spe2_completion_7_oil_rate_constraint]
    type = ADBlackOilCompletionRateConstraint
    variable = oil_pressure
    block = 107
    well_rate = producer_oil_rate_scalar
    surface_rate_name = spe2_completion_7_oil_surface_rate
    completion_reference_volume = 2.802239912627076
    well_rate_fraction = 0.5
  []
  [spe2_completion_8_oil_rate_constraint]
    type = ADBlackOilCompletionRateConstraint
    variable = oil_pressure
    block = 108
    well_rate = producer_oil_rate_scalar
    surface_rate_name = spe2_completion_8_oil_surface_rate
    completion_reference_volume = 2.802239912627076
    well_rate_fraction = 0.5
  []
[]

[ScalarKernels]
  [spe2_producer_rate_equation_coverage]
    # The two element-integrated AD kernels own this scalar equation. The
    # zero scalar object declares that ownership to MOOSE's coverage audit.
    type = NullScalarKernel
    variable = producer_oil_rate_scalar
  []
  [spe2_producer_rate_bhp_complementarity]
    type = ADBlackOilRateBHPComplementarity
    variable = producer_bhp_scalar
    well_rate = producer_oil_rate_scalar
    target_surface_rate = 0
    target_surface_rate_function = spe2_oil_rate_schedule
    apply_bhp_limit = true
    bhp_limit_type = minimum
    bhp_limit = 20684271.879504
  []
[]

[Postprocessors]
  [spe2_completion_7_oil_surface_rate]
    type = ADElementAverageMaterialProperty
    block = 107
    mat_prop = spe2_completion_7_oil_surface_rate
    execute_on = 'INITIAL LINEAR TIMESTEP_END'
  []
  [spe2_completion_8_oil_surface_rate]
    type = ADElementAverageMaterialProperty
    block = 108
    mat_prop = spe2_completion_8_oil_surface_rate
    execute_on = 'INITIAL LINEAR TIMESTEP_END'
  []
  [spe2_completion_7_water_surface_rate]
    type = ADElementAverageMaterialProperty
    block = 107
    mat_prop = spe2_completion_7_water_surface_rate
    execute_on = 'INITIAL LINEAR TIMESTEP_END'
  []
  [spe2_completion_8_water_surface_rate]
    type = ADElementAverageMaterialProperty
    block = 108
    mat_prop = spe2_completion_8_water_surface_rate
    execute_on = 'INITIAL LINEAR TIMESTEP_END'
  []
  [spe2_completion_7_gas_surface_rate]
    type = ADElementAverageMaterialProperty
    block = 107
    mat_prop = spe2_completion_7_gas_surface_rate
    execute_on = 'INITIAL LINEAR TIMESTEP_END'
  []
  [spe2_completion_8_gas_surface_rate]
    type = ADElementAverageMaterialProperty
    block = 108
    mat_prop = spe2_completion_8_gas_surface_rate
    execute_on = 'INITIAL LINEAR TIMESTEP_END'
  []
  [spe2_total_oil_surface_rate]
    type = ScalarVariable
    variable = producer_oil_rate_scalar
  []
  [spe2_datum_bhp]
    type = ScalarVariable
    variable = producer_bhp_scalar
  []
  [spe2_completion_7_bhp]
    type = ADElementAverageMaterialProperty
    block = 107
    mat_prop = spe2_completion_7_effective_bottom_hole_pressure
  []
  [spe2_completion_8_bhp]
    type = ADElementAverageMaterialProperty
    block = 108
    mat_prop = spe2_completion_8_effective_bottom_hole_pressure
  []
[]
