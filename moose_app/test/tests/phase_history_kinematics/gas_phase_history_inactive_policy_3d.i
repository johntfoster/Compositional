mesh_nx := 2
mesh_ny := 2
mesh_nz := 2
solve_dt := 0.1
solve_steps := 2

!include ../../../input/includes/mesh/generated_3d_q2.i
!include ../../../input/includes/fields/solid_q2_aux_3d.i

[Variables]
  [Fg00]
  []
  [Jg]
  []
[]

[AuxVariables]
  [Fg01]
  []
  [Fg02]
  []
  [Fg10]
  []
  [Fg11]
  []
  [Fg12]
  []
  [Fg20]
  []
  [Fg21]
  []
  [Fg22]
  []
  [vg_x]
  []
  [vg_y]
  []
  [vg_z]
  []
  [Wg_x]
  []
  [Wg_y]
  []
  [Wg_z]
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
  [cg_z]
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
    expression = 'x+y+z'
  []
  [vg_y_exact]
    type = ParsedFunction
    expression = '2*x-y+z'
  []
  [vg_z_exact]
    type = ParsedFunction
    expression = '-x+3*y+2*z'
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
  [uz_ic]
    type = FunctionIC
    variable = uz
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
  [Fg02_ic]
    type = FunctionIC
    variable = Fg02
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
  [Fg12_ic]
    type = FunctionIC
    variable = Fg12
    function = zero
  []
  [Fg20_ic]
    type = FunctionIC
    variable = Fg20
    function = zero
  []
  [Fg21_ic]
    type = FunctionIC
    variable = Fg21
    function = zero
  []
  [Fg22_ic]
    type = FunctionIC
    variable = Fg22
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
  [vg_z_ic]
    type = FunctionIC
    variable = vg_z
    function = vg_z_exact
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
  [Wg_z_ic]
    type = FunctionIC
    variable = Wg_z
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

!include ../../../input/includes/materials/solid_kinematics_3d.i

[Materials]
  [gas_history]
    type = ADPhaseHistoryKinematicsMaterial
    phase = gas
    phase_registry = phases
    phase_deformation_gradient = 'Fg00 Fg01 Fg02 Fg10 Fg11 Fg12 Fg20 Fg21 Fg22'
    phase_jacobian = Jg
    phase_velocity = 'vg_x vg_y vg_z'
    reference_relative_mass_flux = 'Wg_x Wg_y Wg_z'
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
  [cg_z_aux]
    type = ADMaterialRealVectorValueAux
    variable = cg_z
    property = gas_phase_reference_convective_velocity
    component = 2
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
    boundary = 'left right bottom top back front'
    function = one
  []
  [Jg_bc]
    type = FunctionDirichletBC
    variable = Jg
    boundary = 'left right bottom top back front'
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
  [cg_z_l2]
    type = ElementL2Error
    variable = cg_z
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
