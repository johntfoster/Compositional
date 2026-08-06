[Mesh]
  [mesh]
    type = GeneratedMeshGenerator
    dim = 2
    nx = 2
    ny = 2
    elem_type = QUAD9
  []
[]

[Variables]
  [oil_pressure]
    family = LAGRANGE
    order = FIRST
  []
  [oil_pressure_enrichment]
    family = MONOMIAL
    order = CONSTANT
  []
  [water_saturation]
    family = BERNSTEIN
    order = SECOND
  []
  [water_saturation_enrichment]
    family = MONOMIAL
    order = CONSTANT
  []
  [gas_saturation]
    family = BERNSTEIN
    order = SECOND
  []
  [gas_saturation_enrichment]
    family = MONOMIAL
    order = CONSTANT
  []
  [water_oil_pressure_difference]
    family = LAGRANGE
    order = SECOND
  []
  [gas_oil_pressure_difference]
    family = LAGRANGE
    order = SECOND
  []
  [tau]
    family = LAGRANGE
    order = FIRST
  []
  [tau_enrichment]
    family = MONOMIAL
    order = CONSTANT
  []
  [fluid_temperature]
    family = LAGRANGE
    order = FIRST
  []
  [solid_temperature]
    family = LAGRANGE
    order = FIRST
  []
[]

[Functions]
  [oil_pressure]
    type = ParsedFunction
    expression = '1e7+2*x-3*y'
  []
  [water_pressure_difference]
    type = ConstantFunction
    value = -27579.029172672
  []
  [gas_pressure_difference]
    type = ConstantFunction
    value = 3447.378646584
  []
  [expected_pressure_gradient]
    type = ParsedFunction
    expression = '2*x-3*y'
  []
  [zero]
    type = ParsedFunction
    expression = '0'
  []
[]

[ICs]
  [oil_pressure]
    type = FunctionIC
    variable = oil_pressure
    function = oil_pressure
  []
  [water_saturation]
    type = ConstantIC
    variable = water_saturation
    value = 0.3
  []
  [gas_saturation]
    type = ConstantIC
    variable = gas_saturation
    value = 0.1
  []
  [fluid_temperature]
    type = ConstantIC
    variable = fluid_temperature
    value = 300
  []
  [solid_temperature]
    type = ConstantIC
    variable = solid_temperature
    value = 300
  []
[]

[Materials]
  [porosity]
    type = ADGenericConstantMaterial
    prop_names = solid_current_porosity
    prop_values = '0.2'
  []
[]

!include ../../../input/includes/materials/spe2_phase_pressure_closure.i
[Kernels]
  [hold_oil_pressure]
    type = ADTimeDerivative
    variable = oil_pressure
  []
  [hold_oil_pressure_enrichment]
    type = ADTimeDerivative
    variable = oil_pressure_enrichment
  []
  [hold_water_saturation]
    type = ADTimeDerivative
    variable = water_saturation
  []
  [hold_water_saturation_enrichment]
    type = ADTimeDerivative
    variable = water_saturation_enrichment
  []
  [hold_gas_saturation]
    type = ADTimeDerivative
    variable = gas_saturation
  []
  [hold_gas_saturation_enrichment]
    type = ADTimeDerivative
    variable = gas_saturation_enrichment
  []
  [hold_tau]
    type = ADTimeDerivative
    variable = tau
  []
  [hold_tau_enrichment]
    type = ADTimeDerivative
    variable = tau_enrichment
  []
  [hold_fluid_temperature]
    type = ADTimeDerivative
    variable = fluid_temperature
  []
  [hold_solid_temperature]
    type = ADTimeDerivative
    variable = solid_temperature
  []
[]

!include ../../../input/includes/operators/spe2_phase_pressure_closure.i

[Postprocessors]
  [water_pressure_difference_l2]
    type = ElementL2Error
    variable = water_oil_pressure_difference
    function = water_pressure_difference
  []
  [gas_pressure_difference_l2]
    type = ElementL2Error
    variable = gas_oil_pressure_difference
    function = gas_pressure_difference
  []
  [water_closure_l2]
    type = ADMaterialScalarL2Error
    property = spe2_phase_pressure_water_pressure_difference_closure_residual
    function = zero
  []
  [gas_closure_l2]
    type = ADMaterialScalarL2Error
    property = spe2_phase_pressure_gas_pressure_difference_closure_residual
    function = zero
  []
  [water_pressure_gradient_l2]
    type = ADMaterialVectorL2Error
    property = spe2_water_pressure_gradient
    gradient_function = expected_pressure_gradient
  []
  [gas_pressure_gradient_l2]
    type = ADMaterialVectorL2Error
    property = spe2_gas_pressure_gradient
    gradient_function = expected_pressure_gradient
  []
  [saturation_onsager_dissipation_l2]
    type = ADMaterialScalarL2Error
    property = spe2_saturation_onsager_dissipation_rate
    function = zero
  []
  [saturation_onsager_entropy_l2]
    type = ADMaterialScalarL2Error
    property = spe2_saturation_onsager_entropy_production_rate
    function = zero
  []
[]

[Executioner]
  type = Transient
  solve_type = NEWTON
  dt = 1
  num_steps = 1
  nl_abs_tol = 1e-12
  nl_rel_tol = 1e-12
[]

[Outputs]
  csv = true
[]

