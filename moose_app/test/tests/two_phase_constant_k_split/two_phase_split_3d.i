mesh_nx := 2
mesh_ny := 2
mesh_nz := 2
solve_dt := 1
solve_steps := 1

!include ../../../input/includes/mesh/generated_3d_q2.i
!include ../../../input/includes/fields/solid_q2_aux_3d.i

[Variables]
  [dummy]
  []
[]

[AuxVariables]
  [phi]
  []
  [rho0]
  []
  [rho1]
  []
  [z0]
  []
  [z1]
  []
  [beta]
    family = MONOMIAL
    order = CONSTANT
  []
  [phi0]
    family = MONOMIAL
    order = CONSTANT
  []
  [phi1]
    family = MONOMIAL
    order = CONSTANT
  []
  [storage0]
    family = MONOMIAL
    order = CONSTANT
  []
  [volume_residual]
    family = MONOMIAL
    order = CONSTANT
  []
[]

[ICs]
  [ux_ic]
    type = FunctionIC
    variable = ux
    function = zero
  []
  [uy_ic]
    type = FunctionIC
    variable = uy
    function = zero
  []
  [uz_ic]
    type = FunctionIC
    variable = uz
    function = zero
  []
  [phi_ic]
    type = FunctionIC
    variable = phi
    function = phi_exact
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
  [z0_ic]
    type = FunctionIC
    variable = z0
    function = z0_exact
  []
  [z1_ic]
    type = FunctionIC
    variable = z1
    function = z1_exact
  []
[]

[Functions]
  [zero]
    type = ParsedFunction
    expression = '0'
  []
  [phi_exact]
    type = ParsedFunction
    expression = '0.3'
  []
  [rho0_exact]
    type = ParsedFunction
    expression = '4'
  []
  [rho1_exact]
    type = ParsedFunction
    expression = '1'
  []
  [z0_exact]
    type = ParsedFunction
    expression = '0.5'
  []
  [z1_exact]
    type = ParsedFunction
    expression = '0.5'
  []
  [beta_exact]
    type = ParsedFunction
    expression = '0.5'
  []
  [phi0_exact]
    type = ParsedFunction
    expression = '0.06'
  []
  [phi1_exact]
    type = ParsedFunction
    expression = '0.24'
  []
  [storage0_exact]
    type = ParsedFunction
    expression = '0.24'
  []
[]

!include ../../../input/includes/materials/solid_kinematics_3d.i

[Materials]
  [split]
    type = ADTwoPhaseConstantKEquilibriumMaterial
    total_porosity = phi
    phase0_density = rho0
    phase1_density = rho1
    overall_mass_fractions = 'z0 z1'
    k_values = '2 0.5'
  []
[]

[AuxKernels]
  [beta_aux]
    type = ADMaterialRealAux
    variable = beta
    property = phase1_mass_fraction
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [phi0_aux]
    type = ADMaterialRealAux
    variable = phi0
    property = phase0_volume_fraction
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [phi1_aux]
    type = ADMaterialRealAux
    variable = phi1
    property = phase1_volume_fraction
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [storage0_aux]
    type = ADMaterialRealAux
    variable = storage0
    property = total_reference_component_storage_0
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [volume_residual_aux]
    type = ADMaterialRealAux
    variable = volume_residual
    property = volume_constraint_residual
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]

[Kernels]
  [dummy_null]
    type = NullKernel
    variable = dummy
  []
[]

[Postprocessors]
  [beta_l2]
    type = ElementL2Error
    variable = beta
    function = beta_exact
  []
  [phi0_l2]
    type = ElementL2Error
    variable = phi0
    function = phi0_exact
  []
  [phi1_l2]
    type = ElementL2Error
    variable = phi1
    function = phi1_exact
  []
  [storage0_l2]
    type = ElementL2Error
    variable = storage0
    function = storage0_exact
  []
  [volume_residual_l2]
    type = ElementL2Error
    variable = volume_residual
    function = zero
  []
[]

!include ../../../input/includes/executioner/transient_newton.i
!include ../../../input/includes/outputs/csv.i
