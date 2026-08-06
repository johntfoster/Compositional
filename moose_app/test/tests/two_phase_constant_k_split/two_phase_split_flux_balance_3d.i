mesh_nx := 2
mesh_ny := 2
mesh_nz := 2
solve_dt := 1
solve_steps := 1

!include ../../../input/includes/mesh/generated_3d_q2.i
!include ../../../input/includes/fields/solid_q2_aux_3d.i
!include ../../../input/includes/fields/eg_pressure_pair_aux.i

[Variables]
  [component_storage]
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
  [storage0_from_split]
    family = MONOMIAL
    order = CONSTANT
  []
  [component_flux_x]
    family = MONOMIAL
    order = CONSTANT
  []
  [component_flux_y]
    family = MONOMIAL
    order = CONSTANT
  []
  [component_flux_z]
    family = MONOMIAL
    order = CONSTANT
  []
[]

[ICs]
  [component_storage_ic]
    type = FunctionIC
    variable = component_storage
    function = storage0_exact
  []
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
  [pressure0_ic]
    type = FunctionIC
    variable = pressure0
    function = pressure0_exact
  []
  [pressure0_enr_ic]
    type = FunctionIC
    variable = pressure0_enr
    function = zero
  []
  [pressure1_ic]
    type = FunctionIC
    variable = pressure1
    function = pressure1_exact
  []
  [pressure1_enr_ic]
    type = FunctionIC
    variable = pressure1_enr
    function = zero
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
  [pressure0_exact]
    type = ParsedFunction
    expression = 'x + y + z'
  []
  [pressure1_exact]
    type = ParsedFunction
    expression = '2*x - y + 3*z'
  []
  [storage0_exact]
    type = ParsedFunction
    expression = '0.24'
  []
  [component_flux_x_exact]
    type = ParsedFunction
    expression = '-8/3'
  []
  [component_flux_y_exact]
    type = ParsedFunction
    expression = '-2/3'
  []
  [component_flux_z_exact]
    type = ParsedFunction
    expression = '-10/3'
  []
[]

!include ../../../input/includes/materials/solid_kinematics_3d.i
!include ../../../input/includes/materials/eg_pressure_pair_reconstruction.i

[Materials]
  [split]
    type = ADTwoPhaseConstantKEquilibriumMaterial
    total_porosity = phi
    phase0_density = rho0
    phase1_density = rho1
    overall_mass_fractions = 'z0 z1'
    k_values = '2 0.5'
  []
  [darcy0]
    type = ADStandardDarcyReferenceFluxMaterial
    pressure = pressure0
    pressure_enrichment = pressure0_enr
    intrinsic_density = rho0
    permeability = 1
    viscosity = 1
    reference_relative_mass_flux_name = phase0_reference_relative_mass_flux
    darcy_mobility_ref_name = phase0_darcy_mobility_ref
  []
  [darcy1]
    type = ADStandardDarcyReferenceFluxMaterial
    pressure = pressure1
    pressure_enrichment = pressure1_enr
    intrinsic_density = rho1
    permeability = 1
    viscosity = 1
    reference_relative_mass_flux_name = phase1_reference_relative_mass_flux
    darcy_mobility_ref_name = phase1_darcy_mobility_ref
  []
  [component_flux]
    type = ADTwoPhaseSplitComponentFluxMaterial
    component = 0
    current_component_source = zero
  []
[]

[AuxKernels]
  [storage0_aux]
    type = ADMaterialRealAux
    variable = storage0_from_split
    property = total_reference_component_storage_0
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [component_flux_x_aux]
    type = ADMaterialRealVectorValueAux
    variable = component_flux_x
    property = reference_component_flux
    component = 0
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [component_flux_y_aux]
    type = ADMaterialRealVectorValueAux
    variable = component_flux_y
    property = reference_component_flux
    component = 1
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [component_flux_z_aux]
    type = ADMaterialRealVectorValueAux
    variable = component_flux_z
    property = reference_component_flux
    component = 2
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]

[Kernels]
  [component_balance]
    type = ADReferenceFluidComponentBalance
    variable = component_storage
  []
[]

[BCs]
  [exact]
    type = FunctionDirichletBC
    variable = component_storage
    boundary = 'left right bottom top back front'
    function = storage0_exact
  []
[]

[Postprocessors]
  [component_l2]
    type = ElementL2Error
    variable = component_storage
    function = storage0_exact
  []
  [split_storage_l2]
    type = ElementL2Error
    variable = storage0_from_split
    function = storage0_exact
  []
  [component_flux_x_l2]
    type = ElementL2Error
    variable = component_flux_x
    function = component_flux_x_exact
  []
  [component_flux_y_l2]
    type = ElementL2Error
    variable = component_flux_y
    function = component_flux_y_exact
  []
  [component_flux_z_l2]
    type = ElementL2Error
    variable = component_flux_z
    function = component_flux_z_exact
  []
[]

!include ../../../input/includes/executioner/transient_newton.i
!include ../../../input/includes/outputs/csv.i
