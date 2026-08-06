mesh_nx := 2
mesh_ny := 2
solve_dt := 0.1
solve_steps := 2

!include ../../../input/includes/mesh/generated_2d_q2.i
!include ../../../input/includes/fields/solid_q2_aux_2d.i

[Variables]
  [Fg00]
  []
  [Jg]
  []
[]

[AuxVariables]
  [Fg01]
  []
  [Fg10]
  []
  [Fg11]
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
  [cg_x]
    family = MONOMIAL
    order = CONSTANT
  []
  [cg_y]
    family = MONOMIAL
    order = CONSTANT
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
    expression = 'x+y'
  []
  [vg_y_exact]
    type = ParsedFunction
    expression = '2*x-y'
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
  [Fg10_ic]
    type = FunctionIC
    variable = Fg10
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
    function = one
  []
  [Wg_y_ic]
    type = FunctionIC
    variable = Wg_y
    function = one
  []
  [rho_g_ic]
    type = FunctionIC
    variable = rho_g
    function = zero
  []
  [active_g_ic]
    type = FunctionIC
    variable = active_g
    function = zero
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
  [cg_x_aux]
    type = ADMaterialRealVectorValueAux
    variable = cg_x
    property = gas_phase_reference_convective_velocity
    component = 0
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [cg_y_aux]
    type = ADMaterialRealVectorValueAux
    variable = cg_y
    property = gas_phase_reference_convective_velocity
    component = 1
    execute_on = 'INITIAL TIMESTEP_END'
  []
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
  [Jg_history]
    type = ADPhaseJacobianHistory
    variable = Jg
    phase = gas
    phase_registry = phases
  []
[]

[BCs]
  [Fg00_bc]
    type = FunctionDirichletBC
    variable = Fg00
    boundary = 'left right bottom top'
    function = one
  []
  [Jg_bc]
    type = FunctionDirichletBC
    variable = Jg
    boundary = 'left right bottom top'
    function = one
  []
[]

[Postprocessors]
  [cg_x_l2]
    type = ElementL2Error
    variable = cg_x
    function = zero
    execute_on = 'INITIAL'
  []
  [cg_y_l2]
    type = ElementL2Error
    variable = cg_y
    function = zero
    execute_on = 'INITIAL'
  []
  [det_Fg_l2]
    type = ElementL2Error
    variable = det_Fg
    function = one
    execute_on = 'INITIAL'
  []
  [jg_det_residual_l2]
    type = ElementL2Error
    variable = jg_det_residual
    function = zero
    execute_on = 'INITIAL'
  []
  [Fg00_l2]
    type = ElementL2Error
    variable = Fg00
    function = one
  []
  [Jg_l2]
    type = ElementL2Error
    variable = Jg
    function = one
  []
[]

!include ../../../input/includes/executioner/transient_newton.i
!include ../../../input/includes/outputs/csv.i
