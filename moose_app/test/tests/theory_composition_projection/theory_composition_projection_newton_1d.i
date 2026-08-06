[Mesh]
  type = GeneratedMesh
  dim = 1
  nx = 1
[]

[Variables]
  [pi0]
    family = MONOMIAL
    order = CONSTANT
  []
  [pi1]
    family = MONOMIAL
    order = CONSTANT
  []
[]

[AuxVariables]
  [eta0]
  []
  [eta1]
  []
  [phase_fraction]
  []
[]

[ICs]
  [eta0_ic]
    type = ConstantIC
    variable = eta0
    value = 0.25
  []
  [eta1_ic]
    type = ConstantIC
    variable = eta1
    value = 0.75
  []
  [phase_fraction_ic]
    type = ConstantIC
    variable = phase_fraction
    value = 0.4
  []
[]

[UserObjects]
  [phases]
    type = PhaseRegistry
    phases = 'solid fluid'
    reference_phase = solid
  []
[]

[Materials]
  [constants]
    type = ADGenericConstantMaterial
    prop_names = 'intrinsic_density phase_pressure'
    prop_values = '5 7'
  []
  [specific_helmholtz]
    type = ADDerivativeParsedMaterial
    coupled_variables = 'eta0 eta1'
    property_name = specific_helmholtz
    expression = '2*eta0^2 + 3*eta1^2'
    derivative_order = 1
  []
  [electric_enthalpy]
    type = ADDerivativeParsedMaterial
    coupled_variables = 'eta0 eta1'
    property_name = electric_enthalpy
    expression = 'eta0*eta1'
    derivative_order = 1
  []
  [fluid_projection]
    type = ADTheoryCompositionProjectionMaterial
    phase_registry = phases
    phase = fluid
    mass_fractions = 'eta0 eta1'
    phase_fraction = phase_fraction
    intrinsic_density_name = intrinsic_density
    phase_pressure_name = phase_pressure
    specific_helmholtz_name = specific_helmholtz
    electric_enthalpy_name = electric_enthalpy
    storage_multiplier_mode = coupled
    storage_multipliers = 'pi0 pi1'
    property_prefix = fluid_projection
  []
[]

[Kernels]
  [component_projection]
    type = ADMaterialPropertyResidual
    variable = pi0
    property = fluid_projection_projection_residual_0
  []
  [phase_pressure_storage]
    type = ADMaterialPropertyResidual
    variable = pi1
    property = fluid_projection_phase_pressure_storage_residual
  []
[]

[Functions]
  [pi0_exact]
    type = ConstantFunction
    value = -0.575
  []
  [pi1_exact]
    type = ConstantFunction
    value = 3.375
  []
  [zero]
    type = ConstantFunction
    value = 0
  []
[]

[Postprocessors]
  [pi0_l2]
    type = ElementL2Error
    variable = pi0
    function = pi0_exact
  []
  [pi1_l2]
    type = ElementL2Error
    variable = pi1
    function = pi1_exact
  []
  [projection_l2]
    type = ADMaterialScalarL2Error
    property = fluid_projection_projection_residual_0
    function = zero
  []
  [pressure_storage_l2]
    type = ADMaterialScalarL2Error
    property = fluid_projection_phase_pressure_storage_residual
    function = zero
  []
[]

[Executioner]
  type = Steady
  solve_type = NEWTON
  nl_abs_tol = 1e-13
  nl_rel_tol = 1e-13
[]

[Outputs]
  csv = true
[]
