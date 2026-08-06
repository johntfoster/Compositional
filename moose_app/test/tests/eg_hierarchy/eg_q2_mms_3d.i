!include ../../../input/includes/common/solver_defaults.i

eg_epsilon := -1.0
eg_sigma := 12.0
eg_tau_anchor := 1.0
eg_permeability := 1.0
eg_viscosity := 1.0
eg_fluid_density := 1.0

mesh_nx := 1
mesh_ny := 1
mesh_nz := 1
all_boundaries = 'left right bottom top back front'
solid_shear_modulus := 5.0
solid_lame_lambda := 7.0
solid_biot := 0.35

!include ../../../input/includes/mesh/generated_3d_q2.i
!include ../../../input/includes/fields/solid_q2_3d.i
!include ../../../input/includes/fields/eg_pressure_tau.i

[Functions]
  [ux_exact]
    type = ParsedFunction
    expression = '0.03*x*(1-x)'
  []
  [uy_exact]
    type = ParsedFunction
    expression = '0.025*y*(1-y)'
  []
  [uz_exact]
    type = ParsedFunction
    expression = '0.02*z*(1-z)'
  []
  [p_exact]
    type = ParsedFunction
    expression = 'sin(pi*x)*sin(pi*y)*sin(pi*z)'
  []
  [pressure_source]
    type = ParsedFunction
    expression = '3*pi*pi*sin(pi*x)*sin(pi*y)*sin(pi*z)'
  []
  [tau_initial]
    type = ParsedFunction
    expression = 'x+2*y+3*z'
  []
  [tau_exact]
    type = ParsedFunction
    expression = 'x+2*y+3*z+4*t'
  []
  [tau_evolution_forcing]
    type = ParsedFunction
    expression = '4'
  []
  [body_x]
    type = ParsedFunction
    expression = '-(5*(-0.06+(-0.06)/(1+0.03*(1-2*x))^2)+7*(-0.06)*(1-log((1+0.03*(1-2*x))*(1+0.025*(1-2*y))*(1+0.02*(1-2*z))))/(1+0.03*(1-2*x))^2-0.35*pi*cos(pi*x)*sin(pi*y)*sin(pi*z)*(1+0.025*(1-2*y))*(1+0.02*(1-2*z)))'
  []
  [body_y]
    type = ParsedFunction
    expression = '-(5*(-0.05+(-0.05)/(1+0.025*(1-2*y))^2)+7*(-0.05)*(1-log((1+0.03*(1-2*x))*(1+0.025*(1-2*y))*(1+0.02*(1-2*z))))/(1+0.025*(1-2*y))^2-0.35*pi*sin(pi*x)*cos(pi*y)*sin(pi*z)*(1+0.03*(1-2*x))*(1+0.02*(1-2*z)))'
  []
  [body_z]
    type = ParsedFunction
    expression = '-(5*(-0.04+(-0.04)/(1+0.02*(1-2*z))^2)+7*(-0.04)*(1-log((1+0.03*(1-2*x))*(1+0.025*(1-2*y))*(1+0.02*(1-2*z))))/(1+0.02*(1-2*z))^2-0.35*pi*sin(pi*x)*sin(pi*y)*cos(pi*z)*(1+0.03*(1-2*x))*(1+0.025*(1-2*y)))'
  []
[]

[ICs]
  [ux_ic]
    type = FunctionIC
    variable = ux
    function = ux_exact
  []
  [uy_ic]
    type = FunctionIC
    variable = uy
    function = uy_exact
  []
  [uz_ic]
    type = FunctionIC
    variable = uz
    function = uz_exact
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

!include ../../../input/includes/materials/solid_kinematics_3d.i
!include ../../../input/includes/materials/eg_reconstruction.i
!include ../../../input/includes/materials/darcy_pressure_flux.i
!include ../../../input/includes/materials/solid_stress_eg_pressure.i
!include ../../../input/includes/materials/eg_tau_evolution.i
!include ../../../input/includes/operators/eg_pressure_diffusion.i
!include ../../../input/includes/operators/eg_tau_fluxless.i
!include ../../../input/includes/operators/solid_momentum_3d.i

[Postprocessors]
  [ux_l2]
    type = ElementL2Error
    variable = ux
    function = ux_exact
    execute_on = TIMESTEP_END
  []
  [uy_l2]
    type = ElementL2Error
    variable = uy
    function = uy_exact
    execute_on = TIMESTEP_END
  []
  [uz_l2]
    type = ElementL2Error
    variable = uz
    function = uz_exact
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
