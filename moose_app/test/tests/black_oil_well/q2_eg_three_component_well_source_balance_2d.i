mesh_nx := 2
mesh_ny := 3

[Mesh]
  type = GeneratedMesh
  dim = 2
  xmin = 0
  xmax = 2
  ymin = 0
  ymax = 3
  nx = ${mesh_nx}
  ny = ${mesh_ny}
  elem_type = QUAD9
[]

!include ../../../input/includes/fields/solid_q2_aux_2d.i
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
  [solid_reference_jacobian]
    family = MONOMIAL
    order = CONSTANT
  []
  [sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_water_component_rate]
    family = MONOMIAL
    order = CONSTANT
  []
  [sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_stock_tank_oil_component_rate]
    family = MONOMIAL
    order = CONSTANT
  []
  [sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_stock_tank_gas_component_rate]
    family = MONOMIAL
    order = CONSTANT
  []
  [summed_eq32_water_component_well_source]
    family = MONOMIAL
    order = CONSTANT
  []
  [summed_eq32_stock_tank_oil_component_well_source]
    family = MONOMIAL
    order = CONSTANT
  []
  [summed_eq32_stock_tank_gas_component_well_source]
    family = MONOMIAL
    order = CONSTANT
  []
[]

[Functions]
  [zero]
    type = ParsedFunction
    expression = '0'
  []
  [ux_exact]
    type = ParsedFunction
    expression = '0.1*x'
  []
  [uy_exact]
    type = ParsedFunction
    expression = '0.2*y'
  []
  [solid_reference_jacobian_exact]
    type = ParsedFunction
    expression = '1.32'
  []
  [porosity_exact]
    type = ParsedFunction
    expression = '0.25'
  []
  [pressure_initial]
    type = ParsedFunction
    expression = '0.6783216783216783'
  []
  [pressure_exact]
    type = ParsedFunction
    expression = '2'
  []
  [water_saturation_initial]
    type = ParsedFunction
    expression = '0.18524475524475525'
  []
  [water_saturation_exact]
    type = ParsedFunction
    expression = '0.2'
  []
  [gas_saturation_initial]
    type = ParsedFunction
    expression = '0.2604895104895105'
  []
  [gas_saturation_exact]
    type = ParsedFunction
    expression = '0.2'
  []

  # Direct summed Eq. (32) variables, with no aggregate mass shorthand:
  # sum_xi J phi_xi fluid_intrinsic_density_xi eta_xi_component.
  [sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_water_component_exact]
    type = ParsedFunction
    expression = '1.32*0.25*2*0.2/1.2'
  []
  [sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_stock_tank_oil_component_exact]
    type = ParsedFunction
    expression = '1.32*0.25*3*(1-0.2-0.2)/1.4'
  []
  [sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_stock_tank_gas_component_exact]
    type = ParsedFunction
    expression = '1.32*0.25*(0.2/0.6+1.4*(1-0.2-0.2)/1.4)'
  []
  [sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_water_component_rate_exact]
    type = ParsedFunction
    expression = '-2*(0.01*0.2*(2-1)/1.2)/6'
  []
  [sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_stock_tank_oil_component_rate_exact]
    type = ParsedFunction
    expression = '-3*(0.01*0.3*(2-1)/1.4)/6'
  []
  [sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_stock_tank_gas_component_rate_exact]
    type = ParsedFunction
    expression = '-(0.01*0.4*(2-1)/0.6+1.4*0.01*0.3*(2-1)/1.4)/6'
  []

  [water_reservoir_rate_exact]
    type = ParsedFunction
    expression = '0.01*0.2*(2-1)'
  []
  [oil_reservoir_rate_exact]
    type = ParsedFunction
    expression = '0.01*0.3*(2-1)'
  []
  [gas_reservoir_rate_exact]
    type = ParsedFunction
    expression = '0.01*0.4*(2-1)'
  []
  [water_surface_rate_exact]
    type = ParsedFunction
    expression = '0.01*0.2*(2-1)/1.2'
  []
  [oil_surface_rate_exact]
    type = ParsedFunction
    expression = '0.01*0.3*(2-1)/1.4'
  []
  [gas_surface_rate_exact]
    type = ParsedFunction
    expression = '0.01*0.4*(2-1)/0.6+1.4*0.01*0.3*(2-1)/1.4'
  []
  [bottom_hole_pressure_exact]
    type = ParsedFunction
    expression = '1'
  []
  [control_surface_productivity_exact]
    type = ParsedFunction
    expression = '0.01*(0.4/0.6+1.4*0.3/1.4)'
  []
[]

[ICs]
  [pressure_ic]
    type = FunctionIC
    variable = pressure
    function = pressure_initial
  []
  [water_saturation_ic]
    type = FunctionIC
    variable = water_saturation
    function = water_saturation_initial
  []
  [gas_saturation_ic]
    type = FunctionIC
    variable = gas_saturation
    function = gas_saturation_initial
  []
  [porosity_ic]
    type = FunctionIC
    variable = porosity
    function = porosity_exact
  []
[]

!include ../../../input/includes/materials/solid_kinematics_2d.i
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
    water_formation_volume_factor_values = '1 2'
    oil_formation_volume_factor_values = '1.2 2.2'
    gas_formation_volume_factor_values = '0.5 1'
    solution_gas_oil_ratio_values = '1 3'
    water_viscosity_values = '1 1'
    oil_viscosity_values = '1 1'
    gas_viscosity_values = '1 1'
    water_surface_density = 2
    oil_surface_density = 3
    gas_surface_density = 1
  []
  [black_oil_relative_permeability]
    type = ADBlackOilRelativePermeabilityMaterial
    water_saturation = water_saturation
    gas_saturation = gas_saturation
    water_saturation_points = '0 1'
    water_relative_permeability_values = '0.2 0.2'
    oil_water_relative_permeability_values = '0.3 0.3'
    gas_saturation_points = '0 1'
    gas_relative_permeability_values = '0.4 0.4'
    oil_gas_relative_permeability_values = '0.3 0.3'
  []
  [production_well_and_summed_eq32_sources]
    type = ADBlackOilPeacemanWellMaterial
    pressure_source = material
    water_pressure_name = pressure_total
    oil_pressure_name = pressure_total
    gas_pressure_name = pressure_total
    mobility_source = relative_permeability_viscosity
    water_relative_permeability_name = black_oil_water_relative_permeability
    oil_relative_permeability_name = black_oil_oil_relative_permeability
    gas_relative_permeability_name = black_oil_gas_relative_permeability
    water_viscosity_name = black_oil_water_viscosity
    oil_viscosity_name = black_oil_oil_viscosity
    gas_viscosity_name = black_oil_gas_viscosity
    water_fvf_name = black_oil_water_formation_volume_factor
    oil_fvf_name = black_oil_oil_formation_volume_factor
    gas_fvf_name = black_oil_gas_formation_volume_factor
    solution_gas_oil_ratio_name = black_oil_solution_gas_oil_ratio
    well_index = 0.01
    control_mode = bhp
    bottom_hole_pressure = 1
    # The well occupies the complete 2 x 3 reference domain. Dividing by this
    # analytic completion area converts total well rates to reference sources.
    completion_reference_volume = 6
    water_surface_density = 2
    oil_surface_density = 3
    gas_surface_density = 1
  []
[]

[Kernels]
  [summed_eq32_water_component_balance]
    type = ADEnrichedGalerkinScalarBalance
    variable = water_saturation
    reference_component_storage_rate_name = black_oil_water_reference_component_storage_rate
    source_name = black_oil_well_water_reference_component_source
  []
  [summed_eq32_stock_tank_oil_component_backbone_balance]
    type = ADEnrichedGalerkinScalarBalance
    variable = pressure
    enrichment = pressure_enr
    reference_component_storage_rate_name = black_oil_oil_reference_component_storage_rate
    source_name = black_oil_well_oil_reference_component_source
  []
  [summed_eq32_stock_tank_oil_component_enrichment_balance]
    type = ADEnrichedGalerkinScalarEnrichmentBalance
    variable = pressure_enr
    backbone = pressure
    reference_component_storage_rate_name = black_oil_oil_reference_component_storage_rate
    source_name = black_oil_well_oil_reference_component_source
    anchor_coefficient = 1
  []
  [summed_eq32_stock_tank_gas_component_balance]
    type = ADEnrichedGalerkinScalarBalance
    variable = gas_saturation
    reference_component_storage_rate_name = black_oil_gas_reference_component_storage_rate
    source_name = black_oil_well_gas_reference_component_source
  []
[]

[BCs]
  [pressure_exact]
    type = FunctionDirichletBC
    variable = pressure
    boundary = 'left right bottom top'
    function = pressure_exact
  []
  [water_saturation_exact]
    type = FunctionDirichletBC
    variable = water_saturation
    boundary = 'left right bottom top'
    function = water_saturation_exact
  []
  [gas_saturation_exact]
    type = FunctionDirichletBC
    variable = gas_saturation
    boundary = 'left right bottom top'
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
  [uy_prescribed]
    type = FunctionAux
    variable = uy
    function = uy_exact
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [solid_reference_jacobian_aux]
    type = ADMaterialRealAux
    variable = solid_reference_jacobian
    property = solid_reference_J
    execute_on = TIMESTEP_END
  []
  [sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_water_component_rate_aux]
    type = ADMaterialRealAux
    variable = sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_water_component_rate
    property = black_oil_water_reference_component_storage_rate
    execute_on = TIMESTEP_END
  []
  [sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_stock_tank_oil_component_rate_aux]
    type = ADMaterialRealAux
    variable = sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_stock_tank_oil_component_rate
    property = black_oil_oil_reference_component_storage_rate
    execute_on = TIMESTEP_END
  []
  [sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_stock_tank_gas_component_rate_aux]
    type = ADMaterialRealAux
    variable = sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_stock_tank_gas_component_rate
    property = black_oil_gas_reference_component_storage_rate
    execute_on = TIMESTEP_END
  []
  [summed_eq32_water_component_well_source_aux]
    type = ADMaterialRealAux
    variable = summed_eq32_water_component_well_source
    property = black_oil_well_water_reference_component_source
    execute_on = TIMESTEP_END
  []
  [summed_eq32_stock_tank_oil_component_well_source_aux]
    type = ADMaterialRealAux
    variable = summed_eq32_stock_tank_oil_component_well_source
    property = black_oil_well_oil_reference_component_source
    execute_on = TIMESTEP_END
  []
  [summed_eq32_stock_tank_gas_component_well_source_aux]
    type = ADMaterialRealAux
    variable = summed_eq32_stock_tank_gas_component_well_source
    property = black_oil_well_gas_reference_component_source
    execute_on = TIMESTEP_END
  []
[]

[Postprocessors]
  [ux_l2]
    type = ElementL2Error
    variable = ux
    function = ux_exact
  []
  [uy_l2]
    type = ElementL2Error
    variable = uy
    function = uy_exact
  []
  [solid_reference_jacobian_l2]
    type = ADMaterialScalarL2Error
    property = solid_reference_J
    function = solid_reference_jacobian_exact
  []
  [reconstructed_p1_plus_p0_eg_pressure_l2]
    type = ADMaterialScalarL2Error
    property = pressure_total
    function = pressure_exact
  []
  [pressure_backbone_l2]
    type = ElementL2Error
    variable = pressure
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

  [sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_water_component_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_water_reference_component_storage
    function = sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_water_component_exact
  []
  [sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_stock_tank_oil_component_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_oil_reference_component_storage
    function = sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_stock_tank_oil_component_exact
  []
  [sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_stock_tank_gas_component_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_gas_reference_component_storage
    function = sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_stock_tank_gas_component_exact
  []
  [sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_water_component_rate_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_water_reference_component_storage_rate
    function = sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_water_component_rate_exact
  []
  [sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_stock_tank_oil_component_rate_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_oil_reference_component_storage_rate
    function = sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_stock_tank_oil_component_rate_exact
  []
  [sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_stock_tank_gas_component_rate_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_gas_reference_component_storage_rate
    function = sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_stock_tank_gas_component_rate_exact
  []
  [summed_eq32_water_component_well_source_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_well_water_reference_component_source
    function = sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_water_component_rate_exact
  []
  [summed_eq32_stock_tank_oil_component_well_source_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_well_oil_reference_component_source
    function = sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_stock_tank_oil_component_rate_exact
  []
  [summed_eq32_stock_tank_gas_component_well_source_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_well_gas_reference_component_source
    function = sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_stock_tank_gas_component_rate_exact
  []

  [water_reservoir_rate_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_well_water_reservoir_rate
    function = water_reservoir_rate_exact
  []
  [oil_reservoir_rate_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_well_oil_reservoir_rate
    function = oil_reservoir_rate_exact
  []
  [gas_reservoir_rate_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_well_gas_reservoir_rate
    function = gas_reservoir_rate_exact
  []
  [water_surface_rate_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_well_water_surface_rate
    function = water_surface_rate_exact
  []
  [oil_surface_rate_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_well_oil_surface_rate
    function = oil_surface_rate_exact
  []
  [gas_surface_rate_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_well_gas_surface_rate
    function = gas_surface_rate_exact
  []
  [effective_bottom_hole_pressure_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_well_effective_bottom_hole_pressure
    function = bottom_hole_pressure_exact
  []
  [control_surface_rate_residual_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_well_control_surface_rate_residual
    function = zero
  []
  [control_surface_productivity_l2]
    type = ADMaterialScalarL2Error
    property = black_oil_well_control_surface_productivity
    function = control_surface_productivity_exact
  []

  [reference_domain_area]
    type = VolumePostprocessor
  []
  [solid_reference_jacobian_integral]
    type = ElementIntegralVariablePostprocessor
    variable = solid_reference_jacobian
  []

  [sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_water_component_rate_integral]
    type = ElementIntegralVariablePostprocessor
    variable = sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_water_component_rate
  []
  [sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_stock_tank_oil_component_rate_integral]
    type = ElementIntegralVariablePostprocessor
    variable = sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_stock_tank_oil_component_rate
  []
  [sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_stock_tank_gas_component_rate_integral]
    type = ElementIntegralVariablePostprocessor
    variable = sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_stock_tank_gas_component_rate
  []
  [summed_eq32_water_component_well_source_integral]
    type = ElementIntegralVariablePostprocessor
    variable = summed_eq32_water_component_well_source
  []
  [summed_eq32_stock_tank_oil_component_well_source_integral]
    type = ElementIntegralVariablePostprocessor
    variable = summed_eq32_stock_tank_oil_component_well_source
  []
  [summed_eq32_stock_tank_gas_component_well_source_integral]
    type = ElementIntegralVariablePostprocessor
    variable = summed_eq32_stock_tank_gas_component_well_source
  []
  [direct_summed_eq32_water_component_global_balance]
    type = LinearCombinationPostprocessor
    pp_names = 'sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_water_component_rate_integral summed_eq32_water_component_well_source_integral'
    pp_coefs = '1 -1'
  []
  [direct_summed_eq32_stock_tank_oil_component_global_balance]
    type = LinearCombinationPostprocessor
    pp_names = 'sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_stock_tank_oil_component_rate_integral summed_eq32_stock_tank_oil_component_well_source_integral'
    pp_coefs = '1 -1'
  []
  [direct_summed_eq32_stock_tank_gas_component_global_balance]
    type = LinearCombinationPostprocessor
    pp_names = 'sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_stock_tank_gas_component_rate_integral summed_eq32_stock_tank_gas_component_well_source_integral'
    pp_coefs = '1 -1'
  []
[]

[Executioner]
  type = Transient
  scheme = implicit-euler
  solve_type = NEWTON
  start_time = 0
  # J/dt = 1.32/7.2 = 1.1/6, so the manufactured state jump produces
  # storage rates per reference area equal to the well totals divided by six.
  dt = 7.2
  num_steps = 1
  nl_abs_tol = 1e-13
  nl_rel_tol = 1e-13
  nl_max_its = 30
[]

[Outputs]
  csv = true
[]
