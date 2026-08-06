mesh_nx := 4
mesh_ny := 4
mesh_nz := 4
solve_dt := 1
solve_steps := 1

!include ../../../input/includes/mesh/generated_3d_q2.i
!include ../../../input/includes/fields/solid_q2_aux_3d.i

[Variables]
  [summed_reference_component_0]
  []
  [summed_reference_component_1]
  []
[]

[AuxVariables]
  [neutral_potential_0]
    family = LAGRANGE
    order = FIRST
  []
  [neutral_potential_0_enr]
    family = MONOMIAL
    order = CONSTANT
  []
  [neutral_potential_1]
    family = LAGRANGE
    order = FIRST
  []
  [neutral_potential_1_enr]
    family = MONOMIAL
    order = CONSTANT
  []
  [electric_potential]
    family = LAGRANGE
    order = FIRST
  []
  [electric_potential_enr]
    family = MONOMIAL
    order = CONSTANT
  []
  [temperature]
    family = LAGRANGE
    order = FIRST
  []
  [temperature_enr]
    family = MONOMIAL
    order = CONSTANT
  []
  [current_component_0_flux_x_aux]
    family = MONOMIAL
    order = SECOND
  []
  [current_component_0_flux_y_aux]
    family = MONOMIAL
    order = SECOND
  []
  [current_component_0_flux_z_aux]
    family = MONOMIAL
    order = SECOND
  []
  [current_component_1_flux_x_aux]
    family = MONOMIAL
    order = SECOND
  []
  [current_component_1_flux_y_aux]
    family = MONOMIAL
    order = SECOND
  []
  [current_component_1_flux_z_aux]
    family = MONOMIAL
    order = SECOND
  []
  [reference_component_0_flux_x_aux]
    family = MONOMIAL
    order = SECOND
  []
  [reference_component_0_flux_y_aux]
    family = MONOMIAL
    order = SECOND
  []
  [reference_component_0_flux_z_aux]
    family = MONOMIAL
    order = SECOND
  []
  [reference_component_1_flux_x_aux]
    family = MONOMIAL
    order = SECOND
  []
  [reference_component_1_flux_y_aux]
    family = MONOMIAL
    order = SECOND
  []
  [reference_component_1_flux_z_aux]
    family = MONOMIAL
    order = SECOND
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
    expression = '0.1*y'
  []
  [uz_exact]
    type = ParsedFunction
    expression = '0.1*z'
  []
  [neutral_potential_0_backbone_exact]
    type = ParsedFunction
    expression = 'x+2*y-z'
  []
  [neutral_potential_0_enrichment_exact]
    type = ParsedFunction
    expression = '0.1'
  []
  [neutral_potential_0_exact]
    type = ParsedFunction
    expression = '0.1+x+2*y-z'
  []
  [neutral_potential_1_backbone_exact]
    type = ParsedFunction
    expression = '-0.5*x+1.5*y+2.5*z'
  []
  [neutral_potential_1_enrichment_exact]
    type = ParsedFunction
    expression = '0.2'
  []
  [neutral_potential_1_exact]
    type = ParsedFunction
    expression = '0.2-0.5*x+1.5*y+2.5*z'
  []
  [electric_potential_backbone_exact]
    type = ParsedFunction
    expression = '2*x-y+2*z'
  []
  [electric_potential_enrichment_exact]
    type = ParsedFunction
    expression = '5'
  []
  [electric_potential_exact]
    type = ParsedFunction
    expression = '5+2*x-y+2*z'
  []
  [temperature_backbone_exact]
    type = ParsedFunction
    expression = '3*x+4*y+3*z'
  []
  [temperature_enrichment_exact]
    type = ParsedFunction
    expression = '1.5'
  []
  [temperature_exact]
    type = ParsedFunction
    expression = '1.5+3*x+4*y+3*z'
  []
  [transport_force_0_antiderivative_exact]
    type = ParsedFunction
    expression = '1.25*x+0.5*y-0.75*z'
  []
  [transport_force_1_antiderivative_exact]
    type = ParsedFunction
    expression = '-x+4.5*y+2*z'
  []
  [current_component_0_flux_antiderivative_exact]
    type = ParsedFunction
    expression = '-2*x-3.25*y+0.5*z'
  []
  [current_component_1_flux_antiderivative_exact]
    type = ParsedFunction
    expression = '0.875*x-7*y-2.625*z'
  []
  [reference_component_0_flux_antiderivative_exact]
    type = ParsedFunction
    expression = '-2.42*x-3.9325*y+0.605*z'
  []
  [reference_component_1_flux_antiderivative_exact]
    type = ParsedFunction
    expression = '1.05875*x-8.47*y-3.17625*z'
  []
  [onsager_reciprocity_residual_exact]
    type = ParsedFunction
    expression = '0'
  []
  [onsager_positive_definite_determinant_exact]
    type = ParsedFunction
    expression = '2.75'
  []
  [onsager_dissipation_exact]
    type = ParsedFunction
    expression = '42.125'
  []
  [summed_reference_component_0_exact]
    type = ParsedFunction
    expression = '(1.1*1.1*1.1)*0.25*2*0.4'
  []
  [summed_reference_component_1_exact]
    type = ParsedFunction
    expression = '(1.1*1.1*1.1)*0.25*2*0.6'
  []
[]

[ICs]
  [summed_reference_component_0_ic]
    type = FunctionIC
    variable = summed_reference_component_0
    function = summed_reference_component_0_exact
  []
  [summed_reference_component_1_ic]
    type = FunctionIC
    variable = summed_reference_component_1
    function = summed_reference_component_1_exact
  []
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
  [uz_ic]
    type = FunctionIC
    variable = uz
    function = uz_exact
  []
  [neutral_potential_0_ic]
    type = FunctionIC
    variable = neutral_potential_0
    function = neutral_potential_0_backbone_exact
  []
  [neutral_potential_0_enr_ic]
    type = FunctionIC
    variable = neutral_potential_0_enr
    function = neutral_potential_0_enrichment_exact
  []
  [neutral_potential_1_ic]
    type = FunctionIC
    variable = neutral_potential_1
    function = neutral_potential_1_backbone_exact
  []
  [neutral_potential_1_enr_ic]
    type = FunctionIC
    variable = neutral_potential_1_enr
    function = neutral_potential_1_enrichment_exact
  []
  [electric_potential_ic]
    type = FunctionIC
    variable = electric_potential
    function = electric_potential_backbone_exact
  []
  [electric_potential_enr_ic]
    type = FunctionIC
    variable = electric_potential_enr
    function = electric_potential_enrichment_exact
  []
  [temperature_ic]
    type = FunctionIC
    variable = temperature
    function = temperature_backbone_exact
  []
  [temperature_enr_ic]
    type = FunctionIC
    variable = temperature_enr
    function = temperature_enrichment_exact
  []
[]

[UserObjects]
  [phases]
    type = PhaseRegistry
    phases = 'solid fluid'
    reference_phase = solid
  []
[]

!include ../../../input/includes/materials/solid_kinematics_3d.i

[Materials]
  [neutral_potential_0_reconstructed]
    type = ADEGReconstructedScalarMaterial
    field_name = neutral_potential_0
    backbone = neutral_potential_0
    enrichment = neutral_potential_0_enr
  []
  [neutral_potential_1_reconstructed]
    type = ADEGReconstructedScalarMaterial
    field_name = neutral_potential_1
    backbone = neutral_potential_1
    enrichment = neutral_potential_1_enr
  []
  [electric_potential_reconstructed]
    type = ADEGReconstructedScalarMaterial
    field_name = electric_potential
    backbone = electric_potential
    enrichment = electric_potential_enr
  []
  [temperature_reconstructed]
    type = ADEGReconstructedScalarMaterial
    field_name = temperature
    backbone = temperature
    enrichment = temperature_enr
  []
  [component_0_force]
    type = ADChargedNonisothermalComponentFluxMaterial
    neutral_potential_gradient_name = neutral_potential_0_total_gradient
    electric_potential_gradient_name = electric_potential_total_gradient
    temperature_gradient_name = temperature_total_gradient
    mobility = 1
    charge_number = 0.5
    thermal_force_coefficient = -0.25
    transport_force_name = component_0_transport_force
    current_component_flux_name = unused_diagonal_component_0_flux
    current_charge_flux_name = unused_component_0_charge_flux
    electric_field_work_name = unused_component_0_electric_work
  []
  [component_1_force]
    type = ADChargedNonisothermalComponentFluxMaterial
    neutral_potential_gradient_name = neutral_potential_1_total_gradient
    electric_potential_gradient_name = electric_potential_total_gradient
    temperature_gradient_name = temperature_total_gradient
    mobility = 1
    charge_number = -1
    thermal_force_coefficient = 0.5
    transport_force_name = component_1_transport_force
    current_component_flux_name = unused_diagonal_component_1_flux
    current_charge_flux_name = unused_component_1_charge_flux
    electric_field_work_name = unused_component_1_electric_work
  []
  [two_component_onsager_flux]
    type = ADTwoComponentOnsagerFluxMaterial
    transport_force_names = 'component_0_transport_force component_1_transport_force'
    onsager_matrix = '2 0.5 0.5 1.5'
  []
  [component_state]
    type = ADGenericConstantMaterial
    prop_names = 'fluid_volume_fraction fluid_intrinsic_density fluid_eta0 fluid_eta1'
    prop_values = '0.25 2 0.4 0.6'
  []
  # Direct one-mobile-phase specializations of the two independent Eq. (32)
  # sums: sum_xi J phi_xi fluid_intrinsic_density_xi eta_xi_alpha.
  [summed_reference_component_0_definition]
    type = ADParsedMaterial
    material_property_names = 'solid_reference_J fluid_volume_fraction fluid_intrinsic_density fluid_eta0'
    property_name = direct_summed_reference_component_0
    expression = 'solid_reference_J*fluid_volume_fraction*fluid_intrinsic_density*fluid_eta0'
  []
  [summed_reference_component_1_definition]
    type = ADParsedMaterial
    material_property_names = 'solid_reference_J fluid_volume_fraction fluid_intrinsic_density fluid_eta1'
    property_name = direct_summed_reference_component_1
    expression = 'solid_reference_J*fluid_volume_fraction*fluid_intrinsic_density*fluid_eta1'
  []
  [zero_phase_flux]
    type = ADGenericConstantVectorMaterial
    prop_names = 'fluid_reference_relative_mass_flux'
    prop_values = '0 0 0'
  []
  [component_0_reference_flux]
    type = ADRegisteredPhaseComponentFluxMaterial
    phase_registry = phases
    phases = 'fluid'
    component = 0
    phase_reference_relative_mass_flux_names = 'fluid_reference_relative_mass_flux'
    phase_component_mass_fraction_names = 'fluid_eta0'
    current_component_extra_flux_material_name = current_component_0_onsager_flux
    current_component_source = zero
    reference_component_flux_name = reference_component_0_flux
    reference_component_source_name = reference_component_0_source
  []
  [component_1_reference_flux]
    type = ADRegisteredPhaseComponentFluxMaterial
    phase_registry = phases
    phases = 'fluid'
    component = 1
    phase_reference_relative_mass_flux_names = 'fluid_reference_relative_mass_flux'
    phase_component_mass_fraction_names = 'fluid_eta1'
    current_component_extra_flux_material_name = current_component_1_onsager_flux
    current_component_source = zero
    reference_component_flux_name = reference_component_1_flux
    reference_component_source_name = reference_component_1_source
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
  [uz_prescribed]
    type = FunctionAux
    variable = uz
    function = uz_exact
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [current_component_0_flux_x_extract]
    type = ADMaterialRealVectorValueAux
    variable = current_component_0_flux_x_aux
    property = current_component_0_onsager_flux
    component = 0
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [current_component_0_flux_y_extract]
    type = ADMaterialRealVectorValueAux
    variable = current_component_0_flux_y_aux
    property = current_component_0_onsager_flux
    component = 1
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [current_component_0_flux_z_extract]
    type = ADMaterialRealVectorValueAux
    variable = current_component_0_flux_z_aux
    property = current_component_0_onsager_flux
    component = 2
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [current_component_1_flux_x_extract]
    type = ADMaterialRealVectorValueAux
    variable = current_component_1_flux_x_aux
    property = current_component_1_onsager_flux
    component = 0
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [current_component_1_flux_y_extract]
    type = ADMaterialRealVectorValueAux
    variable = current_component_1_flux_y_aux
    property = current_component_1_onsager_flux
    component = 1
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [current_component_1_flux_z_extract]
    type = ADMaterialRealVectorValueAux
    variable = current_component_1_flux_z_aux
    property = current_component_1_onsager_flux
    component = 2
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [reference_component_0_flux_x_extract]
    type = ADMaterialRealVectorValueAux
    variable = reference_component_0_flux_x_aux
    property = reference_component_0_flux
    component = 0
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [reference_component_0_flux_y_extract]
    type = ADMaterialRealVectorValueAux
    variable = reference_component_0_flux_y_aux
    property = reference_component_0_flux
    component = 1
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [reference_component_0_flux_z_extract]
    type = ADMaterialRealVectorValueAux
    variable = reference_component_0_flux_z_aux
    property = reference_component_0_flux
    component = 2
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [reference_component_1_flux_x_extract]
    type = ADMaterialRealVectorValueAux
    variable = reference_component_1_flux_x_aux
    property = reference_component_1_flux
    component = 0
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [reference_component_1_flux_y_extract]
    type = ADMaterialRealVectorValueAux
    variable = reference_component_1_flux_y_aux
    property = reference_component_1_flux
    component = 1
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [reference_component_1_flux_z_extract]
    type = ADMaterialRealVectorValueAux
    variable = reference_component_1_flux_z_aux
    property = reference_component_1_flux
    component = 2
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]

[Kernels]
  [summed_reference_component_0_balance]
    type = ADReferenceFluidComponentBalance
    variable = summed_reference_component_0
    reference_component_flux = reference_component_0_flux
    reference_component_source = reference_component_0_source
  []
  [summed_reference_component_1_balance]
    type = ADReferenceFluidComponentBalance
    variable = summed_reference_component_1
    reference_component_flux = reference_component_1_flux
    reference_component_source = reference_component_1_source
  []
[]

[BCs]
  [summed_reference_component_0_exact]
    type = FunctionDirichletBC
    variable = summed_reference_component_0
    boundary = 'left right bottom top back front'
    function = summed_reference_component_0_exact
  []
  [summed_reference_component_1_exact]
    type = FunctionDirichletBC
    variable = summed_reference_component_1
    boundary = 'left right bottom top back front'
    function = summed_reference_component_1_exact
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
  [uz_l2]
    type = ElementL2Error
    variable = uz
    function = uz_exact
  []
  [neutral_potential_0_backbone_l2]
    type = ElementL2Error
    variable = neutral_potential_0
    function = neutral_potential_0_backbone_exact
  []
  [neutral_potential_0_enrichment_l2]
    type = ElementL2Error
    variable = neutral_potential_0_enr
    function = neutral_potential_0_enrichment_exact
  []
  [neutral_potential_0_total_l2]
    type = ADMaterialScalarL2Error
    property = neutral_potential_0_total
    function = neutral_potential_0_exact
  []
  [neutral_potential_0_gradient_l2]
    type = ADMaterialVectorL2Error
    property = neutral_potential_0_total_gradient
    gradient_function = neutral_potential_0_exact
  []
  [neutral_potential_1_backbone_l2]
    type = ElementL2Error
    variable = neutral_potential_1
    function = neutral_potential_1_backbone_exact
  []
  [neutral_potential_1_enrichment_l2]
    type = ElementL2Error
    variable = neutral_potential_1_enr
    function = neutral_potential_1_enrichment_exact
  []
  [neutral_potential_1_total_l2]
    type = ADMaterialScalarL2Error
    property = neutral_potential_1_total
    function = neutral_potential_1_exact
  []
  [neutral_potential_1_gradient_l2]
    type = ADMaterialVectorL2Error
    property = neutral_potential_1_total_gradient
    gradient_function = neutral_potential_1_exact
  []
  [electric_potential_backbone_l2]
    type = ElementL2Error
    variable = electric_potential
    function = electric_potential_backbone_exact
  []
  [electric_potential_enrichment_l2]
    type = ElementL2Error
    variable = electric_potential_enr
    function = electric_potential_enrichment_exact
  []
  [electric_potential_total_l2]
    type = ADMaterialScalarL2Error
    property = electric_potential_total
    function = electric_potential_exact
  []
  [electric_potential_gradient_l2]
    type = ADMaterialVectorL2Error
    property = electric_potential_total_gradient
    gradient_function = electric_potential_exact
  []
  [temperature_backbone_l2]
    type = ElementL2Error
    variable = temperature
    function = temperature_backbone_exact
  []
  [temperature_enrichment_l2]
    type = ElementL2Error
    variable = temperature_enr
    function = temperature_enrichment_exact
  []
  [temperature_total_l2]
    type = ADMaterialScalarL2Error
    property = temperature_total
    function = temperature_exact
  []
  [temperature_gradient_l2]
    type = ADMaterialVectorL2Error
    property = temperature_total_gradient
    gradient_function = temperature_exact
  []
  [transport_force_0_l2]
    type = ADMaterialVectorL2Error
    property = component_0_transport_force
    gradient_function = transport_force_0_antiderivative_exact
  []
  [transport_force_1_l2]
    type = ADMaterialVectorL2Error
    property = component_1_transport_force
    gradient_function = transport_force_1_antiderivative_exact
  []
  [current_component_0_flux_l2]
    type = ADMaterialVectorL2Error
    property = current_component_0_onsager_flux
    gradient_function = current_component_0_flux_antiderivative_exact
  []
  [current_component_1_flux_l2]
    type = ADMaterialVectorL2Error
    property = current_component_1_onsager_flux
    gradient_function = current_component_1_flux_antiderivative_exact
  []
  [reference_component_0_flux_l2]
    type = ADMaterialVectorL2Error
    property = reference_component_0_flux
    gradient_function = reference_component_0_flux_antiderivative_exact
  []
  [reference_component_1_flux_l2]
    type = ADMaterialVectorL2Error
    property = reference_component_1_flux
    gradient_function = reference_component_1_flux_antiderivative_exact
  []
  [onsager_reciprocity_l2]
    type = ADMaterialScalarL2Error
    property = onsager_reciprocity_residual
    function = onsager_reciprocity_residual_exact
  []
  [onsager_positive_definite_determinant_l2]
    type = ADMaterialScalarL2Error
    property = onsager_positive_definite_determinant
    function = onsager_positive_definite_determinant_exact
  []
  [onsager_dissipation_l2]
    type = ADMaterialScalarL2Error
    property = onsager_dissipation
    function = onsager_dissipation_exact
  []
  [onsager_dissipation_average]
    type = ADElementAverageMaterialProperty
    mat_prop = onsager_dissipation
  []
  [direct_summed_reference_component_0_l2]
    type = ADMaterialScalarL2Error
    property = direct_summed_reference_component_0
    function = summed_reference_component_0_exact
  []
  [direct_summed_reference_component_1_l2]
    type = ADMaterialScalarL2Error
    property = direct_summed_reference_component_1
    function = summed_reference_component_1_exact
  []
  [summed_reference_component_0_balance_l2]
    type = ElementL2Error
    variable = summed_reference_component_0
    function = summed_reference_component_0_exact
  []
  [summed_reference_component_1_balance_l2]
    type = ElementL2Error
    variable = summed_reference_component_1
    function = summed_reference_component_1_exact
  []
  [current_component_0_flux_x]
    type = ElementIntegralVariablePostprocessor
    variable = current_component_0_flux_x_aux
  []
  [current_component_0_flux_y]
    type = ElementIntegralVariablePostprocessor
    variable = current_component_0_flux_y_aux
  []
  [current_component_0_flux_z]
    type = ElementIntegralVariablePostprocessor
    variable = current_component_0_flux_z_aux
  []
  [current_component_1_flux_x]
    type = ElementIntegralVariablePostprocessor
    variable = current_component_1_flux_x_aux
  []
  [current_component_1_flux_y]
    type = ElementIntegralVariablePostprocessor
    variable = current_component_1_flux_y_aux
  []
  [current_component_1_flux_z]
    type = ElementIntegralVariablePostprocessor
    variable = current_component_1_flux_z_aux
  []
  [left_reference_component_0_flux_x]
    type = ADSideIntegralMaterialProperty
    boundary = left
    property = reference_component_0_flux
    component = 0
  []
  [right_reference_component_0_flux_x]
    type = ADSideIntegralMaterialProperty
    boundary = right
    property = reference_component_0_flux
    component = 0
  []
  [bottom_reference_component_0_flux_y]
    type = ADSideIntegralMaterialProperty
    boundary = bottom
    property = reference_component_0_flux
    component = 1
  []
  [top_reference_component_0_flux_y]
    type = ADSideIntegralMaterialProperty
    boundary = top
    property = reference_component_0_flux
    component = 1
  []
  [back_reference_component_0_flux_z]
    type = ADSideIntegralMaterialProperty
    boundary = back
    property = reference_component_0_flux
    component = 2
  []
  [front_reference_component_0_flux_z]
    type = ADSideIntegralMaterialProperty
    boundary = front
    property = reference_component_0_flux
    component = 2
  []
  [left_reference_component_1_flux_x]
    type = ADSideIntegralMaterialProperty
    boundary = left
    property = reference_component_1_flux
    component = 0
  []
  [right_reference_component_1_flux_x]
    type = ADSideIntegralMaterialProperty
    boundary = right
    property = reference_component_1_flux
    component = 0
  []
  [bottom_reference_component_1_flux_y]
    type = ADSideIntegralMaterialProperty
    boundary = bottom
    property = reference_component_1_flux
    component = 1
  []
  [top_reference_component_1_flux_y]
    type = ADSideIntegralMaterialProperty
    boundary = top
    property = reference_component_1_flux
    component = 1
  []
  [back_reference_component_1_flux_z]
    type = ADSideIntegralMaterialProperty
    boundary = back
    property = reference_component_1_flux
    component = 2
  []
  [front_reference_component_1_flux_z]
    type = ADSideIntegralMaterialProperty
    boundary = front
    property = reference_component_1_flux
    component = 2
  []
  [direct_summed_reference_component_0_global_balance]
    type = LinearCombinationPostprocessor
    pp_names = 'right_reference_component_0_flux_x left_reference_component_0_flux_x top_reference_component_0_flux_y bottom_reference_component_0_flux_y front_reference_component_0_flux_z back_reference_component_0_flux_z'
    pp_coefs = '1 -1 1 -1 1 -1'
  []
  [direct_summed_reference_component_1_global_balance]
    type = LinearCombinationPostprocessor
    pp_names = 'right_reference_component_1_flux_x left_reference_component_1_flux_x top_reference_component_1_flux_y bottom_reference_component_1_flux_y front_reference_component_1_flux_z back_reference_component_1_flux_z'
    pp_coefs = '1 -1 1 -1 1 -1'
  []
[]

!include ../../../input/includes/executioner/transient_newton.i
!include ../../../input/includes/outputs/csv.i
!include ../../../input/includes/common/solver_defaults.i
