mesh_nx := 4
all_boundaries = 'left right'
eg_epsilon := -1.0
eg_sigma := 12.0

!include ../../../input/includes/mesh/generated_1d_q2.i
!include ../../../input/includes/fields/solid_q2_aux_1d.i
!include ../../../input/includes/fields/eg_pressure_legacy.i

[Variables]
  [water_saturation]
    family = LAGRANGE
    order = FIRST
  []
  [gas_saturation]
    family = LAGRANGE
    order = FIRST
  []
[]

[AuxVariables]
  [porosity]
  []
  [water_pressure]
    family = LAGRANGE
    order = FIRST
  []
  [gas_pressure]
    family = LAGRANGE
    order = FIRST
  []
  [water_reference_component_flux_x]
    family = MONOMIAL
    order = FIRST
  []
  [oil_reference_component_flux_x]
    family = MONOMIAL
    order = FIRST
  []
  [gas_reference_component_flux_x]
    family = MONOMIAL
    order = FIRST
  []
  [water_reference_component_storage_rate_aux]
    family = MONOMIAL
    order = CONSTANT
  []
  [oil_reference_component_storage_rate_aux]
    family = MONOMIAL
    order = CONSTANT
  []
  [gas_reference_component_storage_rate_aux]
    family = MONOMIAL
    order = CONSTANT
  []
  [water_reference_component_source_aux]
    family = MONOMIAL
    order = CONSTANT
  []
  [oil_reference_component_source_aux]
    family = MONOMIAL
    order = CONSTANT
  []
  [gas_reference_component_source_aux]
    family = MONOMIAL
    order = CONSTANT
  []
[]

[Functions]
  [zero]
    type = ParsedFunction
    expression = '0'
  []
  [one]
    type = ParsedFunction
    expression = '1'
  []
  [ux_exact]
    type = ParsedFunction
    expression = '0.1*x'
  []
  [solid_reference_jacobian_exact]
    type = ParsedFunction
    expression = '1.1'
  []
  [pressure_exact]
    type = ParsedFunction
    expression = '2+x'
  []
  [water_saturation_exact]
    type = ParsedFunction
    expression = '0.2+0.1*x'
  []
  [gas_saturation_exact]
    type = ParsedFunction
    expression = '0.2+0.05*x'
  []
  [porosity_exact]
    type = ParsedFunction
    expression = '0.25'
  []
  [water_pressure_exact]
    type = ParsedFunction
    expression = '1.1+0.8*x'
  []
  [gas_pressure_exact]
    type = ParsedFunction
    expression = '2.9+1.15*x'
  []
  [water_relative_permeability_exact]
    type = ParsedFunction
    expression = '0.28+0.04*x'
  []
  [oil_relative_permeability_exact]
    type = ParsedFunction
    expression = '0.5'
  []
  [gas_relative_permeability_exact]
    type = ParsedFunction
    expression = '0.34+0.01*x'
  []
  [water_reference_component_storage_exact]
    type = ParsedFunction
    expression = '1.1*0.25*2*(0.2+0.1*x)'
  []
  [oil_reference_component_storage_exact]
    type = ParsedFunction
    expression = '1.1*0.25*3*(0.6-0.15*x)'
  []
  [gas_reference_component_storage_exact]
    type = ParsedFunction
    expression = '1.1*0.25*(0.2+0.05*x)'
  []
  [water_reference_component_flux_x_exact]
    type = ParsedFunction
    expression = '-2*0.1*0.8*(0.28+0.04*x)/1.1'
  []
  [oil_reference_component_flux_x_exact]
    type = ParsedFunction
    expression = '-3*0.1*0.5/1.1'
  []
  [gas_reference_component_flux_x_exact]
    type = ParsedFunction
    expression = '-0.1*1.15*(0.34+0.01*x)/1.1'
  []
  [water_current_component_source]
    type = ParsedFunction
    expression = '-0.0064/(1.1*1.1)'
  []
  [oil_current_component_source]
    type = ParsedFunction
    expression = '0'
  []
  [gas_current_component_source]
    type = ParsedFunction
    expression = '-0.00115/(1.1*1.1)'
  []
  [water_reference_component_source_exact]
    type = ParsedFunction
    expression = '-0.0064/1.1'
  []
  [oil_reference_component_source_exact]
    type = ParsedFunction
    expression = '0'
  []
  [gas_reference_component_source_exact]
    type = ParsedFunction
    expression = '-0.00115/1.1'
  []
[]

[ICs]
  [pressure_ic]
    type = FunctionIC
    variable = pressure
    function = pressure_exact
  []
  [water_saturation_ic]
    type = FunctionIC
    variable = water_saturation
    function = water_saturation_exact
  []
  [gas_saturation_ic]
    type = FunctionIC
    variable = gas_saturation
    function = gas_saturation_exact
  []
  [porosity_ic]
    type = FunctionIC
    variable = porosity
    function = porosity_exact
  []
  [water_pressure_ic]
    type = FunctionIC
    variable = water_pressure
    function = water_pressure_exact
  []
  [gas_pressure_ic]
    type = FunctionIC
    variable = gas_pressure
    function = gas_pressure_exact
  []
[]

[UserObjects]
  [phases]
    type = PhaseRegistry
    phases = 'matrix oil gas water'
    reference_phase = matrix
    momentum_models = 'reference relative_flux relative_flux relative_flux'
  []
[]

!include ../../../input/includes/materials/solid_kinematics_1d.i
!include ../../../input/includes/materials/eg_pressure_legacy_reconstruction.i

[Materials]
  [black_oil_pvt]
    type = ADBlackOilPVTMaterial
    compute_storage_rates = true
    pressure_name = pressure_total
    pressure_rate_name = pressure_total_dot
    porosity = porosity
    water_saturation = water_saturation
    gas_saturation = gas_saturation
    pressure_points = '0 10'
    water_formation_volume_factor_values = '1 1'
    oil_formation_volume_factor_values = '1 1'
    gas_formation_volume_factor_values = '1 1'
    solution_gas_oil_ratio_values = '0 0'
    water_viscosity_values = '1 1'
    oil_viscosity_values = '1 1'
    gas_viscosity_values = '1 1'
    water_surface_density = 2
    oil_surface_density = 3
    gas_surface_density = 1
  []
  [black_oil_capillary]
    type = ADBlackOilCapillaryPressureMaterial
    oil_pressure = pressure
    water_pressure = water_pressure
    gas_pressure = gas_pressure
    water_saturation = water_saturation
    gas_saturation = gas_saturation
    water_saturation_points = '0 1'
    water_oil_capillary_pressure_values = '0.5 2.5'
    gas_saturation_points = '0 1'
    gas_oil_capillary_pressure_values = '0.3 3.3'
  []
  [black_oil_relative_permeability]
    type = ADBlackOilRelativePermeabilityMaterial
    water_saturation = water_saturation
    gas_saturation = gas_saturation
    water_saturation_points = '0 1'
    water_relative_permeability_values = '0.2 0.6'
    oil_water_relative_permeability_values = '0.5 0.5'
    gas_saturation_points = '0 1'
    gas_relative_permeability_values = '0.3 0.5'
    oil_gas_relative_permeability_values = '0.5 0.5'
  []
  [water_darcy]
    type = ADStandardDarcyReferenceFluxMaterial
    phase = water
    phase_registry = phases
    pressure = water_pressure
    intrinsic_density_source = material
    intrinsic_density_name = black_oil_water_intrinsic_density
    permeability = 0.1
    viscosity_name = black_oil_water_viscosity
    relative_permeability_name = black_oil_water_relative_permeability
    darcy_mobility_ref_name = water_darcy_mobility
    reference_relative_mass_flux_name = water_reference_relative_mass_flux
  []
  [oil_darcy]
    type = ADStandardDarcyReferenceFluxMaterial
    phase = oil
    phase_registry = phases
    pressure = pressure
    pressure_enrichment = pressure_enr
    intrinsic_density_source = material
    intrinsic_density_name = black_oil_oil_intrinsic_density
    permeability = 0.1
    viscosity_name = black_oil_oil_viscosity
    relative_permeability_name = black_oil_oil_relative_permeability
    darcy_mobility_ref_name = oil_darcy_mobility
    reference_relative_mass_flux_name = oil_reference_relative_mass_flux
  []
  [gas_darcy]
    type = ADStandardDarcyReferenceFluxMaterial
    phase = gas
    phase_registry = phases
    pressure = gas_pressure
    intrinsic_density_source = material
    intrinsic_density_name = black_oil_gas_intrinsic_density
    permeability = 0.1
    viscosity_name = black_oil_gas_viscosity
    relative_permeability_name = black_oil_gas_relative_permeability
    darcy_mobility_ref_name = gas_darcy_mobility
    reference_relative_mass_flux_name = gas_reference_relative_mass_flux
  []
  [component_mass_fraction_constants]
    type = ADGenericConstantMaterial
    prop_names = 'zero_component_mass_fraction unit_component_mass_fraction'
    prop_values = '0 1'
  []
  [water_reference_component_flux_and_source]
    type = ADRegisteredPhaseComponentFluxMaterial
    phase_registry = phases
    phases = 'oil gas water'
    component = 0
    phase_reference_relative_mass_flux_names = 'oil_reference_relative_mass_flux gas_reference_relative_mass_flux water_reference_relative_mass_flux'
    phase_component_mass_fraction_names = 'zero_component_mass_fraction zero_component_mass_fraction unit_component_mass_fraction'
    current_component_source = water_current_component_source
    reference_component_flux_name = water_reference_component_flux
    reference_component_source_name = water_reference_component_source
  []
  [oil_reference_component_flux_and_source]
    type = ADRegisteredPhaseComponentFluxMaterial
    phase_registry = phases
    phases = 'oil gas water'
    component = 1
    phase_reference_relative_mass_flux_names = 'oil_reference_relative_mass_flux gas_reference_relative_mass_flux water_reference_relative_mass_flux'
    phase_component_mass_fraction_names = 'black_oil_oil_component_mass_fraction_in_oil zero_component_mass_fraction zero_component_mass_fraction'
    current_component_source = oil_current_component_source
    reference_component_flux_name = oil_reference_component_flux
    reference_component_source_name = oil_reference_component_source
  []
  [gas_reference_component_flux_and_source]
    type = ADRegisteredPhaseComponentFluxMaterial
    phase_registry = phases
    phases = 'oil gas water'
    component = 2
    phase_reference_relative_mass_flux_names = 'oil_reference_relative_mass_flux gas_reference_relative_mass_flux water_reference_relative_mass_flux'
    phase_component_mass_fraction_names = 'black_oil_gas_component_mass_fraction_in_oil unit_component_mass_fraction zero_component_mass_fraction'
    current_component_source = gas_current_component_source
    reference_component_flux_name = gas_reference_component_flux
    reference_component_source_name = gas_reference_component_source
  []
[]

[Kernels]
  [water_component_balance]
    type = ADEnrichedGalerkinScalarBalance
    variable = water_saturation
    reference_component_storage_rate_name = black_oil_water_reference_component_storage_rate
    reference_flux_name = water_reference_component_flux
    source_name = water_reference_component_source
  []
  [oil_component_backbone_balance]
    type = ADEnrichedGalerkinScalarBalance
    variable = pressure
    enrichment = pressure_enr
    reference_component_storage_rate_name = black_oil_oil_reference_component_storage_rate
    reference_flux_name = oil_reference_component_flux
    source_name = oil_reference_component_source
  []
  [oil_component_enrichment_balance]
    type = ADEnrichedGalerkinScalarEnrichmentBalance
    variable = pressure_enr
    backbone = pressure
    reference_component_storage_rate_name = black_oil_oil_reference_component_storage_rate
    source_name = oil_reference_component_source
  []
  [gas_component_balance]
    type = ADEnrichedGalerkinScalarBalance
    variable = gas_saturation
    reference_component_storage_rate_name = black_oil_gas_reference_component_storage_rate
    reference_flux_name = gas_reference_component_flux
    source_name = gas_reference_component_source
  []
[]

[DGKernels]
  [oil_component_enrichment_flux]
    type = ADEnrichedGalerkinFluxDG
    variable = pressure_enr
    reference_flux_name = oil_reference_component_flux
    mobility_name = oil_darcy_mobility
    epsilon = ${eg_epsilon}
    sigma = ${eg_sigma}
  []
[]

[BCs]
  [pressure_backbone_exact]
    type = FunctionDirichletBC
    variable = pressure
    boundary = ${all_boundaries}
    function = pressure_exact
  []
  [pressure_enrichment_weak_exact]
    type = ADEnrichedGalerkinPenaltyBC
    variable = pressure_enr
    backbone = pressure
    boundary = ${all_boundaries}
    reference_flux_name = oil_reference_component_flux
    mobility_name = oil_darcy_mobility
    function = pressure_exact
    epsilon = ${eg_epsilon}
    sigma = ${eg_sigma}
  []
  [water_saturation_exact]
    type = FunctionDirichletBC
    variable = water_saturation
    boundary = ${all_boundaries}
    function = water_saturation_exact
  []
  [gas_saturation_exact]
    type = FunctionDirichletBC
    variable = gas_saturation
    boundary = ${all_boundaries}
    function = gas_saturation_exact
  []
[]

[AuxKernels]
  [ux_prescribed]
    type = FunctionAux
    variable = ux
    function = ux_exact
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [water_reference_component_flux_x_aux]
    type = ADMaterialRealVectorValueAux
    variable = water_reference_component_flux_x
    property = water_reference_component_flux
    component = 0
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [oil_reference_component_flux_x_aux]
    type = ADMaterialRealVectorValueAux
    variable = oil_reference_component_flux_x
    property = oil_reference_component_flux
    component = 0
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [gas_reference_component_flux_x_aux]
    type = ADMaterialRealVectorValueAux
    variable = gas_reference_component_flux_x
    property = gas_reference_component_flux
    component = 0
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [water_reference_component_storage_rate_aux_kernel]
    type = ADMaterialRealAux
    variable = water_reference_component_storage_rate_aux
    property = black_oil_water_reference_component_storage_rate
    execute_on = TIMESTEP_END
  []
  [oil_reference_component_storage_rate_aux_kernel]
    type = ADMaterialRealAux
    variable = oil_reference_component_storage_rate_aux
    property = black_oil_oil_reference_component_storage_rate
    execute_on = TIMESTEP_END
  []
  [gas_reference_component_storage_rate_aux_kernel]
    type = ADMaterialRealAux
    variable = gas_reference_component_storage_rate_aux
    property = black_oil_gas_reference_component_storage_rate
    execute_on = TIMESTEP_END
  []
  [water_reference_component_source_aux_kernel]
    type = ADMaterialRealAux
    variable = water_reference_component_source_aux
    property = water_reference_component_source
    execute_on = TIMESTEP_END
  []
  [oil_reference_component_source_aux_kernel]
    type = ADMaterialRealAux
    variable = oil_reference_component_source_aux
    property = oil_reference_component_source
    execute_on = TIMESTEP_END
  []
  [gas_reference_component_source_aux_kernel]
    type = ADMaterialRealAux
    variable = gas_reference_component_source_aux
    property = gas_reference_component_source
    execute_on = TIMESTEP_END
  []
[]

[Postprocessors]
  [ux_l2]
    type = ElementL2Error
    variable = ux
    function = ux_exact
  []
  [solid_reference_jacobian_l2]
    type = ADMaterialScalarL2Error
    property = solid_reference_J
    function = solid_reference_jacobian_exact
  []
  [pressure_l2]
    type = ADMaterialScalarL2Error
    property = pressure_total
    function = pressure_exact
  []
  [pressure_enrichment_l2]
    type = ElementL2Norm
    variable = pressure_enr
  []
  [water_saturation_l2]
    type = ElementL2Error
    variable = water_saturation
    function = water_saturation_exact
  []
  [gas_saturation_l2]
    type = ElementL2Error
    variable = gas_saturation
    function = gas_saturation_exact
  []
  [water_pressure_closure_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_water_pressure_closure_residual
    function = zero
  []
  [gas_pressure_closure_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_gas_pressure_closure_residual
    function = zero
  []
  [water_relative_permeability_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_water_relative_permeability
    function = water_relative_permeability_exact
  []
  [oil_relative_permeability_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_oil_relative_permeability
    function = oil_relative_permeability_exact
  []
  [gas_relative_permeability_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_gas_relative_permeability
    function = gas_relative_permeability_exact
  []
  [water_reference_component_storage_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_water_reference_component_storage
    function = water_reference_component_storage_exact
  []
  [oil_reference_component_storage_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_oil_reference_component_storage
    function = oil_reference_component_storage_exact
  []
  [gas_reference_component_storage_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_gas_reference_component_storage
    function = gas_reference_component_storage_exact
  []
  [water_reference_component_storage_rate_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_water_reference_component_storage_rate
    function = zero
  []
  [oil_reference_component_storage_rate_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_oil_reference_component_storage_rate
    function = zero
  []
  [gas_reference_component_storage_rate_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_gas_reference_component_storage_rate
    function = zero
  []
  [water_reference_component_flux_x_l2]
    type = ElementL2Error
    variable = water_reference_component_flux_x
    function = water_reference_component_flux_x_exact
  []
  [oil_reference_component_flux_x_l2]
    type = ElementL2Error
    variable = oil_reference_component_flux_x
    function = oil_reference_component_flux_x_exact
  []
  [gas_reference_component_flux_x_l2]
    type = ElementL2Error
    variable = gas_reference_component_flux_x
    function = gas_reference_component_flux_x_exact
  []
  [water_reference_component_source_l2]
    type = ADMaterialScalarL2Error
    property = water_reference_component_source
    function = water_reference_component_source_exact
  []
  [oil_reference_component_source_l2]
    type = ADMaterialScalarL2Error
    property = oil_reference_component_source
    function = oil_reference_component_source_exact
  []
  [gas_reference_component_source_l2]
    type = ADMaterialScalarL2Error
    property = gas_reference_component_source
    function = gas_reference_component_source_exact
  []

  [water_reference_component_storage_rate_integral]
    type = ElementIntegralVariablePostprocessor
    variable = water_reference_component_storage_rate_aux
  []
  [oil_reference_component_storage_rate_integral]
    type = ElementIntegralVariablePostprocessor
    variable = oil_reference_component_storage_rate_aux
  []
  [gas_reference_component_storage_rate_integral]
    type = ElementIntegralVariablePostprocessor
    variable = gas_reference_component_storage_rate_aux
  []
  [water_reference_component_source_integral]
    type = ElementIntegralVariablePostprocessor
    variable = water_reference_component_source_aux
  []
  [oil_reference_component_source_integral]
    type = ElementIntegralVariablePostprocessor
    variable = oil_reference_component_source_aux
  []
  [gas_reference_component_source_integral]
    type = ElementIntegralVariablePostprocessor
    variable = gas_reference_component_source_aux
  []
  [water_left_reference_component_flux]
    type = ADSideIntegralMaterialProperty
    boundary = left
    property = water_reference_component_flux
    component = 0
  []
  [water_right_reference_component_flux]
    type = ADSideIntegralMaterialProperty
    boundary = right
    property = water_reference_component_flux
    component = 0
  []
  [oil_left_reference_component_flux]
    type = ADSideIntegralMaterialProperty
    boundary = left
    property = oil_reference_component_flux
    component = 0
  []
  [oil_right_reference_component_flux]
    type = ADSideIntegralMaterialProperty
    boundary = right
    property = oil_reference_component_flux
    component = 0
  []
  [gas_left_reference_component_flux]
    type = ADSideIntegralMaterialProperty
    boundary = left
    property = gas_reference_component_flux
    component = 0
  []
  [gas_right_reference_component_flux]
    type = ADSideIntegralMaterialProperty
    boundary = right
    property = gas_reference_component_flux
    component = 0
  []
  [water_net_outward_reference_component_flux]
    type = LinearCombinationPostprocessor
    pp_names = 'water_right_reference_component_flux water_left_reference_component_flux'
    pp_coefs = '1 -1'
  []
  [oil_net_outward_reference_component_flux]
    type = LinearCombinationPostprocessor
    pp_names = 'oil_right_reference_component_flux oil_left_reference_component_flux'
    pp_coefs = '1 -1'
  []
  [gas_net_outward_reference_component_flux]
    type = LinearCombinationPostprocessor
    pp_names = 'gas_right_reference_component_flux gas_left_reference_component_flux'
    pp_coefs = '1 -1'
  []
  [direct_summed_eq32_water_component_global_balance]
    type = LinearCombinationPostprocessor
    pp_names = 'water_reference_component_storage_rate_integral water_net_outward_reference_component_flux water_reference_component_source_integral'
    pp_coefs = '1 1 -1'
  []
  [direct_summed_eq32_oil_component_global_balance]
    type = LinearCombinationPostprocessor
    pp_names = 'oil_reference_component_storage_rate_integral oil_net_outward_reference_component_flux oil_reference_component_source_integral'
    pp_coefs = '1 1 -1'
  []
  [direct_summed_eq32_gas_component_global_balance]
    type = LinearCombinationPostprocessor
    pp_names = 'gas_reference_component_storage_rate_integral gas_net_outward_reference_component_flux gas_reference_component_source_integral'
    pp_coefs = '1 1 -1'
  []
[]

[Executioner]
  type = Transient
  scheme = implicit-euler
  solve_type = NEWTON
  start_time = 0
  dt = 1
  num_steps = 1
  nl_abs_tol = 1e-12
  nl_rel_tol = 1e-12
  nl_max_its = 20
[]

[Outputs]
  csv = true
[]
