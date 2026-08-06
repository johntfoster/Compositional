mesh_nx := 8
eg_epsilon := -1.0
eg_sigma := 12.0
solve_dt := 0.1
solve_steps := 2
solid_shear_modulus := 3.0
solid_lame_lambda := 5.0
solid_biot := 0.25

!include ../../../input/includes/mesh/generated_1d_q2.i
!include ../../../input/includes/fields/solid_q2_1d.i
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
[]

[Functions]
  [ux_exact]
    type = ParsedFunction
    expression = '(0.04+0.01*t)*x'
  []
  [p_exact]
    type = ParsedFunction
    expression = '1+0.1*t'
  []
  [solid_reference_jacobian_exact]
    type = ParsedFunction
    expression = '1.04+0.01*t'
  []
  [fluid_intrinsic_density_exact]
    type = ParsedFunction
    expression = '2.5+0.05*t'
  []
  [summed_reference_component_storage_exact]
    type = ParsedFunction
    expression = '0.25*(1.04+0.01*t)*(2.5+0.05*t)'
  []
  [summed_reference_component_storage_rate_exact]
    type = ParsedFunction
    expression = '0.25*(0.01*(2.5+0.05*t)+(1.04+0.01*t)*0.05)'
  []
  [reaction_rate_exact]
    type = ParsedFunction
    expression = '0.25*(0.01*(2.5+0.05*t)+(1.04+0.01*t)*0.05)/(1.04+0.01*t)'
  []
  [right_traction_exact]
    type = ParsedFunction
    expression = '3*((1.04+0.01*t)-1/(1.04+0.01*t))+5*log(1.04+0.01*t)/(1.04+0.01*t)-0.25*(1+0.1*t)'
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

!include ../../../input/includes/materials/solid_kinematics_1d.i
!include ../../../input/includes/materials/eg_pressure_reconstruction.i
!include ../../../input/includes/materials/solid_stress_eg_pressure.i

[Materials]
  [fluid_intrinsic_density]
    type = ADParsedMaterial
    material_property_names = 'p_total'
    property_name = fluid_intrinsic_density
    expression = '2+0.5*p_total'
  []
  [summed_reference_component_storage]
    type = ADParsedMaterial
    material_property_names = 'solid_reference_J fluid_intrinsic_density'
    property_name = summed_reference_component_storage
    expression = 'solid_reference_J*0.25*fluid_intrinsic_density*1.0'
  []
  [summed_reference_component_storage_rate]
    type = ADParsedMaterial
    material_property_names = 'solid_reference_J solid_reference_J_dot fluid_intrinsic_density p_total_dot'
    property_name = summed_reference_component_storage_rate
    expression = '0.25*(solid_reference_J_dot*fluid_intrinsic_density+solid_reference_J*0.5*p_total_dot)*1.0'
  []
  [fluid_chemical_potential]
    type = ADGenericConstantMaterial
    prop_names = 'fluid_chemical_potential_0'
    prop_values = '0'
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
  [solid_x]
    type = ADReferenceSolidMomentum
    variable = ux
    component = 0
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
  [left_ux]
    type = FunctionDirichletBC
    variable = ux
    boundary = left
    function = ux_exact
  []
  [right_traction]
    type = ADReferenceSolidTractionBC
    variable = ux
    boundary = right
    traction = right_traction_exact
  []
[]

[AuxKernels]
  [reaction_rate_prescribed]
    type = FunctionAux
    variable = reaction_rate
    function = reaction_rate_exact
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
[]

[Postprocessors]
  [ux_l2]
    type = ElementL2Error
    variable = ux
    function = ux_exact
  []
  [ux_h1_semi]
    type = ElementH1SemiError
    variable = ux
    function = ux_exact
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
  [solid_reference_jacobian_l2]
    type = ADMaterialScalarL2Error
    property = solid_reference_J
    function = solid_reference_jacobian_exact
  []
  [reaction_rate_l2]
    type = ElementL2Error
    variable = reaction_rate
    function = reaction_rate_exact
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
    function = summed_reference_component_storage_rate_exact
  []
  [summed_reference_component_storage_integral]
    type = ElementIntegralVariablePostprocessor
    variable = summed_reference_component_storage_aux
  []
  [summed_reference_component_storage_rate_integral]
    type = ElementIntegralVariablePostprocessor
    variable = summed_reference_component_storage_rate_aux
  []
  [summed_reference_component_source_integral]
    type = ElementIntegralVariablePostprocessor
    variable = summed_reference_component_source_aux
  []
  [left_reference_component_flux]
    type = ADSideIntegralMaterialProperty
    boundary = left
    property = summed_reference_component_flux
    component = 0
  []
  [right_reference_component_flux]
    type = ADSideIntegralMaterialProperty
    boundary = right
    property = summed_reference_component_flux
    component = 0
  []
  [net_outward_reference_component_flux]
    type = LinearCombinationPostprocessor
    pp_names = 'right_reference_component_flux left_reference_component_flux'
    pp_coefs = '1 -1'
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
