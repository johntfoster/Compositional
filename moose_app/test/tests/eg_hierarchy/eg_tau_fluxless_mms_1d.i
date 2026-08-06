!include ../../../input/includes/common/solver_defaults.i
!include ../../../input/includes/common/eg_tau_defaults.i

mesh_nx := 8
tau_initial_shift := 0.0
all_boundaries = 'left right'

!include ../../../input/includes/mesh/generated_1d_q2.i
!include ../../../input/includes/fields/eg_tau.i

[Functions]
  [tau_initial]
    type = ParsedFunction
    expression = 'sin(pi*x)-${tau_initial_shift}'
  []
  [tau_enrichment_initial]
    type = ParsedFunction
    expression = '${tau_initial_shift}'
  []
  [tau_exact]
    type = ParsedFunction
    expression = 'sin(pi*x)+t'
  []
  [tau_evolution_forcing]
    type = ParsedFunction
    expression = '1'
  []
  [zero]
    type = ParsedFunction
    expression = '0'
  []
[]

[ICs]
  [tau_ic]
    type = FunctionIC
    variable = tau
    function = tau_initial
  []
  [tau_enr_ic]
    type = FunctionIC
    variable = tau_enr
    function = tau_enrichment_initial
  []
[]

!include ../../../input/includes/materials/eg_tau_reconstruction.i
!include ../../../input/includes/materials/eg_tau_evolution.i
!include ../../../input/includes/operators/eg_tau_fluxless.i

[Postprocessors]
  [tau_material_l2]
    type = ADMaterialScalarL2Error
    property = tau_total
    function = tau_exact
    execute_on = TIMESTEP_END
  []
  [tau_gradient_l2]
    type = ADMaterialVectorL2Error
    property = tau_total_gradient
    gradient_function = tau_exact
    execute_on = TIMESTEP_END
  []
  [tau_enrichment_l2]
    type = ElementL2Error
    variable = tau_enr
    function = zero
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
