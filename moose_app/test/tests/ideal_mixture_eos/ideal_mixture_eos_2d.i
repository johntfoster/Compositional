[Mesh]
  type = GeneratedMesh
  dim = 2
  xmin = 0
  xmax = 1
  ymin = 0
  ymax = 1
  nx = 3
  ny = 3
[]

[Variables]
  [dummy]
  []
[]

[AuxVariables]
  [ux]
  []
  [uy]
  []
  [pressure]
  []
  [temperature]
  []
  [porosity]
  []
  [eta0]
  []
  [eta1]
  []
  [density_from_eos]
    family = MONOMIAL
    order = CONSTANT
  []
  [mass_fraction_sum_from_eos]
    family = MONOMIAL
    order = CONSTANT
  []
  [pressure_from_identity]
    family = MONOMIAL
    order = CONSTANT
  []
  [pressure_identity_residual]
    family = MONOMIAL
    order = CONSTANT
  []
  [storage0_from_eos]
    family = MONOMIAL
    order = CONSTANT
  []
  [storage1_from_eos]
    family = MONOMIAL
    order = CONSTANT
  []
  [mu0_from_eos]
    family = MONOMIAL
    order = CONSTANT
  []
  [mu1_from_eos]
    family = MONOMIAL
    order = CONSTANT
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
  [pressure_ic]
    type = FunctionIC
    variable = pressure
    function = pressure_exact
  []
  [temperature_ic]
    type = FunctionIC
    variable = temperature
    function = temperature_exact
  []
  [porosity_ic]
    type = FunctionIC
    variable = porosity
    function = porosity_exact
  []
  [eta0_ic]
    type = FunctionIC
    variable = eta0
    function = eta0_exact
  []
  [eta1_ic]
    type = FunctionIC
    variable = eta1
    function = eta1_exact
  []
[]

[Functions]
  [zero]
    type = ParsedFunction
    expression = '0'
  []
  [pressure_exact]
    type = ParsedFunction
    expression = '2.5'
  []
  [temperature_exact]
    type = ParsedFunction
    expression = '300'
  []
  [porosity_exact]
    type = ParsedFunction
    expression = '0.4'
  []
  [eta0_exact]
    type = ParsedFunction
    expression = '0.25'
  []
  [eta1_exact]
    type = ParsedFunction
    expression = '0.75'
  []
  [density_exact]
    type = ParsedFunction
    expression = '2*exp(0.1*(2.5 - 1))'
  []
  [storage0_exact]
    type = ParsedFunction
    expression = '0.4*2*exp(0.1*(2.5 - 1))*0.25'
  []
  [storage1_exact]
    type = ParsedFunction
    expression = '0.4*2*exp(0.1*(2.5 - 1))*0.75'
  []
  [mass_fraction_sum_exact]
    type = ParsedFunction
    expression = '1'
  []
  [pressure_identity_residual_exact]
    type = ParsedFunction
    expression = '0'
  []
  [mu0_exact]
    type = ParsedFunction
    expression = '((1 + 1/0.1) - (2.5 + 1/0.1)/exp(0.1*(2.5 - 1)))/2 + 2.5/(2*exp(0.1*(2.5 - 1))) + 10 + 0.01*300*log(0.25)'
  []
  [mu1_exact]
    type = ParsedFunction
    expression = '((1 + 1/0.1) - (2.5 + 1/0.1)/exp(0.1*(2.5 - 1)))/2 + 2.5/(2*exp(0.1*(2.5 - 1))) + 20 + 0.01*300*log(0.75)'
  []
[]

[Materials]
  [kinematics]
    type = ADSolidReferenceKinematics
    displacements = 'ux uy'
  []
  [eos]
    type = ADIdealMixtureFluidEOSMaterial
    pressure = pressure
    temperature = temperature
    porosity = porosity
    component_mass_fractions = 'eta0 eta1'
    reference_density = 2
    reference_pressure = 1
    compressibility = 0.1
    mixture_constant = 0.01
    component_reference_potentials = '10 20'
  []
[]

[AuxKernels]
  [density_aux]
    type = ADMaterialRealAux
    variable = density_from_eos
    property = intrinsic_density_from_eos
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [mass_fraction_sum_aux]
    type = ADMaterialRealAux
    variable = mass_fraction_sum_from_eos
    property = mass_fraction_sum
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [pressure_from_identity_aux]
    type = ADMaterialRealAux
    variable = pressure_from_identity
    property = pressure_from_helmholtz_density_derivative
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [pressure_identity_residual_aux]
    type = ADMaterialRealAux
    variable = pressure_identity_residual
    property = pressure_identity_residual
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [storage0_aux]
    type = ADMaterialRealAux
    variable = storage0_from_eos
    property = reference_component_storage_0
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [storage1_aux]
    type = ADMaterialRealAux
    variable = storage1_from_eos
    property = reference_component_storage_1
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [mu0_aux]
    type = ADMaterialRealAux
    variable = mu0_from_eos
    property = neutral_component_potential_0
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [mu1_aux]
    type = ADMaterialRealAux
    variable = mu1_from_eos
    property = neutral_component_potential_1
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]

[Kernels]
  [dummy_null]
    type = NullKernel
    variable = dummy
  []
[]

[Postprocessors]
  [density_l2]
    type = ElementL2Error
    variable = density_from_eos
    function = density_exact
  []
  [mass_fraction_sum_l2]
    type = ElementL2Error
    variable = mass_fraction_sum_from_eos
    function = mass_fraction_sum_exact
  []
  [pressure_identity_l2]
    type = ElementL2Error
    variable = pressure_from_identity
    function = pressure_exact
  []
  [pressure_identity_residual_l2]
    type = ElementL2Error
    variable = pressure_identity_residual
    function = pressure_identity_residual_exact
  []
  [storage0_l2]
    type = ElementL2Error
    variable = storage0_from_eos
    function = storage0_exact
  []
  [storage1_l2]
    type = ElementL2Error
    variable = storage1_from_eos
    function = storage1_exact
  []
  [mu0_l2]
    type = ElementL2Error
    variable = mu0_from_eos
    function = mu0_exact
  []
  [mu1_l2]
    type = ElementL2Error
    variable = mu1_from_eos
    function = mu1_exact
  []
[]

[Executioner]
  type = Transient
  start_time = 0
  dt = 1
  num_steps = 1
[]

[Outputs]
  console = true
  csv = true
[]
