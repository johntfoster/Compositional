mesh_nx := 2
mesh_ny := 2
mesh_nz := 2

!include ../../../input/includes/mesh/generated_3d_q2.i
!include ../../../input/includes/fields/solid_q2_aux_3d.i
!include ../../../input/includes/fields/eg_pressure_legacy_aux.i
!include ../../../input/includes/fields/eg_capillary_pressure_aux.i

[AuxVariables]
  [intrinsic_density]
  []
  [phase_acceleration_x]
  []
  [phase_acceleration_y]
  []
  [phase_acceleration_z]
  []
  [W_x]
    family = MONOMIAL
    order = CONSTANT
  []
  [W_y]
    family = MONOMIAL
    order = CONSTANT
  []
  [W_z]
    family = MONOMIAL
    order = CONSTANT
  []
[]

[Functions]
  [zero]
    type = ParsedFunction
    expression = '0'
  []
  [one]
    type = ParsedFunction
    expression = '1'
  []
  [pressure_exact]
    type = ParsedFunction
    expression = 'x+y+z'
  []
  [capillary_exact]
    type = ParsedFunction
    expression = '2*(x+y+z)'
  []
  [density_exact]
    type = ParsedFunction
    expression = '2'
  []
  [flux_exact]
    type = ParsedFunction
    expression = '-3'
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
  [capillary_ic]
    type = FunctionIC
    variable = capillary_pressure
    function = capillary_exact
  []
  [capillary_enr_ic]
    type = FunctionIC
    variable = capillary_pressure_enr
    function = zero
  []
  [density_ic]
    type = FunctionIC
    variable = intrinsic_density
    function = density_exact
  []
  [acceleration_x_ic]
    type = FunctionIC
    variable = phase_acceleration_x
    function = one
  []
  [acceleration_y_ic]
    type = FunctionIC
    variable = phase_acceleration_y
    function = one
  []
  [acceleration_z_ic]
    type = FunctionIC
    variable = phase_acceleration_z
    function = one
  []
[]

[UserObjects]
  [phases]
    type = PhaseRegistry
    phases = 'matrix brine'
    reference_phase = matrix
    momentum_models = 'reference relative_flux'
  []
[]

!include ../../../input/includes/materials/solid_kinematics_3d.i
!include ../../../input/includes/materials/eg_pressure_legacy_reconstruction.i
!include ../../../input/includes/materials/eg_capillary_pressure_reconstruction.i

[Materials]
  [brine_darcy]
    type = ADStandardDarcyReferenceFluxMaterial
    phase = brine
    phase_registry = phases
    pressure = pressure
    pressure_enrichment = pressure_enr
    intrinsic_density_source = coupled
    intrinsic_density = intrinsic_density
    permeability = 3
    viscosity = 2
  []
[]

[AuxKernels]
  [W_x_aux]
    type = ADMaterialRealVectorValueAux
    variable = W_x
    property = reference_relative_mass_flux
    component = 0
    execute_on = INITIAL
  []
  [W_y_aux]
    type = ADMaterialRealVectorValueAux
    variable = W_y
    property = reference_relative_mass_flux
    component = 1
    execute_on = INITIAL
  []
  [W_z_aux]
    type = ADMaterialRealVectorValueAux
    variable = W_z
    property = reference_relative_mass_flux
    component = 2
    execute_on = INITIAL
  []
[]

[Postprocessors]
  [flux_x_l2]
    type = ElementL2Error
    variable = W_x
    function = flux_exact
    execute_on = INITIAL
  []
  [flux_y_l2]
    type = ElementL2Error
    variable = W_y
    function = flux_exact
    execute_on = INITIAL
  []
  [flux_z_l2]
    type = ElementL2Error
    variable = W_z
    function = flux_exact
    execute_on = INITIAL
  []
[]

!include ../../../input/includes/executioner/steady_material.i
!include ../../../input/includes/outputs/csv.i
