[Mesh]
  type = GeneratedMesh
  dim = 2
  nx = 1
  ny = 1
[]

[Problem]
  solve = false
[]

[Functions]
  [flux0_exact]
    type = ParsedFunction
    expression = '-2.15*x+0.375*y'
  []
  [flux1_exact]
    type = ParsedFunction
    expression = '-1.2*x-2.35*y'
  []
  [reference_flux_exact]
    type = ParsedFunction
    expression = '3.35*x+1.975*y'
  []
  [zero_vector]
    type = ConstantFunction
    value = 0
  []
  [zero]
    type = ConstantFunction
    value = 0
  []
  [minimum_pivot_exact]
    type = ConstantFunction
    value = 0.98
  []
  [power_exact]
    type = ConstantFunction
    value = 7.825
  []
  [entropy_exact]
    type = ConstantFunction
    value = 0.025
  []
[]

[Materials]
  [forces]
    type = ADGenericConstantVectorMaterial
    prop_names = 'force0 force1'
    prop_values = '1 -1 0  0.5 2 0'
  []
  [temperature]
    type = ADGenericConstantMaterial
    prop_names = temperature
    prop_values = 313
  []
  [onsager]
    type = ADMulticomponentOnsagerFluxMaterial
    transport_force_names = 'force0 force1'
    mobility_tensor_entries = '2 0.2  0.2 1
                               0.3 0.1  0.05 0.2
                               0.3 0.05  0.1 0.2
                               1.5 0.1  0.1 1.2'
    component_flux_names = 'flux0 flux1'
    reference_component_flux_name = reference_flux
    temperature_name = temperature
  []
[]

[Postprocessors]
  [flux0_l2]
    type = ADMaterialVectorL2Error
    property = flux0
    gradient_function = flux0_exact
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [flux1_l2]
    type = ADMaterialVectorL2Error
    property = flux1
    gradient_function = flux1_exact
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [reference_flux_l2]
    type = ADMaterialVectorL2Error
    property = reference_flux
    gradient_function = reference_flux_exact
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [zero_sum_l2]
    type = ADMaterialVectorL2Error
    property = multicomponent_onsager_zero_sum_residual
    gradient_function = zero_vector
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [reciprocity_l2]
    type = ADMaterialScalarL2Error
    property = multicomponent_onsager_reciprocity_residual
    function = zero
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [minimum_pivot_l2]
    type = ADMaterialScalarL2Error
    property = multicomponent_onsager_minimum_cholesky_pivot
    function = minimum_pivot_exact
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [power_l2]
    type = ADMaterialScalarL2Error
    property = multicomponent_onsager_force_flux_power_density
    function = power_exact
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [entropy_l2]
    type = ADMaterialScalarL2Error
    property = multicomponent_onsager_entropy_production
    function = entropy_exact
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]

[Executioner]
  type = Steady
[]

[Outputs]
  csv = true
  execute_on = 'INITIAL TIMESTEP_END'
[]
