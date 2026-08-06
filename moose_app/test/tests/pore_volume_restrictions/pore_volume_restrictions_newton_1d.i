[Mesh]
  type = GeneratedMesh
  dim = 1
  nx = 1
[]

[Variables]
  [lambda]
    family = MONOMIAL
    order = CONSTANT
  []
[]

[AuxVariables]
  [S0]
  []
  [S1]
  []
[]

[ICs]
  [S0_ic]
    type = ConstantIC
    variable = S0
    value = 0.25
  []
  [S1_ic]
    type = ConstantIC
    variable = S1
    value = 0.75
  []
[]

[Materials]
  [restriction_data]
    type = ADGenericConstantMaterial
    prop_names = 'ps0 ps1 ws0 ws1 pf0 pf1 wf0 wf1 gamma0 gamma1'
    prop_values = '10 9 2 1 12 6 1 0.5 3 -2.5'
  []
  [restrictions]
    type = ADPoreVolumeRestrictionMaterial
    pore_volume_multiplier = lambda
    fluid_saturations = 'S0 S1'
    solid_pressure_names = 'ps0 ps1'
    solid_omega_plus_names = 'ws0 ws1'
    fluid_pressure_names = 'pf0 pf1'
    fluid_omega_plus_names = 'wf0 wf1'
    fluid_gamma_names = 'gamma0 gamma1'
    solid_restriction_names = 'solid0_restriction solid1_restriction'
  []
[]

[Kernels]
  [solve_shared_lambda]
    type = ADMaterialPropertyResidual
    variable = lambda
    property = total_fluid_pore_volume_restriction
  []
[]

[Functions]
  [lambda_exact]
    type = ConstantFunction
    value = -8
  []
  [zero]
    type = ConstantFunction
    value = 0
  []
[]

[Postprocessors]
  [lambda_l2]
    type = ElementL2Error
    variable = lambda
    function = lambda_exact
  []
  [solid0_l2]
    type = ADMaterialScalarL2Error
    property = solid0_restriction
    function = zero
  []
  [solid1_l2]
    type = ADMaterialScalarL2Error
    property = solid1_restriction
    function = zero
  []
  [fluid_l2]
    type = ADMaterialScalarL2Error
    property = total_fluid_pore_volume_restriction
    function = zero
  []
  [saturation_sum_l2]
    type = ADMaterialScalarL2Error
    property = fluid_saturation_sum_residual
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
