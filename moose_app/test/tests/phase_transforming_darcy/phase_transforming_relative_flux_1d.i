mesh_nx := 2

!include ../../../input/includes/mesh/generated_1d_q2.i
!include ../../../input/includes/fields/solid_q2_aux_1d.i

[AuxVariables]
  [pressure]
  []
  [tau]
  []
  [W_x]
    family = MONOMIAL
    order = CONSTANT
  []
[]

[Functions]
  [zero]
    type = ParsedFunction
    expression = '0'
  []
  [pressure_exact]
    type = ParsedFunction
    expression = 'x'
  []
  [tau_exact]
    type = ParsedFunction
    expression = '3*x'
  []
  [flux_exact]
    type = ParsedFunction
    expression = '10/3'
  []
[]

[ICs]
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
  [tau_ic]
    type = FunctionIC
    variable = tau
    function = tau_exact
  []
[]

!include ../../../input/includes/materials/solid_kinematics_1d.i

[Materials]
  [phase_state]
    type = ADGenericConstantMaterial
    prop_names = 'intrinsic_density bulk_density conversion_source phase_active relative_permeability'
    prop_values = '4 2 1 1 1'
  []
  [transforming_flux]
    type = ADPhaseTransformingDarcyReferenceFluxMaterial
    pressure = pressure
    intrinsic_density_source = material
    intrinsic_density_name = intrinsic_density
    bulk_density_name = bulk_density
    conversion_source_name = conversion_source
    phase_active_name = phase_active
    tau = tau
    solid_displacements = ux
    permeability = 1
    viscosity = 2
    relative_permeability_name = relative_permeability
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
[]

[Postprocessors]
  [flux_l2]
    type = ElementL2Error
    variable = W_x
    function = flux_exact
    execute_on = INITIAL
  []
[]

[Problem]
  solve = false
[]

[Executioner]
  type = Transient
  num_steps = 1
  dt = 1
[]

!include ../../../input/includes/outputs/csv.i
