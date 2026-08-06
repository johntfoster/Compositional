mesh_nx := 8
!include ../../../input/includes/mesh/generated_1d_q2.i

[Variables]
  [electric_potential]
    family = LAGRANGE
    order = SECOND
  []
  [electric_field]
    family = LAGRANGE
    order = FIRST
  []
[]

[AuxVariables]
  [ux]
    family = LAGRANGE
    order = SECOND
  []
  [oil_fraction]
  []
  [gas_fraction]
  []
  [charged_density]
  []
[]

[Functions]
  [zero]
    type = ParsedFunction
    expression = '0'
  []
  [potential_exact]
    type = ParsedFunction
    expression = 'x^2'
  []
  [electric_field_exact]
    type = ParsedFunction
    expression = '-2*x'
  []
  [oil_displacement_potential]
    type = ParsedFunction
    expression = '-2*x^2'
  []
  [gas_displacement_potential]
    type = ParsedFunction
    expression = '-4*x^2'
  []
  [mixture_displacement_potential]
    type = ParsedFunction
    expression = '-3.2*x^2'
  []
  [charge_exact]
    type = ParsedFunction
    expression = '-6.4'
  []
  [oil_maxwell_exact]
    type = ParsedFunction
    expression = '1.6*x^2'
  []
  [gas_maxwell_exact]
    type = ParsedFunction
    expression = '4.8*x^2'
  []
[]

[ICs]
  [potential_ic]
    type = FunctionIC
    variable = electric_potential
    function = potential_exact
  []
  [field_ic]
    type = FunctionIC
    variable = electric_field
    function = zero
  []
  [oil_fraction_ic]
    type = ConstantIC
    variable = oil_fraction
    value = 0.4
  []
  [gas_fraction_ic]
    type = ConstantIC
    variable = gas_fraction
    value = 0.6
  []
  [charged_density_ic]
    type = ConstantIC
    variable = charged_density
    value = 6.4
  []
[]

!include ../../../input/includes/materials/solid_kinematics_1d.i

[Materials]
  [oil_electric_enthalpy]
    type = ADDerivativeParsedMaterial
    coupled_variables = electric_field
    property_name = oil_electric_enthalpy
    expression = '-electric_field^2'
    derivative_order = 2
    enable_jit = true
  []
  [gas_electric_enthalpy]
    type = ADDerivativeParsedMaterial
    coupled_variables = electric_field
    property_name = gas_electric_enthalpy
    expression = '-2*electric_field^2'
    derivative_order = 2
    enable_jit = true
  []
  [oil_electrical_response]
    type = ADPhaseElectricEnthalpyMaterial
    phase = oil
    electric_field = electric_field
    phase_fraction = oil_fraction
    electric_enthalpy_name = oil_electric_enthalpy
    electric_enthalpy_field_derivative_names = 'doil_electric_enthalpy/delectric_field'
  []
  [gas_electrical_response]
    type = ADPhaseElectricEnthalpyMaterial
    phase = gas
    electric_field = electric_field
    phase_fraction = gas_fraction
    electric_enthalpy_name = gas_electric_enthalpy
    electric_enthalpy_field_derivative_names = 'dgas_electric_enthalpy/delectric_field'
  []
  [mixture_electrical_response]
    type = ADMixtureElectricFieldMaterial
    phase_fractions = 'oil_fraction gas_fraction'
    phase_electric_displacement_names = 'oil_electric_displacement gas_electric_displacement'
    charged_component_densities = charged_density
    specific_charges = '-1'
  []
[]

[Kernels]
  [field_constraint]
    type = ADElectricFieldPotentialConstraint
    variable = electric_field
    component = 0
    electric_potential = electric_potential
  []
  [gauss]
    type = ADElectrostaticGaussLaw
    variable = electric_potential
    reference_electric_displacement_name = reference_electric_displacement
    reference_free_charge_name = reference_free_charge
  []
[]

[BCs]
  [potential_bc]
    type = FunctionDirichletBC
    variable = electric_potential
    boundary = 'left right'
    function = potential_exact
  []
[]

[Postprocessors]
  [potential_l2]
    type = ElementL2Error
    variable = electric_potential
    function = potential_exact
  []
  [electric_field_l2]
    type = ElementL2Error
    variable = electric_field
    function = electric_field_exact
  []
  [oil_displacement_l2]
    type = ADMaterialVectorL2Error
    property = oil_electric_displacement
    gradient_function = oil_displacement_potential
  []
  [gas_displacement_l2]
    type = ADMaterialVectorL2Error
    property = gas_electric_displacement
    gradient_function = gas_displacement_potential
  []
  [mixture_displacement_l2]
    type = ADMaterialVectorL2Error
    property = mixture_electric_displacement
    gradient_function = mixture_displacement_potential
  []
  [reference_displacement_l2]
    type = ADMaterialVectorL2Error
    property = reference_electric_displacement
    gradient_function = mixture_displacement_potential
  []
  [current_charge_l2]
    type = ADMaterialScalarL2Error
    property = current_free_charge
    function = charge_exact
  []
  [reference_charge_l2]
    type = ADMaterialScalarL2Error
    property = reference_free_charge
    function = charge_exact
  []
  [oil_maxwell_cauchy_00_l2]
    type = ADMaterialRankTwoComponentL2Error
    property = oil_maxwell_cauchy_stress
    row = 0
    column = 0
    function = oil_maxwell_exact
  []
  [oil_maxwell_piola_00_l2]
    type = ADMaterialRankTwoComponentL2Error
    property = oil_maxwell_piola_stress
    row = 0
    column = 0
    function = oil_maxwell_exact
  []
  [gas_maxwell_cauchy_00_l2]
    type = ADMaterialRankTwoComponentL2Error
    property = gas_maxwell_cauchy_stress
    row = 0
    column = 0
    function = gas_maxwell_exact
  []
  [gas_maxwell_piola_00_l2]
    type = ADMaterialRankTwoComponentL2Error
    property = gas_maxwell_piola_stress
    row = 0
    column = 0
    function = gas_maxwell_exact
  []
[]

[Executioner]
  type = Steady
  solve_type = NEWTON
  automatic_scaling = false
  petsc_options_iname = '-pc_type -pc_factor_mat_solver_type'
  petsc_options_value = 'lu superlu_dist'
  nl_rel_tol = 1e-12
  nl_abs_tol = 1e-13
  nl_max_its = 15
[]

[Outputs]
  csv = true
[]

