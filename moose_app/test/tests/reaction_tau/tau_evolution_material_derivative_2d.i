!include ../../../input/includes/common/solver_defaults.i
!include ../../../input/includes/common/eg_tau_defaults.i

mesh_nx := 6
mesh_ny := 6
all_boundaries = 'left right bottom top'
tau_reference_phase_velocity = 'vs_x vs_y'

!include ../../../input/includes/mesh/generated_2d_q2.i
!include ../../../input/includes/fields/eg_tau.i

[AuxVariables]
  [vs_x]
  []
  [vs_y]
  []
  [tau_material_derivative]
    family = MONOMIAL
    order = CONSTANT
  []
  [tau_convective_term]
    family = MONOMIAL
    order = CONSTANT
  []
  [tau_velocity_square]
    family = MONOMIAL
    order = CONSTANT
  []
  [tau_transfer_offset]
    family = MONOMIAL
    order = CONSTANT
  []
  [tau_evolution_residual]
    family = MONOMIAL
    order = CONSTANT
  []
[]

[Functions]
  [tau_initial]
    type = ParsedFunction
    expression = 'x+2*y'
  []
  [tau_exact]
    type = ParsedFunction
    expression = 'x+2*y+3*t'
  []
  [phase_velocity_x_exact]
    type = ParsedFunction
    expression = '0.25'
  []
  [phase_velocity_y_exact]
    type = ParsedFunction
    expression = '0.5'
  []
  [tau_evolution_forcing]
    type = ParsedFunction
    expression = '2.84375'
  []
  [zero]
    type = ParsedFunction
    expression = '0'
  []
  [convective_exact]
    type = ParsedFunction
    expression = '2.5'
  []
  [material_derivative_exact]
    type = ParsedFunction
    expression = '5.5'
  []
  [velocity_square_exact]
    type = ParsedFunction
    expression = '0.3125'
  []
  [transfer_offset_exact]
    type = ParsedFunction
    expression = '5.34375'
  []
[]

[ICs]
  [tau_ic]
    type = FunctionIC
    variable = tau
    function = tau_initial
  []
  [vs_x_ic]
    type = FunctionIC
    variable = vs_x
    function = phase_velocity_x_exact
  []
  [vs_y_ic]
    type = FunctionIC
    variable = vs_y
    function = phase_velocity_y_exact
  []
[]

[UserObjects]
  [phases]
    type = PhaseRegistry
    phases = 'solid oil'
    reference_phase = solid
  []
[]

!include ../../../input/includes/materials/eg_tau_reconstruction.i

[Materials]
  [scalar_constants]
    type = ADGenericConstantMaterial
    prop_names = 'solid_reference_J oil_bulk_phase_density oil_active'
    prop_values = '1 4 1'
  []
  [vector_constants]
    type = ADGenericConstantVectorMaterial
    prop_names = 'oil_reference_relative_mass_flux'
    prop_values = '2 4 0'
  []
  [oil_tau_derivative]
    type = ADPhaseTauMaterialDerivative
    phase = oil
    phase_registry = phases
    phase_kind = mobile
    tau = tau
    tau_enrichment = tau_enr
    phase_velocity = 'vs_x vs_y'
    bulk_density_name = oil_bulk_phase_density
    reference_relative_mass_flux_name = oil_reference_relative_mass_flux
    phase_active_name = oil_active
  []
[]

!include ../../../input/includes/materials/eg_tau_evolution_velocity.i

[AuxKernels]
  [tau_material_derivative_aux]
    type = ADMaterialRealAux
    variable = tau_material_derivative
    property = oil_tau_material_derivative
    execute_on = TIMESTEP_END
  []
  [tau_convective_term_aux]
    type = ADMaterialRealAux
    variable = tau_convective_term
    property = oil_tau_convective_term
    execute_on = TIMESTEP_END
  []
  [tau_velocity_square_aux]
    type = ADMaterialRealAux
    variable = tau_velocity_square
    property = oil_tau_velocity_square
    execute_on = TIMESTEP_END
  []
  [tau_transfer_offset_aux]
    type = ADMaterialRealAux
    variable = tau_transfer_offset
    property = oil_tau_transfer_offset
    execute_on = TIMESTEP_END
  []
  [tau_evolution_residual_aux]
    type = ADMaterialRealAux
    variable = tau_evolution_residual
    property = tau_evolution_residual
    execute_on = TIMESTEP_END
  []
[]

!include ../../../input/includes/operators/eg_tau_fluxless.i

[Postprocessors]
  [tau_l2]
    type = ADMaterialScalarL2Error
    property = tau_total
    function = tau_exact
    execute_on = TIMESTEP_END
  []
  [tau_material_derivative_l2]
    type = ElementL2Error
    variable = tau_material_derivative
    function = material_derivative_exact
    execute_on = TIMESTEP_END
  []
  [tau_convective_term_l2]
    type = ElementL2Error
    variable = tau_convective_term
    function = convective_exact
    execute_on = TIMESTEP_END
  []
  [tau_velocity_square_l2]
    type = ElementL2Error
    variable = tau_velocity_square
    function = velocity_square_exact
    execute_on = TIMESTEP_END
  []
  [tau_transfer_offset_l2]
    type = ElementL2Error
    variable = tau_transfer_offset
    function = transfer_offset_exact
    execute_on = TIMESTEP_END
  []
  [tau_evolution_residual_l2]
    type = ElementL2Error
    variable = tau_evolution_residual
    function = zero
    execute_on = TIMESTEP_END
  []
[]

!include ../../../input/includes/executioner/transient_newton.i
!include ../../../input/includes/outputs/csv.i
