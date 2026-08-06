mesh_nx := 8
solve_dt := 1
solve_steps := 1

!include ../../../input/includes/mesh/generated_1d_q2.i
!include ../../../input/includes/fields/solid_q2_aux_1d.i
!include ../../../input/includes/fields/eg_pressure_legacy_aux.i

[Variables]
  [component_storage]
  []
[]

[AuxVariables]
  [porosity]
  []
  [intrinsic_density]
  []
  [eta]
  []
  [storage_from_material]
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
  [porosity_ic]
    type = FunctionIC
    variable = porosity
    function = porosity_exact
  []
  [density_ic]
    type = FunctionIC
    variable = intrinsic_density
    function = density_exact
  []
  [eta_ic]
    type = FunctionIC
    variable = eta
    function = eta_exact
  []
[]

[Functions]
  [component_storage_exact]
    type = ParsedFunction
    expression = '0.5'
  []
  [pressure_exact]
    type = ParsedFunction
    expression = 'sin(pi*x)'
  []
  [porosity_exact]
    type = ParsedFunction
    expression = '0.25'
  []
  [density_exact]
    type = ParsedFunction
    expression = '4'
  []
  [eta_exact]
    type = ParsedFunction
    expression = '0.5'
  []
  [source]
    type = ParsedFunction
    expression = 'pi*pi*sin(pi*x)'
  []
  [zero_vector]
    type = ParsedVectorFunction
    expression_x = '0'
    expression_y = '0'
    expression_z = '0'
  []
  [zero]
    type = ParsedFunction
    expression = '0'
  []
  [one]
    type = ParsedFunction
    expression = '1'
  []
[]

!include ../../../input/includes/materials/solid_kinematics_1d.i
!include ../../../input/includes/materials/eg_pressure_legacy_reconstruction.i

[Materials]
  [storage]
    type = ADReferenceComponentStorageMaterial
    porosity = porosity
    intrinsic_density = intrinsic_density
    component_mass_fraction = eta
  []
  [darcy_flux]
    type = ADStandardDarcyReferenceFluxMaterial
    pressure = pressure
    pressure_enrichment = pressure_enr
    intrinsic_density = intrinsic_density
    permeability = 0.25
    viscosity = 1
  []
  [component_flux]
    type = ADReferenceFluidComponentFluxMaterial
    component_mass_fraction = one
    current_component_extra_flux = zero_vector
    current_component_source = source
  []
[]

[AuxKernels]
  [storage_material_aux]
    type = ADMaterialRealAux
    variable = storage_from_material
    property = reference_component_storage
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
    boundary = 'left right'
    function = component_storage_exact
  []
[]

[Postprocessors]
  [component_l2]
    type = ElementL2Error
    variable = component_storage
    function = component_storage_exact
  []
  [storage_closure_l2]
    type = ElementL2Error
    variable = storage_from_material
    function = component_storage_exact
  []
[]

!include ../../../input/includes/executioner/transient_newton.i
!include ../../../input/includes/outputs/csv.i
