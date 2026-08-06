mesh_nx := 2
mesh_ny := 2
mesh_nz := 2
solve_dt := 1
solve_steps := 1

!include ../../../input/includes/mesh/generated_3d_q2.i
!include ../../../input/includes/fields/solid_q2_aux_3d.i
!include ../../../input/includes/fields/eg_pressure_legacy_aux.i

[Variables]
  [component_storage]
  []
[]

[AuxVariables]
  [temperature]
  []
  [porosity]
  []
  [eta0]
  []
  [eta1]
  []
  [storage0_from_eos]
    family = MONOMIAL
    order = CONSTANT
  []
[]

[ICs]
  [component_storage_ic]
    type = FunctionIC
    variable = component_storage
    function = component_storage_exact
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
  [pressure_ic]
    type = FunctionIC
    variable = pressure
    function = pressure_exact
  []
  [pressure_enr_ic]
    type = FunctionIC
    variable = pressure_enr
    function = zero
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
[]

[Functions]
  [zero]
    type = ParsedFunction
    expression = '0'
  []
  [zero_vector]
    type = ParsedVectorFunction
    expression_x = '0'
    expression_y = '0'
    expression_z = '0'
  []
  [one_half]
    type = ParsedFunction
    expression = '0.5'
  []
  [pressure_exact]
    type = ParsedFunction
    expression = 'x + y + z'
  []
  [temperature_exact]
    type = ParsedFunction
    expression = '300'
  []
  [porosity_exact]
    type = ParsedFunction
    expression = '0.25'
  []
  [eta0_exact]
    type = ParsedFunction
    expression = '0.5'
  []
  [eta1_exact]
    type = ParsedFunction
    expression = '0.5'
  []
  [component_storage_exact]
    type = ParsedFunction
    expression = '0.25*exp(0.2*(x+y+z))'
  []
  [source]
    type = ParsedFunction
    expression = '-0.15*exp(0.2*(x+y+z))'
  []
[]

!include ../../../input/includes/materials/solid_kinematics_3d.i
!include ../../../input/includes/materials/eg_pressure_legacy_reconstruction.i

[Materials]
  [eos]
    type = ADIdealMixtureFluidEOSMaterial
    pressure = pressure
    pressure_enrichment = pressure_enr
    temperature = temperature
    porosity = porosity
    component_mass_fractions = 'eta0 eta1'
    reference_density = 2
    reference_pressure = 0
    compressibility = 0.2
    mixture_constant = 0.01
    component_reference_potentials = '10 20'
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
  [component_flux]
    type = ADReferenceFluidComponentFluxMaterial
    component_mass_fraction = one_half
    current_component_extra_flux = zero_vector
    current_component_source = source
  []
[]

[AuxKernels]
  [storage0_aux]
    type = ADMaterialRealAux
    variable = storage0_from_eos
    property = reference_component_storage_0
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
    function = component_storage_exact
  []
[]

[Postprocessors]
  [component_l2]
    type = ElementL2Error
    variable = component_storage
    function = component_storage_exact
  []
  [storage0_l2]
    type = ElementL2Error
    variable = storage0_from_eos
    function = component_storage_exact
  []
[]

!include ../../../input/includes/executioner/transient_newton.i
!include ../../../input/includes/outputs/csv.i
