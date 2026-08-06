!include peaceman_bhp_component_sources_1d.i

[Functions]
  [free_gas_surface_rate_exact]
    type = ParsedFunction
    expression = '360'
  []
  [free_gas_source_exact]
    type = ParsedFunction
    expression = '-43.2'
  []
[]

[Postprocessors]
  active = 'free_gas_surface_rate_l2 free_gas_source_l2'
  [free_gas_surface_rate_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_well_free_gas_surface_rate
    function = free_gas_surface_rate_exact
    execute_on = INITIAL
  []
  [free_gas_source_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_well_free_gas_reference_component_source
    function = free_gas_source_exact
    execute_on = INITIAL
  []
[]
