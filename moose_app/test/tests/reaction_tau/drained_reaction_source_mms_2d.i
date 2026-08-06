mesh_nx := 4
mesh_ny := 4
all_boundaries = 'left right bottom top'
eg_epsilon := -1.0
eg_sigma := 12.0
solve_dt := 0.1
solve_steps := 2

!include ../../../input/includes/mesh/generated_2d_q2.i
!include ../../../input/includes/fields/solid_q2_aux_2d.i
!include ../../../input/includes/fields/eg_pressure.i

[AuxVariables]
  [reaction_rate]
    family = LAGRANGE
    order = FIRST
  []
  [summed_reference_component_storage_aux]
    family = MONOMIAL
    order = FIRST
  []
  [summed_reference_component_storage_rate_aux]
    family = MONOMIAL
    order = FIRST
  []
  [summed_reference_component_source_aux]
    family = MONOMIAL
    order = FIRST
  []
  [summed_reference_component_flux_x_aux]
    family = MONOMIAL
    order = FIRST
  []
  [summed_reference_component_flux_y_aux]
    family = MONOMIAL
    order = FIRST
  []
[]

[Functions]
  # These fields are represented exactly by QUAD9/Q2 displacement and the
  # reconstructed P1 backbone plus P0 enrichment EG pressure spaces.
  [ux_exact]
    type = ParsedFunction
    expression = '0'
  []
  [uy_exact]
    type = ParsedFunction
    expression = '0'
  []
  [p_exact]
    type = ParsedFunction
    expression = '1+0.2*x+0.15*y+0.1*t'
  []
  [summed_reference_component_storage_exact]
    type = ParsedFunction
    expression = '1*0.25*(2+0.5*(1+0.2*x+0.15*y+0.1*t))*1'
  []
  [summed_reference_component_storage_rate_exact]
    type = ParsedFunction
    expression = '0.0125'
  []
  # W_alpha = eta_fluid_alpha W_fluid with
  # W_fluid = -fluid_intrinsic_density*0.3*Grad_X(p).
  [summed_reference_component_flux_x_exact]
    type = ParsedFunction
    expression = '-0.06*(2+0.5*(1+0.2*x+0.15*y+0.1*t))'
  []
  [summed_reference_component_flux_y_exact]
    type = ParsedFunction
    expression = '-0.045*(2+0.5*(1+0.2*x+0.15*y+0.1*t))'
  []
  # d(storage)/dt + Div_X(W_alpha) = 0.0125 - 0.009375.
  [summed_reference_component_source_exact]
    type = ParsedFunction
    expression = '0.003125'
  []
  [reaction_rate_exact]
    type = ParsedFunction
    expression = '0.003125'
  []
  [one]
    type = ParsedFunction
    expression = '1'
  []
  [zero]
    type = ParsedFunction
    expression = '0'
  []
[]

[ICs]
  [ux_ic]
    type = FunctionIC
    variable = ux
    function = ux_exact
  []
  [uy_ic]
    type = FunctionIC
    variable = uy
    function = uy_exact
  []
  [p_ic]
    type = FunctionIC
    variable = p
    function = p_exact
  []
  [reaction_rate_ic]
    type = FunctionIC
    variable = reaction_rate
    function = reaction_rate_exact
  []
[]

[UserObjects]
  [phases]
    type = PhaseRegistry
    phases = 'solid fluid'
    reference_phase = solid
  []
[]

!include ../../../input/includes/materials/solid_kinematics_2d.i
!include ../../../input/includes/materials/eg_pressure_reconstruction.i

[Materials]
  [component_state_constants]
    type = ADGenericConstantMaterial
    prop_names = 'fluid_volume_fraction fluid_component_mass_fraction fluid_chemical_potential_0'
    prop_values = '0.25 1 0'
  []
  [fluid_intrinsic_density]
    type = ADParsedMaterial
    material_property_names = 'p_total'
    property_name = fluid_intrinsic_density
    expression = '2+0.5*p_total'
  []
  # Single-mobile-phase specialization of the direct Eq. (32) sum
  # sum_xi J phi_xi fluid_intrinsic_density_xi eta_xi_alpha.
  [summed_reference_component_storage]
    type = ADParsedMaterial
    material_property_names = 'solid_reference_J fluid_volume_fraction fluid_intrinsic_density fluid_component_mass_fraction'
    property_name = summed_reference_component_storage
    expression = 'solid_reference_J*fluid_volume_fraction*fluid_intrinsic_density*fluid_component_mass_fraction'
  []
  # Direct product time rate of that summed Eq. (32) variable.
  [summed_reference_component_storage_rate]
    type = ADParsedMaterial
    material_property_names = 'solid_reference_J solid_reference_J_dot fluid_volume_fraction fluid_intrinsic_density fluid_component_mass_fraction p_total_dot'
    property_name = summed_reference_component_storage_rate
    expression = 'solid_reference_J_dot*fluid_volume_fraction*fluid_intrinsic_density*fluid_component_mass_fraction+solid_reference_J*fluid_volume_fraction*0.5*p_total_dot*fluid_component_mass_fraction'
  []
  [reaction_network]
    type = ADReactionNetworkMaterial
    phase_registry = phases
    phases = 'fluid'
    components = 'component0'
    reaction_rates = reaction_rate
    stoichiometric_coefficients = '1'
    chemical_potential_names = 'fluid_chemical_potential_0'
  []
  [fluid_darcy_flux]
    type = ADStandardDarcyReferenceFluxMaterial
    pressure = p
    pressure_enrichment = p_enr
    intrinsic_density_source = material
    intrinsic_density_name = fluid_intrinsic_density
    permeability = 0.3
    viscosity = 1
    darcy_mobility_ref_name = p_mobility
    reference_relative_mass_flux_name = fluid_reference_relative_mass_flux
  []
  [summed_reference_component_flux]
    type = ADReferenceFluidComponentFluxMaterial
    reference_relative_mass_flux = fluid_reference_relative_mass_flux
    component_mass_fraction = one
    current_component_source = zero
    reference_component_flux_name = summed_reference_component_flux
    reference_component_source_name = unused_reference_component_source
  []
[]

[Kernels]
  [p_backbone_balance]
    type = ADEnrichedGalerkinScalarBalance
    variable = p
    enrichment = p_enr
    reference_component_storage_rate_name = summed_reference_component_storage_rate
    reference_flux_name = summed_reference_component_flux
    source_name = reaction_network_reference_component_source_0
  []
  [p_enrichment_balance]
    type = ADEnrichedGalerkinScalarEnrichmentBalance
    variable = p_enr
    backbone = p
    reference_component_storage_rate_name = summed_reference_component_storage_rate
    source_name = reaction_network_reference_component_source_0
  []
[]

[DGKernels]
  [p_enrichment_flux]
    type = ADEnrichedGalerkinFluxDG
    variable = p_enr
    reference_flux_name = summed_reference_component_flux
    mobility_name = p_mobility
    epsilon = ${eg_epsilon}
    sigma = ${eg_sigma}
  []
  [p_backbone_symmetry]
    type = ADEnrichedGalerkinSymmetryDG
    variable = p
    enrichment = p_enr
    mobility_name = p_mobility
    epsilon = ${eg_epsilon}
  []
[]

[BCs]
  [p_backbone_drained]
    type = FunctionDirichletBC
    variable = p
    boundary = ${all_boundaries}
    function = p_exact
  []
  [p_enrichment_drained]
    type = ADEnrichedGalerkinPenaltyBC
    variable = p_enr
    backbone = p
    boundary = ${all_boundaries}
    reference_flux_name = summed_reference_component_flux
    mobility_name = p_mobility
    function = p_exact
    epsilon = ${eg_epsilon}
    sigma = ${eg_sigma}
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
  [summed_reference_component_storage_aux]
    type = ADMaterialRealAux
    variable = summed_reference_component_storage_aux
    property = summed_reference_component_storage
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [summed_reference_component_storage_rate_aux]
    type = ADMaterialRealAux
    variable = summed_reference_component_storage_rate_aux
    property = summed_reference_component_storage_rate
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [summed_reference_component_source_aux]
    type = ADMaterialRealAux
    variable = summed_reference_component_source_aux
    property = reaction_network_reference_component_source_0
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [summed_reference_component_flux_x_aux]
    type = ADMaterialRealVectorValueAux
    variable = summed_reference_component_flux_x_aux
    property = summed_reference_component_flux
    component = 0
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [summed_reference_component_flux_y_aux]
    type = ADMaterialRealVectorValueAux
    variable = summed_reference_component_flux_y_aux
    property = summed_reference_component_flux
    component = 1
    execute_on = 'INITIAL TIMESTEP_END'
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
  [p_total_l2]
    type = ADMaterialScalarL2Error
    property = p_total
    function = p_exact
  []
  [p_total_gradient_l2]
    type = ADMaterialVectorL2Error
    property = p_total_gradient
    gradient_function = p_exact
  []
  [p_enrichment_l2]
    type = ElementL2Norm
    variable = p_enr
  []
  [summed_reference_component_storage_l2]
    type = ElementL2Error
    variable = summed_reference_component_storage_aux
    function = summed_reference_component_storage_exact
  []
  [summed_reference_component_storage_rate_l2]
    type = ElementL2Error
    variable = summed_reference_component_storage_rate_aux
    function = summed_reference_component_storage_rate_exact
  []
  [summed_reference_component_source_l2]
    type = ElementL2Error
    variable = summed_reference_component_source_aux
    function = summed_reference_component_source_exact
  []
  [summed_reference_component_flux_x_l2]
    type = ElementL2Error
    variable = summed_reference_component_flux_x_aux
    function = summed_reference_component_flux_x_exact
  []
  [summed_reference_component_flux_y_l2]
    type = ElementL2Error
    variable = summed_reference_component_flux_y_aux
    function = summed_reference_component_flux_y_exact
  []
  [summed_reference_component_storage_rate_integral]
    type = ElementIntegralVariablePostprocessor
    variable = summed_reference_component_storage_rate_aux
  []
  [summed_reference_component_source_integral]
    type = ElementIntegralVariablePostprocessor
    variable = summed_reference_component_source_aux
  []
  [left_reference_component_flux_x]
    type = ADSideIntegralMaterialProperty
    boundary = left
    property = summed_reference_component_flux
    component = 0
  []
  [right_reference_component_flux_x]
    type = ADSideIntegralMaterialProperty
    boundary = right
    property = summed_reference_component_flux
    component = 0
  []
  [bottom_reference_component_flux_y]
    type = ADSideIntegralMaterialProperty
    boundary = bottom
    property = summed_reference_component_flux
    component = 1
  []
  [top_reference_component_flux_y]
    type = ADSideIntegralMaterialProperty
    boundary = top
    property = summed_reference_component_flux
    component = 1
  []
  [net_outward_reference_component_flux]
    type = LinearCombinationPostprocessor
    pp_names = 'right_reference_component_flux_x left_reference_component_flux_x top_reference_component_flux_y bottom_reference_component_flux_y'
    pp_coefs = '1 -1 1 -1'
  []
  [summed_reference_component_global_balance]
    type = LinearCombinationPostprocessor
    pp_names = 'summed_reference_component_storage_rate_integral net_outward_reference_component_flux summed_reference_component_source_integral'
    pp_coefs = '1 1 -1'
  []
[]

!include ../../../input/includes/executioner/transient_newton.i
!include ../../../input/includes/outputs/csv.i
!include ../../../input/includes/common/solver_defaults.i
