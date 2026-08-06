[Mesh]
  type = GeneratedMesh
  dim = 1
  nx = 2
[]

[Variables]
  [reaction_rate]
    family = MONOMIAL
    order = SECOND
  []
  [reaction_energy_transfer_rate]
    family = MONOMIAL
    order = SECOND
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
  [reaction_rate_exact]
    type = ParsedFunction
    expression = '8.25'
  []
  [reaction_energy_transfer_rate_exact]
    type = ParsedFunction
    expression = '2.5'
  []
  [fluid_temperature_exact]
    type = ParsedFunction
    expression = '2'
  []
  [solid_temperature_exact]
    type = ParsedFunction
    expression = '4'
  []
  [energy_force_exact]
    type = ParsedFunction
    expression = '0.25'
  []
  [reaction_entropy_production_exact]
    type = ParsedFunction
    expression = '16.5'
  []
  [reaction_energy_entropy_production_exact]
    type = ParsedFunction
    expression = '0.625'
  []
  [total_entropy_production_exact]
    type = ParsedFunction
    expression = '17.125'
  []
  [determinant_exact]
    type = ParsedFunction
    expression = '7'
  []
  [zero]
    type = ParsedFunction
    expression = '0'
  []
[]

[ICs]
  [reaction_rate_ic]
    type = ConstantIC
    variable = reaction_rate
    value = 7
  []
  [reaction_energy_transfer_rate_ic]
    type = ConstantIC
    variable = reaction_energy_transfer_rate
    value = 3
  []
  [fluid_temperature_ic]
    type = ConstantIC
    variable = fluid_temperature
    value = 1.8
  []
  [solid_temperature_ic]
    type = ConstantIC
    variable = solid_temperature
    value = 4.2
  []
[]

[Materials]
  [reaction_force]
    type = ADGenericConstantMaterial
    prop_names = temperature_weighted_reaction_force
    prop_values = '2'
  []
  [fluid_temperature_property]
    type = ADParsedMaterial
    coupled_variables = fluid_temperature
    property_name = fluid_temperature_value
    expression = 'fluid_temperature'
  []
  [solid_temperature_property]
    type = ADParsedMaterial
    coupled_variables = solid_temperature
    property_name = solid_temperature_value
    expression = 'solid_temperature'
  []
  [fluid_temperature_residual]
    type = ADParsedMaterial
    coupled_variables = fluid_temperature
    property_name = fluid_temperature_residual
    expression = 'fluid_temperature-2'
  []
  [solid_temperature_residual]
    type = ADParsedMaterial
    coupled_variables = solid_temperature
    property_name = solid_temperature_residual
    expression = 'solid_temperature-4'
  []
  [reaction_energy_onsager]
    type = ADReactionEnergyOnsagerMaterial
    reaction_force_name = temperature_weighted_reaction_force
    fluid_temperature_name = fluid_temperature_value
    solid_temperature_name = solid_temperature_value
    reaction_rate = reaction_rate
    reaction_energy_transfer_rate = reaction_energy_transfer_rate
    reaction_mobility = 4
    cross_mobility = 1
    energy_mobility = 2
  []
[]

[Kernels]
  [reaction_rate_equation]
    type = ADMaterialPropertyResidual
    variable = reaction_rate
    property = reaction_energy_onsager_reaction_rate_residual
  []
  [reaction_energy_transfer_equation]
    type = ADMaterialPropertyResidual
    variable = reaction_energy_transfer_rate
    property = reaction_energy_onsager_reaction_energy_transfer_rate_residual
  []
  [fluid_temperature_equation]
    type = ADMaterialPropertyResidual
    variable = fluid_temperature
    property = fluid_temperature_residual
  []
  [solid_temperature_equation]
    type = ADMaterialPropertyResidual
    variable = solid_temperature
    property = solid_temperature_residual
  []
[]

[Postprocessors]
  [reaction_rate_error]
    type = ElementL2Error
    variable = reaction_rate
    function = reaction_rate_exact
  []
  [reaction_energy_transfer_rate_error]
    type = ElementL2Error
    variable = reaction_energy_transfer_rate
    function = reaction_energy_transfer_rate_exact
  []
  [fluid_temperature_error]
    type = ElementL2Error
    variable = fluid_temperature
    function = fluid_temperature_exact
  []
  [solid_temperature_error]
    type = ElementL2Error
    variable = solid_temperature
    function = solid_temperature_exact
  []
  [energy_force_error]
    type = ADMaterialScalarL2Error
    property = reaction_energy_onsager_energy_force
    function = energy_force_exact
  []
  [predicted_reaction_rate_error]
    type = ADMaterialScalarL2Error
    property = reaction_energy_onsager_predicted_reaction_rate
    function = reaction_rate_exact
  []
  [predicted_reaction_energy_transfer_rate_error]
    type = ADMaterialScalarL2Error
    property = reaction_energy_onsager_predicted_reaction_energy_transfer_rate
    function = reaction_energy_transfer_rate_exact
  []
  [actual_reaction_energy_transfer_rate_error]
    type = ADMaterialScalarL2Error
    property = reaction_energy_onsager_reaction_energy_transfer_rate
    function = reaction_energy_transfer_rate_exact
  []
  [reaction_rate_residual_error]
    type = ADMaterialScalarL2Error
    property = reaction_energy_onsager_reaction_rate_residual
    function = zero
  []
  [reaction_energy_transfer_rate_residual_error]
    type = ADMaterialScalarL2Error
    property = reaction_energy_onsager_reaction_energy_transfer_rate_residual
    function = zero
  []
  [reaction_entropy_production_error]
    type = ADMaterialScalarL2Error
    property = reaction_energy_onsager_reaction_entropy_production
    function = reaction_entropy_production_exact
  []
  [reaction_energy_entropy_production_error]
    type = ADMaterialScalarL2Error
    property = reaction_energy_onsager_reaction_energy_entropy_production
    function = reaction_energy_entropy_production_exact
  []
  [total_entropy_production_error]
    type = ADMaterialScalarL2Error
    property = reaction_energy_onsager_total_entropy_production
    function = total_entropy_production_exact
  []
  [onsager_quadratic_dissipation_error]
    type = ADMaterialScalarL2Error
    property = reaction_energy_onsager_onsager_quadratic_dissipation
    function = total_entropy_production_exact
  []
  [onsager_determinant_error]
    type = ADMaterialScalarL2Error
    property = reaction_energy_onsager_onsager_determinant
    function = determinant_exact
  []
[]

[Executioner]
  type = Steady
  solve_type = NEWTON
  nl_abs_tol = 1e-13
  nl_rel_tol = 1e-13
[]

[Outputs]
  console = true
  csv = true
[]
