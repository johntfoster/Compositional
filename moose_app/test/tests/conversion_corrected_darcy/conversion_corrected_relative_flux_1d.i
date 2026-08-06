mesh_nx := 2

!include ../../../input/includes/mesh/generated_1d_q2.i
!include ../../../input/includes/fields/solid_q2_aux_1d.i

[AuxVariables]
  [pressure]
    order = FIRST
  []
  [tau]
    order = FIRST
  []
  [solid_velocity]
  []
  [W_x]
    family = MONOMIAL
    order = CONSTANT
  []
  [resistance]
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
  [solid_velocity_exact]
    type = ParsedFunction
    expression = '0.5'
  []
  [flux_exact]
    type = ParsedFunction
    expression = '8/3'
  []
  [resistance_exact]
    type = ParsedFunction
    expression = '1.5'
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
  [solid_velocity_ic]
    type = FunctionIC
    variable = solid_velocity
    function = solid_velocity_exact
  []
[]

!include ../../../input/includes/materials/solid_kinematics_1d.i

[Materials]
  [phase_state]
    type = ADGenericConstantMaterial
    prop_names = 'phase_fraction bulk_density conversion_source'
    prop_values = '0.5 2 1'
  []
  [conversion_corrected_flux]
    type = ADConversionCorrectedDarcyReferenceFluxMaterial
    phase_fraction_name = phase_fraction
    bulk_density_name = bulk_density
    conversion_source_name = conversion_source
    pressure = pressure
    tau = tau
    solid_velocity = solid_velocity
    permeability = 1
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
  [resistance_aux]
    type = ADMaterialRealAux
    variable = resistance
    property = conversion_corrected_darcy_resistance
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
  [resistance_l2]
    type = ElementL2Error
    variable = resistance
    function = resistance_exact
    execute_on = INITIAL
  []
[]

!include ../../../input/includes/executioner/steady_material.i
!include ../../../input/includes/outputs/csv.i
