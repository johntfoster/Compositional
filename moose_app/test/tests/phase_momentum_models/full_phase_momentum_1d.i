mesh_nx := 8
solve_dt := 0.1
solve_steps := 2

!include ../../../input/includes/mesh/generated_1d_q2.i
!include ../../../input/includes/fields/solid_q2_aux_1d.i
!include ../../../input/includes/fields/eg_pressure_potential_aux.i
!include ../../../input/includes/fields/eg_capillary_pressure_aux.i

[Variables]
  [v]
  []
[]

[AuxVariables]
  [rho]
  []
  [phi]
  []
[]

[Functions]
  [zero]
    type = ParsedFunction
    expression = '0'
  []
  [rho_exact]
    type = ParsedFunction
    expression = '2'
  []
  [phi_exact]
    type = ParsedFunction
    expression = '0.5'
  []
  [pressure_exact]
    type = ParsedFunction
    expression = 'x'
  []
  [capillary_exact]
    type = ParsedFunction
    expression = '2*x'
  []
  [velocity_exact]
    type = ParsedFunction
    expression = 't*x'
  []
  [momentum_forcing]
    type = ParsedFunction
    expression = '2*x*(1+t^2)+0.5+t*x'
  []
  [momentum_forcing_capillary]
    type = ParsedFunction
    expression = '2*x*(1+t^2)+1.5+t*x'
  []
[]

[ICs]
  [v_ic]
    type = FunctionIC
    variable = v
    function = velocity_exact
  []
  [ux_ic]
    type = FunctionIC
    variable = ux
    function = zero
  []
  [rho_ic]
    type = FunctionIC
    variable = rho
    function = rho_exact
  []
  [phi_ic]
    type = FunctionIC
    variable = phi
    function = phi_exact
  []
  [pressure_ic]
    type = FunctionIC
    variable = pressure_potential
    function = pressure_exact
  []
  [pressure_enr_ic]
    type = FunctionIC
    variable = pressure_potential_enr
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
[]

[UserObjects]
  [phases]
    type = PhaseRegistry
    phases = 'solid oil gas water'
    reference_phase = solid
    momentum_models = 'reference full relative_flux relative_flux'
  []
[]

!include ../../../input/includes/materials/solid_kinematics_1d.i
!include ../../../input/includes/materials/eg_pressure_potential_reconstruction.i
!include ../../../input/includes/materials/eg_capillary_pressure_reconstruction.i

[Kernels]
  [oil_momentum]
    type = ADRegisteredPhaseMomentum
    variable = v
    phase = oil
    phase_registry = phases
    component = 0
    phase_velocity = v
    solid_displacements = ux
    bulk_density = rho
    phase_fraction = phi
    pressure_potential = pressure_potential
    pressure_potential_enrichment = pressure_potential_enr
    viscosity = 4
    permeability = 1
    forcing = momentum_forcing
  []
[]

[BCs]
  [v_bc]
    type = FunctionDirichletBC
    variable = v
    boundary = 'left right'
    function = velocity_exact
  []
[]

[Postprocessors]
  [velocity_l2]
    type = ElementL2Error
    variable = v
    function = velocity_exact
  []
[]

!include ../../../input/includes/executioner/transient_newton.i
!include ../../../input/includes/outputs/csv.i
