mesh_nx := 2
mesh_ny := 2
solve_dt := 0.01
solve_steps := 10

!include ../../../input/includes/mesh/generated_2d_q2.i
!include ../../../input/includes/fields/solid_q2_aux_2d.i

[Variables]
  [Fg00]
  []
  [Fg01]
  []
  [Fg11]
  []
  [Jg]
  []
[]

[AuxVariables]
  [Fg10]
  []
  [vg_x]
  []
  [vg_y]
  []
  [Wg_x]
  []
  [Wg_y]
  []
  [rho_g]
  []
  [active_g]
  []
  [det_Fg]
    family = MONOMIAL
    order = CONSTANT
  []
  [jg_det_residual]
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
  [vg_x_exact]
    type = ParsedFunction
    expression = '0.08*x+0.12*y'
  []
  [vg_y_exact]
    type = ParsedFunction
    expression = '-0.03*y'
  []
  [Fg00_exact]
    type = ParsedFunction
    expression = 'exp(0.08*t)'
  []
  [Fg01_exact]
    type = ParsedFunction
    expression = '0.12*(exp(0.08*t)-exp(-0.03*t))/(0.08+0.03)'
  []
  [Fg11_exact]
    type = ParsedFunction
    expression = 'exp(-0.03*t)'
  []
  [Jg_exact]
    type = ParsedFunction
    expression = 'exp(0.05*t)'
  []
[]

[ICs]
  [Fg00_ic]
    type = FunctionIC
    variable = Fg00
    function = one
  []
  [Fg01_ic]
    type = FunctionIC
    variable = Fg01
    function = zero
  []
  [Fg11_ic]
    type = FunctionIC
    variable = Fg11
    function = one
  []
  [Jg_ic]
    type = FunctionIC
    variable = Jg
    function = one
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
  [Fg10_ic]
    type = FunctionIC
    variable = Fg10
    function = zero
  []
  [vg_x_ic]
    type = FunctionIC
    variable = vg_x
    function = vg_x_exact
  []
  [vg_y_ic]
    type = FunctionIC
    variable = vg_y
    function = vg_y_exact
  []
  [Wg_x_ic]
    type = FunctionIC
    variable = Wg_x
    function = zero
  []
  [Wg_y_ic]
    type = FunctionIC
    variable = Wg_y
    function = zero
  []
  [rho_g_ic]
    type = FunctionIC
    variable = rho_g
    function = one
  []
  [active_g_ic]
    type = FunctionIC
    variable = active_g
    function = one
  []
[]

[UserObjects]
  [phases]
    type = PhaseRegistry
    phases = 'solid gas'
    reference_phase = solid
  []
[]

!include ../../../input/includes/materials/solid_kinematics_2d.i

[Materials]
  [gas_history]
    type = ADPhaseHistoryKinematicsMaterial
    phase = gas
    phase_registry = phases
    phase_deformation_gradient = 'Fg00 Fg01 Fg10 Fg11'
    phase_jacobian = Jg
    phase_velocity = 'vg_x vg_y'
    reference_relative_mass_flux = 'Wg_x Wg_y'
    phase_density = rho_g
    active_fraction = active_g
  []
[]

[AuxKernels]
  [det_Fg_aux]
    type = ADMaterialRealAux
    variable = det_Fg
    property = gas_phase_deformation_gradient_determinant
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [jg_det_aux]
    type = ADMaterialRealAux
    variable = jg_det_residual
    property = gas_phase_jacobian_det_residual
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]

[Kernels]
  [Fg00_history]
    type = ADPhaseDeformationGradientHistory
    variable = Fg00
    phase = gas
    phase_registry = phases
    row = 0
    col = 0
  []
  [Fg01_history]
    type = ADPhaseDeformationGradientHistory
    variable = Fg01
    phase = gas
    phase_registry = phases
    row = 0
    col = 1
  []
  [Fg11_history]
    type = ADPhaseDeformationGradientHistory
    variable = Fg11
    phase = gas
    phase_registry = phases
    row = 1
    col = 1
  []
  [Jg_history]
    type = ADPhaseJacobianHistory
    variable = Jg
    phase = gas
    phase_registry = phases
  []
[]

[BCs]
  [Fg00_exact_bc]
    type = FunctionDirichletBC
    variable = Fg00
    boundary = 'left right bottom top'
    function = Fg00_exact
  []
  [Fg01_exact_bc]
    type = FunctionDirichletBC
    variable = Fg01
    boundary = 'left right bottom top'
    function = Fg01_exact
  []
  [Fg11_exact_bc]
    type = FunctionDirichletBC
    variable = Fg11
    boundary = 'left right bottom top'
    function = Fg11_exact
  []
  [Jg_exact_bc]
    type = FunctionDirichletBC
    variable = Jg
    boundary = 'left right bottom top'
    function = Jg_exact
  []
[]

[Postprocessors]
  [Fg00_l2]
    type = ElementL2Error
    variable = Fg00
    function = Fg00_exact
  []
  [Fg01_l2]
    type = ElementL2Error
    variable = Fg01
    function = Fg01_exact
  []
  [Fg11_l2]
    type = ElementL2Error
    variable = Fg11
    function = Fg11_exact
  []
  [Jg_l2]
    type = ElementL2Error
    variable = Jg
    function = Jg_exact
  []
  [det_Fg_l2]
    type = ElementL2Error
    variable = det_Fg
    function = Jg_exact
  []
  [jg_det_residual_l2]
    type = ElementL2Error
    variable = jg_det_residual
    function = zero
  []
[]

!include ../../../input/includes/executioner/transient_newton.i
!include ../../../input/includes/outputs/csv.i
