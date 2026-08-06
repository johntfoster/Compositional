mesh_nx := 4
solve_dt := 0.01
solve_steps := 10

!include ../../../input/includes/mesh/generated_1d_q2.i
!include ../../../input/includes/fields/solid_q2_aux_1d.i

[Variables]
  [Fo00]
  []
  [Jo]
  []
[]

[AuxVariables]
  [vo_x]
  []
  [Wo_x]
  []
  [rho_o]
  []
  [active_o]
  []
  [det_Fo]
    family = MONOMIAL
    order = CONSTANT
  []
  [jo_det_residual]
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
  [vo_x_exact]
    type = ParsedFunction
    expression = '0.1*x'
  []
  [Fo00_exact]
    type = ParsedFunction
    expression = 'exp(0.1*t)'
  []
[]

[ICs]
  [Fo00_ic]
    type = FunctionIC
    variable = Fo00
    function = one
  []
  [Jo_ic]
    type = FunctionIC
    variable = Jo
    function = one
  []
  [ux_ic]
    type = FunctionIC
    variable = ux
    function = zero
  []
  [vo_x_ic]
    type = FunctionIC
    variable = vo_x
    function = vo_x_exact
  []
  [Wo_x_ic]
    type = FunctionIC
    variable = Wo_x
    function = zero
  []
  [rho_o_ic]
    type = FunctionIC
    variable = rho_o
    function = one
  []
  [active_o_ic]
    type = FunctionIC
    variable = active_o
    function = one
  []
[]

[UserObjects]
  [phases]
    type = PhaseRegistry
    phases = 'solid oil'
    reference_phase = solid
  []
[]

!include ../../../input/includes/materials/solid_kinematics_1d.i

[Materials]
  [oil_history]
    type = ADPhaseHistoryKinematicsMaterial
    phase = oil
    phase_registry = phases
    phase_deformation_gradient = 'Fo00'
    phase_jacobian = Jo
    phase_velocity = 'vo_x'
    reference_relative_mass_flux = 'Wo_x'
    phase_density = rho_o
    active_fraction = active_o
  []
[]

[AuxKernels]
  [det_Fo_aux]
    type = ADMaterialRealAux
    variable = det_Fo
    property = oil_phase_deformation_gradient_determinant
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [jo_det_aux]
    type = ADMaterialRealAux
    variable = jo_det_residual
    property = oil_phase_jacobian_det_residual
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]

[Kernels]
  [Fo00_history]
    type = ADPhaseDeformationGradientHistory
    variable = Fo00
    phase = oil
    phase_registry = phases
    row = 0
    col = 0
  []
  [Jo_history]
    type = ADPhaseJacobianHistory
    variable = Jo
    phase = oil
    phase_registry = phases
  []
[]

[BCs]
  [Fo00_exact_bc]
    type = FunctionDirichletBC
    variable = Fo00
    boundary = 'left right'
    function = Fo00_exact
  []
  [Jo_exact_bc]
    type = FunctionDirichletBC
    variable = Jo
    boundary = 'left right'
    function = Fo00_exact
  []
[]

[Postprocessors]
  [Fo00_l2]
    type = ElementL2Error
    variable = Fo00
    function = Fo00_exact
  []
  [Jo_l2]
    type = ElementL2Error
    variable = Jo
    function = Fo00_exact
  []
  [det_Fo_l2]
    type = ElementL2Error
    variable = det_Fo
    function = Fo00_exact
  []
  [jo_det_residual_l2]
    type = ElementL2Error
    variable = jo_det_residual
    function = zero
  []
[]

!include ../../../input/includes/executioner/transient_newton.i
!include ../../../input/includes/outputs/csv.i
