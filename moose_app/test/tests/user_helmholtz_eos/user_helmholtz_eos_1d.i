[Mesh]
  type = GeneratedMesh
  dim = 1
  nx = 2
[]

[AuxVariables]
  [rho0]
  []
  [rho1]
  []
  [temperature]
  []
  [porosity]
  []
  [helmholtz]
    family = MONOMIAL
    order = CONSTANT
  []
  [pressure]
    family = MONOMIAL
    order = CONSTANT
  []
  [mu0]
    family = MONOMIAL
    order = CONSTANT
  []
  [mu1]
    family = MONOMIAL
    order = CONSTANT
  []
  [intrinsic_density]
    family = MONOMIAL
    order = CONSTANT
  []
  [bulk_density]
    family = MONOMIAL
    order = CONSTANT
  []
  [specific_helmholtz]
    family = MONOMIAL
    order = CONSTANT
  []
  [entropy_density]
    family = MONOMIAL
    order = CONSTANT
  []
  [hessian_00]
    family = MONOMIAL
    order = CONSTANT
  []
  [hessian_01]
    family = MONOMIAL
    order = CONSTANT
  []
  [hessian_11]
    family = MONOMIAL
    order = CONSTANT
  []
  [dmu1_dT]
    family = MONOMIAL
    order = CONSTANT
  []
[]

[Functions]
  [one]
    type = ParsedFunction
    expression = '1'
  []
  [two]
    type = ParsedFunction
    expression = '2'
  []
  [three]
    type = ParsedFunction
    expression = '3'
  []
  [quarter]
    type = ParsedFunction
    expression = '0.25'
  []
  [helmholtz_exact]
    type = ParsedFunction
    expression = '30*log(2)-43'
  []
  [pressure_exact]
    type = ParsedFunction
    expression = '55'
  []
  [mu0_exact]
    type = ParsedFunction
    expression = '4'
  []
  [mu1_exact]
    type = ParsedFunction
    expression = '4+15*log(2)'
  []
  [bulk_density_exact]
    type = ParsedFunction
    expression = '0.75'
  []
  [specific_helmholtz_exact]
    type = ParsedFunction
    expression = '(30*log(2)-43)/3'
  []
  [entropy_density_exact]
    type = ParsedFunction
    expression = '15-10*log(2)'
  []
  [nineteen]
    type = ParsedFunction
    expression = '19'
  []
  [four]
    type = ParsedFunction
    expression = '4'
  []
  [eleven_point_five]
    type = ParsedFunction
    expression = '11.5'
  []
  [dmu1_dT_exact]
    type = ParsedFunction
    expression = '5*log(2)'
  []
[]

[ICs]
  [rho0_ic]
    type = FunctionIC
    variable = rho0
    function = one
  []
  [rho1_ic]
    type = FunctionIC
    variable = rho1
    function = two
  []
  [temperature_ic]
    type = FunctionIC
    variable = temperature
    function = three
  []
  [porosity_ic]
    type = FunctionIC
    variable = porosity
    function = quarter
  []
[]

[UserObjects]
  [phases]
    type = PhaseRegistry
    phases = 'solid oil gas water hydrate'
    reference_phase = solid
  []
[]

[Materials]
  [user_oil_helmholtz]
    type = ADDerivativeParsedMaterial
    coupled_variables = 'rho0 rho1 temperature'
    property_name = oil_helmholtz_density
    constant_names = 'K rho_ref R'
    constant_expressions = '4 2 5'
    expression = '0.5*K*(rho0+rho1-rho_ref)^2 + R*temperature*(rho0*(log(rho0)-1)+rho1*(log(rho1)-1))'
    derivative_order = 2
    enable_jit = true
  []
  [oil_eos_closure]
    type = ADHelmholtzEOSClosureMaterial
    phase = oil
    phase_registry = phases
    partial_densities = 'rho0 rho1'
    temperature = temperature
    porosity = porosity
    helmholtz_density_name = oil_helmholtz_density
  []
[]

[AuxKernels]
  [helmholtz_aux]
    type = ADMaterialRealAux
    variable = helmholtz
    property = oil_helmholtz_density
    execute_on = INITIAL
  []
  [pressure_aux]
    type = ADMaterialRealAux
    variable = pressure
    property = oil_pressure_from_eos
    execute_on = INITIAL
  []
  [mu0_aux]
    type = ADMaterialRealAux
    variable = mu0
    property = oil_chemical_potential_0
    execute_on = INITIAL
  []
  [mu1_aux]
    type = ADMaterialRealAux
    variable = mu1
    property = oil_chemical_potential_1
    execute_on = INITIAL
  []
  [intrinsic_density_aux]
    type = ADMaterialRealAux
    variable = intrinsic_density
    property = oil_intrinsic_density
    execute_on = INITIAL
  []
  [bulk_density_aux]
    type = ADMaterialRealAux
    variable = bulk_density
    property = oil_bulk_phase_density
    execute_on = INITIAL
  []
  [specific_helmholtz_aux]
    type = ADMaterialRealAux
    variable = specific_helmholtz
    property = oil_specific_helmholtz_free_energy
    execute_on = INITIAL
  []
  [entropy_density_aux]
    type = ADMaterialRealAux
    variable = entropy_density
    property = oil_entropy_density
    execute_on = INITIAL
  []
  [hessian_00_aux]
    type = ADMaterialRealAux
    variable = hessian_00
    property = 'd^2oil_helmholtz_density/drho0^2'
    execute_on = INITIAL
  []
  [hessian_01_aux]
    type = ADMaterialRealAux
    variable = hessian_01
    property = 'd^2oil_helmholtz_density/drho0drho1'
    execute_on = INITIAL
  []
  [hessian_11_aux]
    type = ADMaterialRealAux
    variable = hessian_11
    property = 'd^2oil_helmholtz_density/drho1^2'
    execute_on = INITIAL
  []
  [dmu1_dT_aux]
    type = ADMaterialRealAux
    variable = dmu1_dT
    property = 'd^2oil_helmholtz_density/drho1dtemperature'
    execute_on = INITIAL
  []
[]

[Postprocessors]
  [helmholtz_l2]
    type = ElementL2Error
    variable = helmholtz
    function = helmholtz_exact
    execute_on = INITIAL
  []
  [pressure_l2]
    type = ElementL2Error
    variable = pressure
    function = pressure_exact
    execute_on = INITIAL
  []
  [mu0_l2]
    type = ElementL2Error
    variable = mu0
    function = mu0_exact
    execute_on = INITIAL
  []
  [mu1_l2]
    type = ElementL2Error
    variable = mu1
    function = mu1_exact
    execute_on = INITIAL
  []
  [intrinsic_density_l2]
    type = ElementL2Error
    variable = intrinsic_density
    function = three
    execute_on = INITIAL
  []
  [bulk_density_l2]
    type = ElementL2Error
    variable = bulk_density
    function = bulk_density_exact
    execute_on = INITIAL
  []
  [specific_helmholtz_l2]
    type = ElementL2Error
    variable = specific_helmholtz
    function = specific_helmholtz_exact
    execute_on = INITIAL
  []
  [entropy_density_l2]
    type = ElementL2Error
    variable = entropy_density
    function = entropy_density_exact
    execute_on = INITIAL
  []
  [hessian_00_l2]
    type = ElementL2Error
    variable = hessian_00
    function = nineteen
    execute_on = INITIAL
  []
  [hessian_01_l2]
    type = ElementL2Error
    variable = hessian_01
    function = four
    execute_on = INITIAL
  []
  [hessian_11_l2]
    type = ElementL2Error
    variable = hessian_11
    function = eleven_point_five
    execute_on = INITIAL
  []
  [dmu1_dT_l2]
    type = ElementL2Error
    variable = dmu1_dT
    function = dmu1_dT_exact
    execute_on = INITIAL
  []
[]

[Problem]
  solve = false
[]

[Executioner]
  type = Steady
[]

[Outputs]
  console = true
  csv = true
[]
