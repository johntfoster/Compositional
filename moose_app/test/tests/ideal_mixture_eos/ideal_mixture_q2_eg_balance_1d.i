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

  # These are the two direct summed Eq. (32) variables.  The deliberately
  # explicit names keep the represented quantity visible and avoid aggregate
  # A or M_a^0 shorthand:
  # sum_xi J phi_xi fluid_intrinsic_density_xi eta_xi_component.
  [sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_component_0]
    family = LAGRANGE
    order = SECOND
  []
  [sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_component_1]
    family = LAGRANGE
    order = SECOND
  []
[]

[AuxVariables]
  [pressure_target]
    family = LAGRANGE
    order = FIRST
  []
  [temperature]
    family = LAGRANGE
    order = FIRST
  []
  [porosity]
    family = LAGRANGE
    order = FIRST
  []
  [eta0]
    family = LAGRANGE
    order = FIRST
  []
  [eta1]
    family = LAGRANGE
    order = FIRST
  []
  [sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_component_0_rate_aux]
    family = MONOMIAL
    order = CONSTANT
  []
  [sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_component_1_rate_aux]
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
  [pressure_backbone_exact]
    type = ParsedFunction
    expression = '1e-5*x+0.2*t'
  []
  [pressure_enrichment_exact]
    type = ParsedFunction
    expression = '2.5'
  []
  [pressure_exact]
    type = ParsedFunction
    expression = '2.5+1e-5*x+0.2*t'
  []
  [temperature_exact]
    type = ParsedFunction
    expression = '300'
  []
  [porosity_exact]
    type = ParsedFunction
    expression = '0.4'
  []
  [eta0_exact]
    type = ParsedFunction
    expression = '0.25'
  []
  [eta1_exact]
    type = ParsedFunction
    expression = '0.75'
  []
  [mass_fraction_sum_exact]
    type = ParsedFunction
    expression = '1'
  []
  [intrinsic_density_exact]
    type = ParsedFunction
    expression = '2*exp(0.1*(1.5+1e-5*x+0.2*t))'
  []
  [current_phase_mass_density_exact]
    type = ParsedFunction
    expression = '0.8*exp(0.1*(1.5+1e-5*x+0.2*t))'
  []
  [component_partial_density_0_exact]
    type = ParsedFunction
    expression = '0.5*exp(0.1*(1.5+1e-5*x+0.2*t))'
  []
  [component_partial_density_1_exact]
    type = ParsedFunction
    expression = '1.5*exp(0.1*(1.5+1e-5*x+0.2*t))'
  []
  [specific_helmholtz_exact]
    type = ParsedFunction
    expression = '(11-(12.5+1e-5*x+0.2*t)/exp(0.1*(1.5+1e-5*x+0.2*t)))/2+0.25*(10+3*log(0.25))+0.75*(20+3*log(0.75))'
  []
  [neutral_potential_0_exact]
    type = ParsedFunction
    expression = '5.5-5*exp(-0.1*(1.5+1e-5*x+0.2*t))+10+3*log(0.25)'
  []
  [neutral_potential_1_exact]
    type = ParsedFunction
    expression = '5.5-5*exp(-0.1*(1.5+1e-5*x+0.2*t))+20+3*log(0.75)'
  []
  [neutral_potential_0_enrichment_exact]
    type = ParsedFunction
    expression = '10'
  []
  [neutral_potential_1_enrichment_exact]
    type = ParsedFunction
    expression = '20'
  []
  [sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_component_0_exact]
    type = ParsedFunction
    expression = '0.22*exp(0.1*(1.5+1e-5*x+0.2*t))'
  []
  [sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_component_1_exact]
    type = ParsedFunction
    expression = '0.66*exp(0.1*(1.5+1e-5*x+0.2*t))'
  []
  # Backward-Euler rates for the manufactured step from t=0 to t=1.
  [sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_component_0_rate_exact]
    type = ParsedFunction
    expression = '0.22*exp(0.1*(1.5+1e-5*x+0.2*t))*(1-exp(-0.02))'
  []
  [sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_component_1_rate_exact]
    type = ParsedFunction
    expression = '0.66*exp(0.1*(1.5+1e-5*x+0.2*t))*(1-exp(-0.02))'
  []
  [reference_relative_mass_flux_antiderivative_exact]
    type = ParsedFunction
    expression = '-(2*0.25/(1.1*0.1))*exp(0.1*(1.5+1e-5*x+0.2*t))'
  []
  [reference_component_0_flux_antiderivative_exact]
    type = ParsedFunction
    expression = '-0.25*(2*0.25/(1.1*0.1))*exp(0.1*(1.5+1e-5*x+0.2*t))'
  []
  [reference_component_1_flux_antiderivative_exact]
    type = ParsedFunction
    expression = '-0.75*(2*0.25/(1.1*0.1))*exp(0.1*(1.5+1e-5*x+0.2*t))'
  []
  # current source = (backward-Euler reference storage rate + Div_X W_alpha)/J.
  [current_component_0_source]
    type = ParsedFunction
    expression = '0.4*0.25*2*exp(0.1*(1.5+1e-5*x+0.2*t))*(1-exp(-0.02))-0.25*2*exp(0.1*(1.5+1e-5*x+0.2*t))*0.25*0.1*(1e-5)^2/(1.1*1.1)'
  []
  [current_component_1_source]
    type = ParsedFunction
    expression = '0.4*0.75*2*exp(0.1*(1.5+1e-5*x+0.2*t))*(1-exp(-0.02))-0.75*2*exp(0.1*(1.5+1e-5*x+0.2*t))*0.25*0.1*(1e-5)^2/(1.1*1.1)'
  []
  [reference_component_0_source_exact]
    type = ParsedFunction
    expression = '1.1*(0.4*0.25*2*exp(0.1*(1.5+1e-5*x+0.2*t))*(1-exp(-0.02))-0.25*2*exp(0.1*(1.5+1e-5*x+0.2*t))*0.25*0.1*(1e-5)^2/(1.1*1.1))'
  []
  [reference_component_1_source_exact]
    type = ParsedFunction
    expression = '1.1*(0.4*0.75*2*exp(0.1*(1.5+1e-5*x+0.2*t))*(1-exp(-0.02))-0.75*2*exp(0.1*(1.5+1e-5*x+0.2*t))*0.25*0.1*(1e-5)^2/(1.1*1.1))'
  []
[]

[ICs]
  [ux_ic]
    type = FunctionIC
    variable = ux
    function = ux_exact
  []
  [pressure_target_ic]
    type = FunctionIC
    variable = pressure_target
    function = pressure_exact
  []
  [pressure_ic]
    type = FunctionIC
    variable = pressure
    function = pressure_backbone_exact
  []
  [pressure_enr_ic]
    type = FunctionIC
    variable = pressure_enr
    function = pressure_enrichment_exact
  []
  [temperature_ic]
    type = FunctionIC
    variable = temperature
    function = temperature_exact
  []
  [porosity_ic]
    type = FunctionIC
    variable = porosity
    function = porosity_exact
  []
  [eta0_ic]
    type = FunctionIC
    variable = eta0
    function = eta0_exact
  []
  [eta1_ic]
    type = FunctionIC
    variable = eta1
    function = eta1_exact
  []
  [neutral_potential_0_ic]
    type = FunctionIC
    variable = neutral_potential_0
    function = zero
  []
  [neutral_potential_0_enr_ic]
    type = FunctionIC
    variable = neutral_potential_0_enr
    function = neutral_potential_0_enrichment_exact
  []
  [neutral_potential_1_ic]
    type = FunctionIC
    variable = neutral_potential_1
    function = zero
  []
  [neutral_potential_1_enr_ic]
    type = FunctionIC
    variable = neutral_potential_1_enr
    function = neutral_potential_1_enrichment_exact
  []
  [sum_component_0_ic]
    type = FunctionIC
    variable = sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_component_0
    function = sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_component_0_exact
  []
  [sum_component_1_ic]
    type = FunctionIC
    variable = sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_component_1
    function = sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_component_1_exact
  []
[]

!include ../../../input/includes/materials/solid_kinematics_1d.i

[Materials]
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
  [ideal_mixture_eos]
    type = ADIdealMixtureFluidEOSMaterial
    pressure = pressure
    pressure_enrichment = pressure_enr
    temperature = temperature
    porosity = porosity
    component_mass_fractions = 'eta0 eta1'
    reference_density = 2
    reference_pressure = 1
    compressibility = 0.1
    mixture_constant = 0.01
    component_reference_potentials = '10 20'
  []
  [pressure_closure_residual]
    type = ADParsedMaterial
    coupled_variables = 'pressure_target'
    material_property_names = 'pressure_total'
    property_name = pressure_closure_residual
    expression = 'pressure_total-pressure_target'
  []
  [neutral_potential_0_closure_residual]
    type = ADParsedMaterial
    material_property_names = 'neutral_potential_0_total neutral_component_potential_0'
    property_name = neutral_potential_0_closure_residual
    expression = 'neutral_potential_0_total-neutral_component_potential_0'
  []
  [neutral_potential_1_closure_residual]
    type = ADParsedMaterial
    material_property_names = 'neutral_potential_1_total neutral_component_potential_1'
    property_name = neutral_potential_1_closure_residual
    expression = 'neutral_potential_1_total-neutral_component_potential_1'
  []
  [component_partial_density_0]
    type = ADParsedMaterial
    coupled_variables = 'eta0'
    material_property_names = 'intrinsic_density_from_eos'
    property_name = component_partial_density_0
    expression = 'intrinsic_density_from_eos*eta0'
  []
  [component_partial_density_1]
    type = ADParsedMaterial
    coupled_variables = 'eta1'
    material_property_names = 'intrinsic_density_from_eos'
    property_name = component_partial_density_1
    expression = 'intrinsic_density_from_eos*eta1'
  []
  [fluid_legendre_relation_residual]
    type = ADParsedMaterial
    coupled_variables = 'eta0 eta1'
    material_property_names = 'intrinsic_density_from_eos specific_helmholtz_free_energy neutral_component_potential_0 neutral_component_potential_1 pressure_total'
    property_name = fluid_legendre_relation_residual
    expression = 'pressure_total-intrinsic_density_from_eos*(eta0*neutral_component_potential_0+eta1*neutral_component_potential_1-specific_helmholtz_free_energy)'
  []
  [neutral_component_euler_residual]
    type = ADParsedMaterial
    coupled_variables = 'eta0 eta1'
    material_property_names = 'intrinsic_density_from_eos specific_helmholtz_free_energy neutral_component_potential_0 neutral_component_potential_1 pressure_total'
    property_name = neutral_component_euler_residual
    expression = 'eta0*neutral_component_potential_0+eta1*neutral_component_potential_1-specific_helmholtz_free_energy-pressure_total/intrinsic_density_from_eos'
  []
  [darcy_flux]
    type = ADStandardDarcyReferenceFluxMaterial
    pressure = pressure
    pressure_enrichment = pressure_enr
    intrinsic_density_source = material
    intrinsic_density_name = intrinsic_density_from_eos
    permeability = 0.25
    viscosity = 1
  []
  [component_0_flux]
    type = ADReferenceFluidComponentFluxMaterial
    component_mass_fraction = eta0_exact
    current_component_source = current_component_0_source
    reference_component_flux_name = reference_component_0_flux
    reference_component_source_name = reference_component_0_source
  []
  [component_1_flux]
    type = ADReferenceFluidComponentFluxMaterial
    component_mass_fraction = eta1_exact
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
  [pressure_target_prescribed]
    type = FunctionAux
    variable = pressure_target
    function = pressure_exact
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [temperature_prescribed]
    type = FunctionAux
    variable = temperature
    function = temperature_exact
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [porosity_prescribed]
    type = FunctionAux
    variable = porosity
    function = porosity_exact
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [eta0_prescribed]
    type = FunctionAux
    variable = eta0
    function = eta0_exact
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [eta1_prescribed]
    type = FunctionAux
    variable = eta1
    function = eta1_exact
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [sum_component_0_rate]
    type = FunctionAux
    variable = sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_component_0_rate_aux
    function = sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_component_0_rate_exact
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [sum_component_1_rate]
    type = FunctionAux
    variable = sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_component_1_rate_aux
    function = sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_component_1_rate_exact
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
    anchor_value = 2.5
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
    anchor_value = 10
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
    anchor_value = 20
  []
  [sum_component_0_balance]
    type = ADReferenceFluidComponentBalance
    variable = sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_component_0
    reference_component_flux = reference_component_0_flux
    reference_component_source = reference_component_0_source
  []
  [sum_component_1_balance]
    type = ADReferenceFluidComponentBalance
    variable = sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_component_1
    reference_component_flux = reference_component_1_flux
    reference_component_source = reference_component_1_source
  []
[]

[BCs]
  [sum_component_0_exact]
    type = FunctionDirichletBC
    variable = sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_component_0
    boundary = 'left right'
    function = sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_component_0_exact
  []
  [sum_component_1_exact]
    type = FunctionDirichletBC
    variable = sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_component_1
    boundary = 'left right'
    function = sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_component_1_exact
  []
[]

[Postprocessors]
  [ux_l2]
    type = ElementL2Error
    variable = ux
    function = ux_exact
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
  [intrinsic_density_l2]
    type = ADMaterialScalarL2Error
    property = intrinsic_density_from_eos
    function = intrinsic_density_exact
  []
  [current_phase_mass_density_l2]
    type = ADMaterialScalarL2Error
    property = current_phase_mass_density
    function = current_phase_mass_density_exact
  []
  [component_partial_density_0_l2]
    type = ADMaterialScalarL2Error
    property = component_partial_density_0
    function = component_partial_density_0_exact
  []
  [component_partial_density_1_l2]
    type = ADMaterialScalarL2Error
    property = component_partial_density_1
    function = component_partial_density_1_exact
  []
  [specific_helmholtz_l2]
    type = ADMaterialScalarL2Error
    property = specific_helmholtz_free_energy
    function = specific_helmholtz_exact
  []
  [mass_fraction_sum_l2]
    type = ADMaterialScalarL2Error
    property = mass_fraction_sum
    function = mass_fraction_sum_exact
  []
  [pressure_identity_l2]
    type = ADMaterialScalarL2Error
    property = pressure_from_helmholtz_density_derivative
    function = pressure_exact
  []
  [pressure_identity_residual_l2]
    type = ADMaterialScalarL2Error
    property = pressure_identity_residual
    function = zero
  []
  [fluid_legendre_relation_l2]
    type = ADMaterialScalarL2Error
    property = fluid_legendre_relation_residual
    function = zero
  []
  [neutral_component_euler_l2]
    type = ADMaterialScalarL2Error
    property = neutral_component_euler_residual
    function = zero
  []
  [eos_neutral_potential_0_l2]
    type = ADMaterialScalarL2Error
    property = neutral_component_potential_0
    function = neutral_potential_0_exact
  []
  [eos_neutral_potential_1_l2]
    type = ADMaterialScalarL2Error
    property = neutral_component_potential_1
    function = neutral_potential_1_exact
  []
  [neutral_potential_0_total_l2]
    type = ADMaterialScalarL2Error
    property = neutral_potential_0_total
    function = neutral_potential_0_exact
  []
  [neutral_potential_1_total_l2]
    type = ADMaterialScalarL2Error
    property = neutral_potential_1_total
    function = neutral_potential_1_exact
  []
  [neutral_potential_0_gradient_l2]
    type = ADMaterialVectorL2Error
    property = neutral_potential_0_total_gradient
    gradient_function = neutral_potential_0_exact
  []
  [neutral_potential_1_gradient_l2]
    type = ADMaterialVectorL2Error
    property = neutral_potential_1_total_gradient
    gradient_function = neutral_potential_1_exact
  []
  [neutral_potential_0_enrichment_l2]
    type = ElementL2Error
    variable = neutral_potential_0_enr
    function = neutral_potential_0_enrichment_exact
  []
  [neutral_potential_1_enrichment_l2]
    type = ElementL2Error
    variable = neutral_potential_1_enr
    function = neutral_potential_1_enrichment_exact
  []
  [eos_sum_component_0_l2]
    type = ADMaterialScalarL2Error
    property = reference_component_storage_0
    function = sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_component_0_exact
  []
  [eos_sum_component_1_l2]
    type = ADMaterialScalarL2Error
    property = reference_component_storage_1
    function = sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_component_1_exact
  []
  [solved_sum_component_0_l2]
    type = ElementL2Error
    variable = sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_component_0
    function = sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_component_0_exact
  []
  [solved_sum_component_1_l2]
    type = ElementL2Error
    variable = sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_component_1
    function = sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_component_1_exact
  []
  [reference_relative_mass_flux_l2]
    type = ADMaterialVectorL2Error
    property = reference_relative_mass_flux
    gradient_function = reference_relative_mass_flux_antiderivative_exact
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
    type = ADMaterialScalarL2Error
    property = reference_component_0_source
    function = reference_component_0_source_exact
  []
  [reference_component_1_source_l2]
    type = ADMaterialScalarL2Error
    property = reference_component_1_source
    function = reference_component_1_source_exact
  []
  [sum_component_0_rate_integral]
    type = ElementIntegralVariablePostprocessor
    variable = sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_component_0_rate_aux
  []
  [sum_component_1_rate_integral]
    type = ElementIntegralVariablePostprocessor
    variable = sum_xi_J_phi_xi_fluid_intrinsic_density_xi_eta_xi_component_1_rate_aux
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
    pp_names = 'sum_component_0_rate_integral net_outward_reference_component_0_flux reference_component_0_source_integral'
    pp_coefs = '1 1 -1'
  []
  [direct_summed_eq32_component_1_global_balance]
    type = LinearCombinationPostprocessor
    pp_names = 'sum_component_1_rate_integral net_outward_reference_component_1_flux reference_component_1_source_integral'
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
