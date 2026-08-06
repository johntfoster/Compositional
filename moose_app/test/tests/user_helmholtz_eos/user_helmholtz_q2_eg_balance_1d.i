mesh_nx := 8
solve_dt := 1
solve_steps := 1

!include ../../../input/includes/mesh/generated_1d_q2.i
!include ../../../input/includes/fields/solid_q2_aux_1d.i

[Variables]
  [pressure]
    family = LAGRANGE
    order = FIRST
  []
  [pressure_enr]
    family = MONOMIAL
    order = CONSTANT
  []
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
  [summed_reference_component_0]
  []
  [summed_reference_component_1]
  []
[]

[AuxVariables]
  [rho0]
    family = LAGRANGE
    order = FIRST
  []
  [rho1]
    family = LAGRANGE
    order = FIRST
  []
  [temperature]
    family = LAGRANGE
    order = FIRST
  []
  [temperature_enr]
    family = MONOMIAL
    order = CONSTANT
  []
  [oil_volume_fraction]
  []
  [summed_reference_component_0_aux]
    family = MONOMIAL
    order = CONSTANT
  []
  [summed_reference_component_1_aux]
    family = MONOMIAL
    order = CONSTANT
  []
  [reference_component_0_source_aux]
    family = MONOMIAL
    order = CONSTANT
  []
  [reference_component_1_source_aux]
    family = MONOMIAL
    order = CONSTANT
  []
  [summed_reference_component_0_rate_aux]
    family = MONOMIAL
    order = CONSTANT
  []
  [summed_reference_component_1_rate_aux]
    family = MONOMIAL
    order = CONSTANT
  []
[]

[Functions]
  [ux_exact]
    type = ParsedFunction
    expression = '0.1*x'
  []
  [rho0_exact]
    type = ParsedFunction
    expression = '1+0.1*x+0.05*t'
  []
  [rho1_exact]
    type = ParsedFunction
    expression = '2*(1+0.1*x+0.05*t)'
  []
  [temperature_backbone_exact]
    type = ParsedFunction
    expression = 'x+0.2*t'
  []
  [temperature_enrichment_exact]
    type = ParsedFunction
    expression = '1'
  []
  [temperature_exact]
    type = ParsedFunction
    expression = '1+x+0.2*t'
  []
  [oil_volume_fraction_exact]
    type = ParsedFunction
    expression = '0.25'
  []
  [pressure_backbone_exact]
    type = ParsedFunction
    expression = '2*x+0.4*t'
  []
  [pressure_enrichment_exact]
    type = ParsedFunction
    expression = '9'
  []
  [pressure_exact]
    type = ParsedFunction
    expression = '9+2*x+0.4*t'
  []
  [neutral_potential_0_backbone_exact]
    type = ParsedFunction
    expression = '3*x+0.6*t'
  []
  [neutral_potential_0_enrichment_exact]
    type = ParsedFunction
    expression = '5'
  []
  [neutral_potential_0_exact]
    type = ParsedFunction
    expression = '5+3*x+0.6*t'
  []
  [neutral_potential_1_backbone_exact]
    type = ParsedFunction
    expression = '4*x+0.8*t'
  []
  [neutral_potential_1_enrichment_exact]
    type = ParsedFunction
    expression = '9'
  []
  [neutral_potential_1_exact]
    type = ParsedFunction
    expression = '9+4*x+0.8*t'
  []
  [helmholtz_exact]
    type = ParsedFunction
    expression = '(1+0.1*x+0.05*t)*(12+11*(1+x+0.2*t))-7-2*(1+x+0.2*t)'
  []
  [intrinsic_density_exact]
    type = ParsedFunction
    expression = '3*(1+0.1*x+0.05*t)'
  []
  [bulk_phase_density_exact]
    type = ParsedFunction
    expression = '0.75*(1+0.1*x+0.05*t)'
  []
  [specific_helmholtz_exact]
    type = ParsedFunction
    expression = '((1+0.1*x+0.05*t)*(12+11*(1+x+0.2*t))-7-2*(1+x+0.2*t))/(3*(1+0.1*x+0.05*t))'
  []
  [entropy_density_exact]
    type = ParsedFunction
    expression = '2-11*(1+0.1*x+0.05*t)'
  []
  [summed_reference_component_0_exact]
    type = ParsedFunction
    expression = '1.1*0.25*(1+0.1*x+0.05*t)'
  []
  [summed_reference_component_1_exact]
    type = ParsedFunction
    expression = '1.1*0.25*2*(1+0.1*x+0.05*t)'
  []
  [summed_reference_component_0_rate_exact]
    type = ParsedFunction
    expression = '0.01375'
  []
  [summed_reference_component_1_rate_exact]
    type = ParsedFunction
    expression = '0.0275'
  []
  [current_component_0_source]
    type = ParsedFunction
    expression = '-0.02625/1.1'
  []
  [current_component_1_source]
    type = ParsedFunction
    expression = '-0.0525/1.1'
  []
  [reference_component_0_source_exact]
    type = ParsedFunction
    expression = '-0.02625'
  []
  [reference_component_1_source_exact]
    type = ParsedFunction
    expression = '-0.0525'
  []
  [oil_reference_relative_mass_flux_antiderivative_exact]
    type = ParsedFunction
    expression = '-1.2*((1+0.05*t)*x+0.05*x^2)'
  []
  [current_component_0_extra_flux_antiderivative_exact]
    type = ParsedFunction
    expression = '-0.3*x'
  []
  [current_component_1_extra_flux_antiderivative_exact]
    type = ParsedFunction
    expression = '-0.4*x'
  []
  [reference_component_0_flux_antiderivative_exact]
    type = ParsedFunction
    expression = '-(0.4*(1+0.05*t)+0.3)*x-0.02*x^2'
  []
  [reference_component_1_flux_antiderivative_exact]
    type = ParsedFunction
    expression = '-(0.8*(1+0.05*t)+0.4)*x-0.04*x^2'
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
  [rho0_ic]
    type = FunctionIC
    variable = rho0
    function = rho0_exact
  []
  [rho1_ic]
    type = FunctionIC
    variable = rho1
    function = rho1_exact
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
  [oil_volume_fraction_ic]
    type = FunctionIC
    variable = oil_volume_fraction
    function = oil_volume_fraction_exact
  []
  [pressure_ic]
    type = FunctionIC
    variable = pressure
    function = zero
  []
  [pressure_enr_ic]
    type = FunctionIC
    variable = pressure_enr
    function = zero
  []
  [neutral_potential_0_ic]
    type = FunctionIC
    variable = neutral_potential_0
    function = zero
  []
  [neutral_potential_0_enr_ic]
    type = FunctionIC
    variable = neutral_potential_0_enr
    function = zero
  []
  [neutral_potential_1_ic]
    type = FunctionIC
    variable = neutral_potential_1
    function = zero
  []
  [neutral_potential_1_enr_ic]
    type = FunctionIC
    variable = neutral_potential_1_enr
    function = zero
  []
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
[]

[UserObjects]
  [phases]
    type = PhaseRegistry
    phases = 'solid oil'
    reference_phase = solid
  []
[]

!include ../../../input/includes/materials/solid_kinematics_1d.i

[Materials]
  [temperature_reconstructed]
    type = ADEGReconstructedScalarMaterial
    field_name = temperature
    backbone = temperature
    enrichment = temperature_enr
  []
  [pressure_reconstructed]
    type = ADEGReconstructedScalarMaterial
    field_name = pressure
    backbone = pressure
    enrichment = pressure_enr
  []
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
  [user_oil_helmholtz]
    type = ADDerivativeParsedMaterial
    coupled_variables = 'rho0 rho1 temperature temperature_enr'
    property_name = oil_helmholtz_density
    expression = 'rho0*(2+3*(temperature+temperature_enr))+rho1*(5+4*(temperature+temperature_enr))-(7+2*(temperature+temperature_enr))'
    derivative_order = 2
    enable_jit = true
  []
  [oil_eos_closure]
    type = ADHelmholtzEOSClosureMaterial
    phase = oil
    phase_registry = phases
    partial_densities = 'rho0 rho1'
    temperature = temperature
    porosity = oil_volume_fraction
    helmholtz_density_name = oil_helmholtz_density
  []
  [pressure_closure_residual]
    type = ADParsedMaterial
    material_property_names = 'pressure_total oil_pressure_from_eos'
    property_name = pressure_closure_residual
    expression = 'pressure_total-oil_pressure_from_eos'
  []
  [neutral_potential_0_closure_residual]
    type = ADParsedMaterial
    material_property_names = 'neutral_potential_0_total oil_chemical_potential_0'
    property_name = neutral_potential_0_closure_residual
    expression = 'neutral_potential_0_total-oil_chemical_potential_0'
  []
  [neutral_potential_1_closure_residual]
    type = ADParsedMaterial
    material_property_names = 'neutral_potential_1_total oil_chemical_potential_1'
    property_name = neutral_potential_1_closure_residual
    expression = 'neutral_potential_1_total-oil_chemical_potential_1'
  []
  [legendre_relation_residual]
    type = ADParsedMaterial
    coupled_variables = 'rho0 rho1'
    material_property_names = 'oil_pressure_from_eos oil_chemical_potential_0 oil_chemical_potential_1 oil_helmholtz_density'
    property_name = oil_legendre_relation_residual
    expression = 'oil_pressure_from_eos-(rho0*oil_chemical_potential_0+rho1*oil_chemical_potential_1-oil_helmholtz_density)'
  []
  [oil_component_fraction_0]
    type = ADParsedMaterial
    coupled_variables = 'rho0'
    material_property_names = 'oil_intrinsic_density'
    property_name = oil_component_mass_fraction_0
    expression = 'rho0/oil_intrinsic_density'
  []
  [oil_component_fraction_1]
    type = ADParsedMaterial
    coupled_variables = 'rho1'
    material_property_names = 'oil_intrinsic_density'
    property_name = oil_component_mass_fraction_1
    expression = 'rho1/oil_intrinsic_density'
  []
  # Direct single-mobile-phase specializations of the two Eq. (32) sums:
  # sum_xi J phi_xi fluid_intrinsic_density_xi eta_xi_component.
  [summed_reference_component_0_definition]
    type = ADParsedMaterial
    coupled_variables = 'rho0 oil_volume_fraction'
    material_property_names = 'solid_reference_J'
    property_name = direct_summed_reference_component_0
    expression = 'solid_reference_J*oil_volume_fraction*rho0'
  []
  [summed_reference_component_1_definition]
    type = ADParsedMaterial
    coupled_variables = 'rho1 oil_volume_fraction'
    material_property_names = 'solid_reference_J'
    property_name = direct_summed_reference_component_1
    expression = 'solid_reference_J*oil_volume_fraction*rho1'
  []
  [oil_darcy_flux]
    type = ADStandardDarcyReferenceFluxMaterial
    pressure = pressure
    pressure_enrichment = pressure_enr
    intrinsic_density_source = material
    intrinsic_density_name = oil_intrinsic_density
    permeability = 0.22
    viscosity = 1
    reference_relative_mass_flux_name = oil_reference_relative_mass_flux
  []
  [component_0_extra_flux]
    type = ADChargedNonisothermalComponentFluxMaterial
    neutral_potential_gradient_name = neutral_potential_0_total_gradient
    mobility = 0.1
    transport_force_name = component_0_transport_force
    current_component_flux_name = current_component_0_extra_flux
    current_charge_flux_name = unused_component_0_charge_flux
    electric_field_work_name = unused_component_0_electric_work
  []
  [component_1_extra_flux]
    type = ADChargedNonisothermalComponentFluxMaterial
    neutral_potential_gradient_name = neutral_potential_1_total_gradient
    mobility = 0.1
    transport_force_name = component_1_transport_force
    current_component_flux_name = current_component_1_extra_flux
    current_charge_flux_name = unused_component_1_charge_flux
    electric_field_work_name = unused_component_1_electric_work
  []
  [component_0_reference_flux]
    type = ADRegisteredPhaseComponentFluxMaterial
    phase_registry = phases
    phases = 'oil'
    component = 0
    phase_reference_relative_mass_flux_names = 'oil_reference_relative_mass_flux'
    phase_component_mass_fraction_names = 'oil_component_mass_fraction_0'
    current_component_extra_flux_material_name = current_component_0_extra_flux
    current_component_source = current_component_0_source
    reference_component_flux_name = reference_component_0_flux
    reference_component_source_name = reference_component_0_source
  []
  [component_1_reference_flux]
    type = ADRegisteredPhaseComponentFluxMaterial
    phase_registry = phases
    phases = 'oil'
    component = 1
    phase_reference_relative_mass_flux_names = 'oil_reference_relative_mass_flux'
    phase_component_mass_fraction_names = 'oil_component_mass_fraction_1'
    current_component_extra_flux_material_name = current_component_1_extra_flux
    current_component_source = current_component_1_source
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
  [rho0_prescribed]
    type = FunctionAux
    variable = rho0
    function = rho0_exact
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [rho1_prescribed]
    type = FunctionAux
    variable = rho1
    function = rho1_exact
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [temperature_prescribed]
    type = FunctionAux
    variable = temperature
    function = temperature_backbone_exact
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [temperature_enrichment_prescribed]
    type = FunctionAux
    variable = temperature_enr
    function = temperature_enrichment_exact
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [oil_volume_fraction_prescribed]
    type = FunctionAux
    variable = oil_volume_fraction
    function = oil_volume_fraction_exact
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [summed_reference_component_0_aux]
    type = ADMaterialRealAux
    variable = summed_reference_component_0_aux
    property = direct_summed_reference_component_0
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [summed_reference_component_1_aux]
    type = ADMaterialRealAux
    variable = summed_reference_component_1_aux
    property = direct_summed_reference_component_1
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [reference_component_0_source_aux]
    type = ADMaterialRealAux
    variable = reference_component_0_source_aux
    property = reference_component_0_source
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [reference_component_1_source_aux]
    type = ADMaterialRealAux
    variable = reference_component_1_source_aux
    property = reference_component_1_source
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [summed_reference_component_0_rate_aux]
    type = FunctionAux
    variable = summed_reference_component_0_rate_aux
    function = summed_reference_component_0_rate_exact
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [summed_reference_component_1_rate_aux]
    type = FunctionAux
    variable = summed_reference_component_1_rate_aux
    function = summed_reference_component_1_rate_exact
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]

[Kernels]
  [pressure_backbone_closure]
    type = ADEnrichedGalerkinMaterialPropertyResidual
    variable = pressure
    property = pressure_closure_residual
  []
  [pressure_enrichment_closure]
    type = ADEnrichedGalerkinMaterialPropertyResidual
    variable = pressure_enr
    property = pressure_closure_residual
    anchor_coefficient = 1
    anchor_value = 9
  []
  [neutral_potential_0_backbone_closure]
    type = ADEnrichedGalerkinMaterialPropertyResidual
    variable = neutral_potential_0
    property = neutral_potential_0_closure_residual
  []
  [neutral_potential_0_enrichment_closure]
    type = ADEnrichedGalerkinMaterialPropertyResidual
    variable = neutral_potential_0_enr
    property = neutral_potential_0_closure_residual
    anchor_coefficient = 1
    anchor_value = 5
  []
  [neutral_potential_1_backbone_closure]
    type = ADEnrichedGalerkinMaterialPropertyResidual
    variable = neutral_potential_1
    property = neutral_potential_1_closure_residual
  []
  [neutral_potential_1_enrichment_closure]
    type = ADEnrichedGalerkinMaterialPropertyResidual
    variable = neutral_potential_1_enr
    property = neutral_potential_1_closure_residual
    anchor_coefficient = 1
    anchor_value = 9
  []
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
    boundary = 'left right'
    function = summed_reference_component_0_exact
  []
  [summed_reference_component_1_exact]
    type = FunctionDirichletBC
    variable = summed_reference_component_1
    boundary = 'left right'
    function = summed_reference_component_1_exact
  []
[]

[Postprocessors]
  [ux_l2]
    type = ElementL2Error
    variable = ux
    function = ux_exact
  []
  [rho0_l2]
    type = ElementL2Error
    variable = rho0
    function = rho0_exact
  []
  [rho1_l2]
    type = ElementL2Error
    variable = rho1
    function = rho1_exact
  []
  [temperature_total_l2]
    type = ADMaterialScalarL2Error
    property = temperature_total
    function = temperature_exact
  []
  [pressure_total_l2]
    type = ADMaterialScalarL2Error
    property = pressure_total
    function = pressure_exact
  []
  [pressure_gradient_l2]
    type = ADMaterialVectorL2Error
    property = pressure_total_gradient
    gradient_function = pressure_exact
  []
  [pressure_enrichment_l2]
    type = ElementL2Error
    variable = pressure_enr
    function = pressure_enrichment_exact
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
  [neutral_potential_0_enrichment_l2]
    type = ElementL2Error
    variable = neutral_potential_0_enr
    function = neutral_potential_0_enrichment_exact
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
  [neutral_potential_1_enrichment_l2]
    type = ElementL2Error
    variable = neutral_potential_1_enr
    function = neutral_potential_1_enrichment_exact
  []
  [helmholtz_density_l2]
    type = ADMaterialScalarL2Error
    property = oil_helmholtz_density
    function = helmholtz_exact
  []
  [eos_pressure_l2]
    type = ADMaterialScalarL2Error
    property = oil_pressure_from_eos
    function = pressure_exact
  []
  [eos_neutral_potential_0_l2]
    type = ADMaterialScalarL2Error
    property = oil_chemical_potential_0
    function = neutral_potential_0_exact
  []
  [eos_neutral_potential_1_l2]
    type = ADMaterialScalarL2Error
    property = oil_chemical_potential_1
    function = neutral_potential_1_exact
  []
  [intrinsic_density_l2]
    type = ADMaterialScalarL2Error
    property = oil_intrinsic_density
    function = intrinsic_density_exact
  []
  [bulk_phase_density_l2]
    type = ADMaterialScalarL2Error
    property = oil_bulk_phase_density
    function = bulk_phase_density_exact
  []
  [specific_helmholtz_l2]
    type = ADMaterialScalarL2Error
    property = oil_specific_helmholtz_free_energy
    function = specific_helmholtz_exact
  []
  [entropy_density_l2]
    type = ADMaterialScalarL2Error
    property = oil_entropy_density
    function = entropy_density_exact
  []
  [legendre_relation_l2]
    type = ADMaterialScalarL2Error
    property = oil_legendre_relation_residual
    function = zero
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
  [oil_reference_relative_mass_flux_l2]
    type = ADMaterialVectorL2Error
    property = oil_reference_relative_mass_flux
    gradient_function = oil_reference_relative_mass_flux_antiderivative_exact
  []
  [current_component_0_extra_flux_l2]
    type = ADMaterialVectorL2Error
    property = current_component_0_extra_flux
    gradient_function = current_component_0_extra_flux_antiderivative_exact
  []
  [current_component_1_extra_flux_l2]
    type = ADMaterialVectorL2Error
    property = current_component_1_extra_flux
    gradient_function = current_component_1_extra_flux_antiderivative_exact
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
  [reference_component_0_source_l2]
    type = ElementL2Error
    variable = reference_component_0_source_aux
    function = reference_component_0_source_exact
  []
  [reference_component_1_source_l2]
    type = ElementL2Error
    variable = reference_component_1_source_aux
    function = reference_component_1_source_exact
  []
  [summed_reference_component_0_rate_integral]
    type = ElementIntegralVariablePostprocessor
    variable = summed_reference_component_0_rate_aux
  []
  [summed_reference_component_1_rate_integral]
    type = ElementIntegralVariablePostprocessor
    variable = summed_reference_component_1_rate_aux
  []
  [reference_component_0_source_integral]
    type = ElementIntegralVariablePostprocessor
    variable = reference_component_0_source_aux
  []
  [reference_component_1_source_integral]
    type = ElementIntegralVariablePostprocessor
    variable = reference_component_1_source_aux
  []
  [left_reference_component_0_flux]
    type = ADSideIntegralMaterialProperty
    boundary = left
    property = reference_component_0_flux
    component = 0
  []
  [right_reference_component_0_flux]
    type = ADSideIntegralMaterialProperty
    boundary = right
    property = reference_component_0_flux
    component = 0
  []
  [left_reference_component_1_flux]
    type = ADSideIntegralMaterialProperty
    boundary = left
    property = reference_component_1_flux
    component = 0
  []
  [right_reference_component_1_flux]
    type = ADSideIntegralMaterialProperty
    boundary = right
    property = reference_component_1_flux
    component = 0
  []
  [net_outward_reference_component_0_flux]
    type = LinearCombinationPostprocessor
    pp_names = 'right_reference_component_0_flux left_reference_component_0_flux'
    pp_coefs = '1 -1'
  []
  [net_outward_reference_component_1_flux]
    type = LinearCombinationPostprocessor
    pp_names = 'right_reference_component_1_flux left_reference_component_1_flux'
    pp_coefs = '1 -1'
  []
  [direct_summed_eq32_component_0_global_balance]
    type = LinearCombinationPostprocessor
    pp_names = 'summed_reference_component_0_rate_integral net_outward_reference_component_0_flux reference_component_0_source_integral'
    pp_coefs = '1 1 -1'
  []
  [direct_summed_eq32_component_1_global_balance]
    type = LinearCombinationPostprocessor
    pp_names = 'summed_reference_component_1_rate_integral net_outward_reference_component_1_flux reference_component_1_source_integral'
    pp_coefs = '1 1 -1'
  []
[]

[Executioner]
  type = Transient
  start_time = 0
  dt = ${solve_dt}
  num_steps = ${solve_steps}
  solve_type = NEWTON
  nl_rel_tol = 1e-14
  nl_abs_tol = 1e-14
  l_tol = 1e-14
  line_search = none
[]

!include ../../../input/includes/outputs/csv.i
!include ../../../input/includes/common/solver_defaults.i
