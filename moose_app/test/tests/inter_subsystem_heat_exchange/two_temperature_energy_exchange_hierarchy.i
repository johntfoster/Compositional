[Variables]
  [theta_f]
    family = LAGRANGE
    order = SECOND
  []
  [theta_f_enr]
    family = MONOMIAL
    order = CONSTANT
  []
  [theta_s]
    family = LAGRANGE
    order = SECOND
  []
  [theta_s_enr]
    family = MONOMIAL
    order = CONSTANT
  []
[]

[ICs]
  [theta_f_ic]
    type = ConstantIC
    variable = theta_f
    value = ${theta_f_initial}
  []
  [theta_s_ic]
    type = ConstantIC
    variable = theta_s
    value = ${theta_s_initial}
  []
[]

[Functions]
  [theta_f_exact]
    type = ParsedFunction
    expression = ${theta_f_exact_expression}
  []
  [theta_s_exact]
    type = ParsedFunction
    expression = ${theta_s_exact_expression}
  []
  [fluid_flux_exact]
    type = ParsedFunction
    expression = ${fluid_flux_potential_expression}
  []
  [solid_flux_exact]
    type = ParsedFunction
    expression = ${solid_flux_potential_expression}
  []
  [exchange_exact]
    type = ParsedFunction
    expression = ${fluid_exchange_expression}
  []
  [solid_exchange_exact]
    type = ParsedFunction
    expression = ${solid_exchange_expression}
  []
  [fluid_external_exact]
    type = ParsedFunction
    expression = ${fluid_external_expression}
  []
  [solid_external_exact]
    type = ParsedFunction
    expression = ${solid_external_expression}
  []
  [zero]
    type = ConstantFunction
    value = 0
  []
[]

[Materials]
  [theta_f_reconstruction]
    type = ADEGReconstructedScalarMaterial
    backbone = theta_f
    enrichment = theta_f_enr
    field_name = theta_f
  []
  [theta_s_reconstruction]
    type = ADEGReconstructedScalarMaterial
    backbone = theta_s
    enrichment = theta_s_enr
    field_name = theta_s
  []
  [reference_scalars]
    type = ADGenericConstantMaterial
    prop_names = 'solid_reference_J zero_electric_work'
    prop_values = '1 0'
  []
  [reference_inverse]
    type = ADGenericConstantRankTwoTensor
    tensor_name = solid_reference_F_inv
    tensor_values = '1 0 0  0 1 0  0 0 1'
  []
  [reference_jacobian_inverse]
    type = ADGenericConstantRankTwoTensor
    tensor_name = solid_reference_J_F_inv
    tensor_values = '1 0 0  0 1 0  0 0 1'
  []
  [fluid_conductivity_tensor]
    type = ADGenericConstantRankTwoTensor
    tensor_name = fluid_conductivity_tensor
    tensor_values = '2 0 0  0 2 0  0 0 2'
  []
  [solid_conductivity_tensor]
    type = ADGenericConstantRankTwoTensor
    tensor_name = solid_conductivity_tensor
    tensor_values = '3 0 0  0 3 0  0 0 3'
  []
  [fluid_fourier]
    type = ADReferenceThermalEnergyMaterial
    reference_temperature_gradient_name = theta_f_total_gradient
    thermal_conductivity = 2
    electric_field_work_names = zero_electric_work
    current_volumetric_heat_supply = zero
    current_heat_flux_name = fluid_current_heat_flux
    reference_heat_flux_name = fluid_reference_heat_flux
    reference_electric_work_name = fluid_reference_electric_work
    reference_heat_supply_name = fluid_reference_external_heat_supply
    reference_energy_source_name = fluid_unused_energy_source
  []
  [solid_fourier]
    type = ADReferenceThermalEnergyMaterial
    reference_temperature_gradient_name = theta_s_total_gradient
    thermal_conductivity = 3
    electric_field_work_names = zero_electric_work
    current_volumetric_heat_supply = zero
    current_heat_flux_name = solid_current_heat_flux
    reference_heat_flux_name = solid_reference_heat_flux
    reference_electric_work_name = solid_reference_electric_work
    reference_heat_supply_name = solid_reference_external_heat_supply
    reference_energy_source_name = solid_unused_energy_source
  []
  [heat_transfer_coefficient]
    type = ADParsedMaterial
    material_property_names = theta_f_total
    property_name = h_fs
    expression = '1+0.01*theta_f_total'
  []
  [heat_exchange]
    type = ADInterSubsystemHeatExchangeMaterial
    fluid_temperature_name = theta_f_total
    solid_temperature_name = theta_s_total
    heat_transfer_coefficient_name = h_fs
    fluid_heat_source_name = fluid_exchange_source
    solid_heat_source_name = solid_exchange_source
    exchange_cancellation_name = exchange_cancellation
    entropy_production_name = exchange_entropy_production
  []
  [manufactured_external_sources]
    type = ADGenericFunctionMaterial
    prop_names = 'fluid_external_source solid_external_source'
    prop_values = 'fluid_external_exact solid_external_exact'
  []
  [fluid_total_source]
    type = ADParsedMaterial
    material_property_names = 'fluid_external_source fluid_exchange_source'
    property_name = fluid_total_source
    expression = 'fluid_external_source+fluid_exchange_source'
  []
  [solid_total_source]
    type = ADParsedMaterial
    material_property_names = 'solid_external_source solid_exchange_source'
    property_name = solid_total_source
    expression = 'solid_external_source+solid_exchange_source'
  []
[]

[Kernels]
  [fluid_backbone_energy]
    type = ADEnrichedGalerkinScalarBalance
    variable = theta_f
    enrichment = theta_f_enr
    time_coefficient = 0
    reference_flux_name = fluid_reference_heat_flux
    source_name = fluid_total_source
  []
  [fluid_enrichment_energy]
    type = ADEnrichedGalerkinScalarEnrichmentBalance
    variable = theta_f_enr
    backbone = theta_f
    time_coefficient = 0
    source_name = fluid_total_source
  []
  [solid_backbone_energy]
    type = ADEnrichedGalerkinScalarBalance
    variable = theta_s
    enrichment = theta_s_enr
    time_coefficient = 0
    reference_flux_name = solid_reference_heat_flux
    source_name = solid_total_source
  []
  [solid_enrichment_energy]
    type = ADEnrichedGalerkinScalarEnrichmentBalance
    variable = theta_s_enr
    backbone = theta_s
    time_coefficient = 0
    source_name = solid_total_source
  []
[]

[DGKernels]
  [fluid_flux]
    type = ADEnrichedGalerkinFluxDG
    variable = theta_f_enr
    reference_flux_name = fluid_reference_heat_flux
    mobility_name = fluid_conductivity_tensor
    epsilon = ${eg_epsilon}
    sigma = ${eg_sigma}
  []
  [fluid_symmetry]
    type = ADEnrichedGalerkinSymmetryDG
    variable = theta_f
    enrichment = theta_f_enr
    mobility_name = fluid_conductivity_tensor
    epsilon = ${eg_epsilon}
  []
  [solid_flux]
    type = ADEnrichedGalerkinFluxDG
    variable = theta_s_enr
    reference_flux_name = solid_reference_heat_flux
    mobility_name = solid_conductivity_tensor
    epsilon = ${eg_epsilon}
    sigma = ${eg_sigma}
  []
  [solid_symmetry]
    type = ADEnrichedGalerkinSymmetryDG
    variable = theta_s
    enrichment = theta_s_enr
    mobility_name = solid_conductivity_tensor
    epsilon = ${eg_epsilon}
  []
[]

[BCs]
  [fluid_backbone]
    type = FunctionDirichletBC
    variable = theta_f
    boundary = ${all_boundaries}
    function = theta_f_exact
  []
  [solid_backbone]
    type = FunctionDirichletBC
    variable = theta_s
    boundary = ${all_boundaries}
    function = theta_s_exact
  []
  [fluid_enrichment]
    type = ADEnrichedGalerkinPenaltyBC
    variable = theta_f_enr
    backbone = theta_f
    boundary = ${all_boundaries}
    reference_flux_name = fluid_reference_heat_flux
    mobility_name = fluid_conductivity_tensor
    function = theta_f_exact
    epsilon = ${eg_epsilon}
    sigma = ${eg_sigma}
  []
  [solid_enrichment]
    type = ADEnrichedGalerkinPenaltyBC
    variable = theta_s_enr
    backbone = theta_s
    boundary = ${all_boundaries}
    reference_flux_name = solid_reference_heat_flux
    mobility_name = solid_conductivity_tensor
    function = theta_s_exact
    epsilon = ${eg_epsilon}
    sigma = ${eg_sigma}
  []
[]

[Postprocessors]
  [theta_f_total_l2]
    type = ADMaterialScalarL2Error
    property = theta_f_total
    function = theta_f_exact
  []
  [theta_s_total_l2]
    type = ADMaterialScalarL2Error
    property = theta_s_total
    function = theta_s_exact
  []
  [theta_f_gradient_l2]
    type = ADMaterialVectorL2Error
    property = theta_f_total_gradient
    gradient_function = theta_f_exact
  []
  [theta_s_gradient_l2]
    type = ADMaterialVectorL2Error
    property = theta_s_total_gradient
    gradient_function = theta_s_exact
  []
  [theta_f_enrichment_l2]
    type = ElementL2Norm
    variable = theta_f_enr
  []
  [theta_s_enrichment_l2]
    type = ElementL2Norm
    variable = theta_s_enr
  []
  [fluid_flux_l2]
    type = ADMaterialVectorL2Error
    property = fluid_reference_heat_flux
    gradient_function = fluid_flux_exact
  []
  [solid_flux_l2]
    type = ADMaterialVectorL2Error
    property = solid_reference_heat_flux
    gradient_function = solid_flux_exact
  []
  [fluid_exchange_l2]
    type = ADMaterialScalarL2Error
    property = fluid_exchange_source
    function = exchange_exact
  []
  [solid_exchange_l2]
    type = ADMaterialScalarL2Error
    property = solid_exchange_source
    function = solid_exchange_exact
  []
  [cancellation_l2]
    type = ADMaterialScalarL2Error
    property = exchange_cancellation
    function = zero
  []
[]

[Executioner]
  type = Transient
  solve_type = NEWTON
  dt = 1
  num_steps = 1
  nl_abs_tol = 1e-11
  nl_rel_tol = 1e-12
[]

[Outputs]
  csv = true
[]
