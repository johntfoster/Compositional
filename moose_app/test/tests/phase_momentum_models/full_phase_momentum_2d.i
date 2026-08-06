mesh_nx := 6
mesh_ny := 6
solve_dt := 0.1
solve_steps := 2

!include ../../../input/includes/mesh/generated_2d_q2.i
!include ../../../input/includes/fields/solid_q2_aux_2d.i
!include ../../../input/includes/fields/eg_pressure_potential_aux.i
!include ../../../input/includes/fields/eg_capillary_pressure_aux.i

[Variables]
  [vx]
  []
  [vy]
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
    expression = 'x+y'
  []
  [capillary_exact]
    type = ParsedFunction
    expression = '2*(x+y)'
  []
  [velocity_x_exact]
    type = ParsedFunction
    expression = 't*x'
  []
  [velocity_y_exact]
    type = ParsedFunction
    expression = 't*y'
  []
  [momentum_x_forcing]
    type = ParsedFunction
    expression = '2*x*(1+t^2)+0.5+t*x'
  []
  [momentum_y_forcing]
    type = ParsedFunction
    expression = '2*y*(1+t^2)+0.5+t*y'
  []
  [momentum_x_forcing_capillary]
    type = ParsedFunction
    expression = '2*x*(1+t^2)+1.5+t*x'
  []
  [momentum_y_forcing_capillary]
    type = ParsedFunction
    expression = '2*y*(1+t^2)+1.5+t*y'
  []
[]

[ICs]
  [vx_ic]
    type = FunctionIC
    variable = vx
    function = velocity_x_exact
  []
  [vy_ic]
    type = FunctionIC
    variable = vy
    function = velocity_y_exact
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

!include ../../../input/includes/materials/solid_kinematics_2d.i
!include ../../../input/includes/materials/eg_pressure_potential_reconstruction.i
!include ../../../input/includes/materials/eg_capillary_pressure_reconstruction.i

[Kernels]
  [oil_momentum_x]
    type = ADRegisteredPhaseMomentum
    variable = vx
    phase = oil
    phase_registry = phases
    component = 0
    phase_velocity = 'vx vy'
    solid_displacements = 'ux uy'
    bulk_density = rho
    phase_fraction = phi
    pressure_potential = pressure_potential
    pressure_potential_enrichment = pressure_potential_enr
    viscosity = 4
    permeability = 1
    forcing = momentum_x_forcing
  []
  [oil_momentum_y]
    type = ADRegisteredPhaseMomentum
    variable = vy
    phase = oil
    phase_registry = phases
    component = 1
    phase_velocity = 'vx vy'
    solid_displacements = 'ux uy'
    bulk_density = rho
    phase_fraction = phi
    pressure_potential = pressure_potential
    pressure_potential_enrichment = pressure_potential_enr
    viscosity = 4
    permeability = 1
    forcing = momentum_y_forcing
  []
[]

[BCs]
  [vx_bc]
    type = FunctionDirichletBC
    variable = vx
    boundary = 'left right bottom top'
    function = velocity_x_exact
  []
  [vy_bc]
    type = FunctionDirichletBC
    variable = vy
    boundary = 'left right bottom top'
    function = velocity_y_exact
  []
[]

[Postprocessors]
  [vx_l2]
    type = ElementL2Error
    variable = vx
    function = velocity_x_exact
  []
  [vy_l2]
    type = ElementL2Error
    variable = vy
    function = velocity_y_exact
  []
[]

!include ../../../input/includes/executioner/transient_newton.i
!include ../../../input/includes/outputs/csv.i
