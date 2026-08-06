mesh_nx := 4

!include ../../../input/includes/mesh/generated_1d_q2.i
!include ../../../input/includes/fields/solid_q2_aux_1d.i

[Variables]
  [equivalent_pressure]
    family = LAGRANGE
    order = FIRST
  []
  [equivalent_pressure_enrichment]
    family = MONOMIAL
    order = CONSTANT
  []
  [velocity_x]
    family = LAGRANGE
    order = FIRST
  []
[]

[AuxVariables]
  [phase0_saturation]
    family = LAGRANGE
    order = SECOND
  []
  [phase1_saturation]
    family = LAGRANGE
    order = SECOND
  []
  [phase0_saturation_enrichment]
    family = MONOMIAL
    order = CONSTANT
  []
  [phase1_saturation_enrichment]
    family = MONOMIAL
    order = CONSTANT
  []
[]

[Functions]
  [velocity_x_exact]
    type = ParsedFunction
    expression = '1+x'
  []
  [velocity_x_source]
    type = ParsedFunction
    expression = '1.7+x'
  []
[]

[ICs]
  [velocity_x_ic]
    type = FunctionIC
    variable = velocity_x
    function = velocity_x_exact
  []
[]

!include common.i
!include ../../../input/includes/materials/solid_kinematics_1d.i

[Kernels]
  [equivalent_pressure_diffusion]
    type = ADDiffusion
    variable = equivalent_pressure
  []
  [equivalent_pressure_enrichment_anchor]
    type = ADReaction
    variable = equivalent_pressure_enrichment
  []
  [velocity_x_reaction]
    type = ADReaction
    variable = velocity_x
  []
  [velocity_x_pressure]
    type = ADPhaseMomentumPressurePotentialGradientTerm
    variable = velocity_x
    component = 0
    phase_momentum_pressure_potential_gradient_name = test_phase0_momentum_pressure_potential_gradient
    coefficient = 0.5
  []
  [velocity_x_source]
    type = ADBodyForce
    variable = velocity_x
    function = velocity_x_source
  []
[]

[BCs]
  [equivalent_pressure_bc]
    type = FunctionDirichletBC
    variable = equivalent_pressure
    boundary = 'left right'
    function = equivalent_pressure_exact
  []
[]

[Postprocessors]
  [velocity_x_l2]
    type = ElementL2Error
    variable = velocity_x
    function = velocity_x_exact
  []
[]

!include ../../../input/includes/executioner/steady_newton.i
!include ../../../input/includes/outputs/csv.i
