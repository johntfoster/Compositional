mesh_nx := 6
mesh_ny := 6
solve_dt := 1
solve_steps := 1

!include ../../../input/includes/mesh/generated_2d_q2.i
!include ../../../input/includes/fields/solid_q2_aux_2d.i

[Variables]
  [Fo00]
  []
[]

[AuxVariables]
  [Fo01]
  []
  [Fo10]
  []
  [Fo11]
  []
  [Jo]
  []
  [vo_x]
  []
  [vo_y]
  []
  [Wo_x]
  []
  [Wo_y]
  []
  [rho_o_bulk]
  []
  [active_o]
  []
  [co_x]
    family = MONOMIAL
    order = CONSTANT
  []
  [co_y]
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
  [two]
    type = ParsedFunction
    expression = '2'
  []
  [four]
    type = ParsedFunction
    expression = '4'
  []
  [quarter]
    type = ParsedFunction
    expression = '0.25'
  []
  [Fo00_exact]
    type = ParsedFunction
    expression = '1+t*(x+2*y)'
  []
  [material_derivative_source]
    type = ParsedFunction
    expression = 'x+2*y+5*t'
  []
[]

[ICs]
  [Fo00_ic]
    type = FunctionIC
    variable = Fo00
    function = Fo00_exact
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
  [Fo01_ic]
    type = FunctionIC
    variable = Fo01
    function = zero
  []
  [Fo10_ic]
    type = FunctionIC
    variable = Fo10
    function = zero
  []
  [Fo11_ic]
    type = FunctionIC
    variable = Fo11
    function = one
  []
  [Jo_ic]
    type = FunctionIC
    variable = Jo
    function = one
  []
  [vo_x_ic]
    type = FunctionIC
    variable = vo_x
    function = zero
  []
  [vo_y_ic]
    type = FunctionIC
    variable = vo_y
    function = zero
  []
  [Wo_x_ic]
    type = FunctionIC
    variable = Wo_x
    function = two
  []
  [Wo_y_ic]
    type = FunctionIC
    variable = Wo_y
    function = four
  []
  [rho_o_bulk_ic]
    type = FunctionIC
    variable = rho_o_bulk
    function = two
  []
  [active_o_ic]
    type = FunctionIC
    variable = active_o
    function = quarter
  []
[]

[UserObjects]
  [phases]
    type = PhaseRegistry
    phases = 'solid oil'
    reference_phase = solid
  []
[]

!include ../../../input/includes/materials/solid_kinematics_2d.i

[Materials]
  [oil_history]
    type = ADPhaseHistoryKinematicsMaterial
    phase = oil
    phase_registry = phases
    phase_deformation_gradient = 'Fo00 Fo01 Fo10 Fo11'
    phase_jacobian = Jo
    phase_velocity = 'vo_x vo_y'
    reference_relative_mass_flux = 'Wo_x Wo_y'
    phase_density = rho_o_bulk
    active_fraction = active_o
  []
[]

[AuxKernels]
  [co_x_aux]
    type = ADMaterialRealVectorValueAux
    variable = co_x
    property = oil_phase_reference_convective_velocity
    component = 0
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [co_y_aux]
    type = ADMaterialRealVectorValueAux
    variable = co_y
    property = oil_phase_reference_convective_velocity
    component = 1
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
    forcing = material_derivative_source
  []
[]

[BCs]
  [Fo00_exact_bc]
    type = FunctionDirichletBC
    variable = Fo00
    boundary = 'left right bottom top'
    function = Fo00_exact
  []
[]

[Postprocessors]
  [Fo00_l2]
    type = ElementL2Error
    variable = Fo00
    function = Fo00_exact
  []
  [co_x_l2]
    type = ElementL2Error
    variable = co_x
    function = one
  []
  [co_y_l2]
    type = ElementL2Error
    variable = co_y
    function = two
  []
[]

!include ../../../input/includes/executioner/transient_newton.i
!include ../../../input/includes/outputs/csv.i
