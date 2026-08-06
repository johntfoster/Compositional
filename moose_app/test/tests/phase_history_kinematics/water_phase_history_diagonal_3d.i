mesh_nx := 1
mesh_ny := 1
mesh_nz := 1
solve_dt := 0.01
solve_steps := 10

!include ../../../input/includes/mesh/generated_3d_q2.i
!include ../../../input/includes/fields/solid_q2_aux_3d.i

[Variables]
  [Fw00]
  []
  [Fw11]
  []
  [Fw22]
  []
  [Jw]
  []
[]

[AuxVariables]
  [Fw01]
  []
  [Fw02]
  []
  [Fw10]
  []
  [Fw12]
  []
  [Fw20]
  []
  [Fw21]
  []
  [vw_x]
  []
  [vw_y]
  []
  [vw_z]
  []
  [Ww_x]
  []
  [Ww_y]
  []
  [Ww_z]
  []
  [rho_w]
  []
  [active_w]
  []
  [det_Fw]
    family = MONOMIAL
    order = CONSTANT
  []
  [jw_det_residual]
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
  [vw_x_exact]
    type = ParsedFunction
    expression = '0.04*x'
  []
  [vw_y_exact]
    type = ParsedFunction
    expression = '-0.02*y'
  []
  [vw_z_exact]
    type = ParsedFunction
    expression = '0.01*z'
  []
  [Fw00_exact]
    type = ParsedFunction
    expression = 'exp(0.04*t)'
  []
  [Fw11_exact]
    type = ParsedFunction
    expression = 'exp(-0.02*t)'
  []
  [Fw22_exact]
    type = ParsedFunction
    expression = 'exp(0.01*t)'
  []
  [Jw_exact]
    type = ParsedFunction
    expression = 'exp(0.03*t)'
  []
[]

[ICs]
  [Fw00_ic]
    type = FunctionIC
    variable = Fw00
    function = one
  []
  [Fw11_ic]
    type = FunctionIC
    variable = Fw11
    function = one
  []
  [Fw22_ic]
    type = FunctionIC
    variable = Fw22
    function = one
  []
  [Jw_ic]
    type = FunctionIC
    variable = Jw
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
  [uz_ic]
    type = FunctionIC
    variable = uz
    function = zero
  []
  [Fw01_ic]
    type = FunctionIC
    variable = Fw01
    function = zero
  []
  [Fw02_ic]
    type = FunctionIC
    variable = Fw02
    function = zero
  []
  [Fw10_ic]
    type = FunctionIC
    variable = Fw10
    function = zero
  []
  [Fw12_ic]
    type = FunctionIC
    variable = Fw12
    function = zero
  []
  [Fw20_ic]
    type = FunctionIC
    variable = Fw20
    function = zero
  []
  [Fw21_ic]
    type = FunctionIC
    variable = Fw21
    function = zero
  []
  [vw_x_ic]
    type = FunctionIC
    variable = vw_x
    function = vw_x_exact
  []
  [vw_y_ic]
    type = FunctionIC
    variable = vw_y
    function = vw_y_exact
  []
  [vw_z_ic]
    type = FunctionIC
    variable = vw_z
    function = vw_z_exact
  []
  [Ww_x_ic]
    type = FunctionIC
    variable = Ww_x
    function = zero
  []
  [Ww_y_ic]
    type = FunctionIC
    variable = Ww_y
    function = zero
  []
  [Ww_z_ic]
    type = FunctionIC
    variable = Ww_z
    function = zero
  []
  [rho_w_ic]
    type = FunctionIC
    variable = rho_w
    function = one
  []
  [active_w_ic]
    type = FunctionIC
    variable = active_w
    function = one
  []
[]

[UserObjects]
  [phases]
    type = PhaseRegistry
    phases = 'solid water'
    reference_phase = solid
  []
[]

!include ../../../input/includes/materials/solid_kinematics_3d.i

[Materials]
  [water_history]
    type = ADPhaseHistoryKinematicsMaterial
    phase = water
    phase_registry = phases
    phase_deformation_gradient = 'Fw00 Fw01 Fw02 Fw10 Fw11 Fw12 Fw20 Fw21 Fw22'
    phase_jacobian = Jw
    phase_velocity = 'vw_x vw_y vw_z'
    reference_relative_mass_flux = 'Ww_x Ww_y Ww_z'
    phase_density = rho_w
    active_fraction = active_w
  []
[]

[AuxKernels]
  [det_Fw_aux]
    type = ADMaterialRealAux
    variable = det_Fw
    property = water_phase_deformation_gradient_determinant
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [jw_det_aux]
    type = ADMaterialRealAux
    variable = jw_det_residual
    property = water_phase_jacobian_det_residual
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]

[Kernels]
  [Fw00_history]
    type = ADPhaseDeformationGradientHistory
    variable = Fw00
    phase = water
    phase_registry = phases
    row = 0
    col = 0
  []
  [Fw11_history]
    type = ADPhaseDeformationGradientHistory
    variable = Fw11
    phase = water
    phase_registry = phases
    row = 1
    col = 1
  []
  [Fw22_history]
    type = ADPhaseDeformationGradientHistory
    variable = Fw22
    phase = water
    phase_registry = phases
    row = 2
    col = 2
  []
  [Jw_history]
    type = ADPhaseJacobianHistory
    variable = Jw
    phase = water
    phase_registry = phases
  []
[]

[BCs]
  [Fw00_exact_bc]
    type = FunctionDirichletBC
    variable = Fw00
    boundary = 'left right bottom top front back'
    function = Fw00_exact
  []
  [Fw11_exact_bc]
    type = FunctionDirichletBC
    variable = Fw11
    boundary = 'left right bottom top front back'
    function = Fw11_exact
  []
  [Fw22_exact_bc]
    type = FunctionDirichletBC
    variable = Fw22
    boundary = 'left right bottom top front back'
    function = Fw22_exact
  []
  [Jw_exact_bc]
    type = FunctionDirichletBC
    variable = Jw
    boundary = 'left right bottom top front back'
    function = Jw_exact
  []
[]

[Postprocessors]
  [Fw00_l2]
    type = ElementL2Error
    variable = Fw00
    function = Fw00_exact
  []
  [Fw11_l2]
    type = ElementL2Error
    variable = Fw11
    function = Fw11_exact
  []
  [Fw22_l2]
    type = ElementL2Error
    variable = Fw22
    function = Fw22_exact
  []
  [Jw_l2]
    type = ElementL2Error
    variable = Jw
    function = Jw_exact
  []
  [det_Fw_l2]
    type = ElementL2Error
    variable = det_Fw
    function = Jw_exact
  []
  [jw_det_residual_l2]
    type = ElementL2Error
    variable = jw_det_residual
    function = zero
  []
[]

!include ../../../input/includes/executioner/transient_newton.i
!include ../../../input/includes/outputs/csv.i
