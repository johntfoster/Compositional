!include ../../../input/includes/common/solver_defaults.i

eg_epsilon := -1.0
eg_sigma := 12.0
eg_tau_anchor := 1.0
eg_permeability := 1.0
eg_viscosity := 1.0
eg_fluid_density := 1.0

mesh_nx := 8
all_boundaries = 'left right'
solid_shear_modulus := 3.0
solid_lame_lambda := 5.0
solid_biot := 0.25

!include ../../../input/includes/mesh/generated_1d_q2.i
!include ../../../input/includes/fields/solid_q2_1d.i
!include ../../../input/includes/fields/eg_pressure_tau.i

[Functions]
  [ux_exact]
    type = ParsedFunction
    expression = '0.05*x*(1-x)'
  []
  [p_exact]
    type = ParsedFunction
    expression = 'sin(pi*x)'
  []
  [pressure_source]
    type = ParsedFunction
    expression = 'pi*pi*sin(pi*x)'
  []
  [tau_initial]
    type = ParsedFunction
    expression = 'x'
  []
  [tau_exact]
    type = ParsedFunction
    expression = 'x+3*t'
  []
  [tau_evolution_forcing]
    type = ParsedFunction
    expression = '3'
  []
  [body_x]
    type = ParsedFunction
    expression = '-(3*(-0.1+(-0.1)/(1+0.05*(1-2*x))^2)+5*(-0.1)*(1-log(1+0.05*(1-2*x)))/(1+0.05*(1-2*x))^2-0.25*pi*cos(pi*x))'
  []
[]

[ICs]
  [ux_ic]
    type = FunctionIC
    variable = ux
    function = ux_exact
  []
  [p_ic]
    type = FunctionIC
    variable = p
    function = p_exact
  []
  [tau_ic]
    type = FunctionIC
    variable = tau
    function = tau_initial
  []
[]

!include ../../../input/includes/materials/solid_kinematics_1d.i
!include ../../../input/includes/materials/eg_reconstruction.i
!include ../../../input/includes/materials/darcy_pressure_flux.i
!include ../../../input/includes/materials/solid_stress_eg_pressure.i
!include ../../../input/includes/materials/eg_tau_evolution.i
!include ../../../input/includes/operators/eg_pressure_diffusion.i
!include ../../../input/includes/operators/eg_tau_fluxless.i
!include ../../../input/includes/operators/solid_momentum_1d.i

[Postprocessors]
  [ux_l2]
    type = ElementL2Error
    variable = ux
    function = ux_exact
    execute_on = TIMESTEP_END
  []
  [p_total_l2]
    type = ElementL2Error
    variable = p_total
    function = p_exact
    execute_on = TIMESTEP_END
  []
  [tau_total_l2]
    type = ElementL2Error
    variable = tau_total
    function = tau_exact
    execute_on = TIMESTEP_END
  []
  [p_enrichment_average]
    type = ElementAverageValue
    variable = p_enr
    execute_on = TIMESTEP_END
  []
  [tau_enrichment_average]
    type = ElementAverageValue
    variable = tau_enr
    execute_on = TIMESTEP_END
  []
[]

!include ../../../input/includes/executioner/transient_newton.i
!include ../../../input/includes/outputs/csv.i
