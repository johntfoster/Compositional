[Mesh]
  type = GeneratedMesh
  dim = 1
  nx = 1
[]

[Problem]
  solve = false
[]

[Variables]
  [temperature]
  []
[]

[AuxVariables]
  [rho_a]
  []
  [rho_b]
  []
  [phase_fraction]
  []
[]

[ICs]
  [rho_a_ic]
    type = ConstantIC
    variable = rho_a
    value = 2
  []
  [rho_b_ic]
    type = ConstantIC
    variable = rho_b
    value = 3
  []
  [temperature_ic]
    type = ConstantIC
    variable = temperature
    value = 4
  []
  [phase_fraction_ic]
    type = ConstantIC
    variable = phase_fraction
    value = 0.5
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
  [material_helmholtz_density]
    type = ADDerivativeParsedMaterial
    coupled_variables = 'rho_a rho_b temperature'
    property_name = material_helmholtz_density
    expression = 'rho_a^2 + 2*rho_b + 3*temperature'
    derivative_order = 2
  []
  [electric_enthalpy_density]
    type = ADDerivativeParsedMaterial
    coupled_variables = 'rho_a rho_b temperature'
    property_name = electric_enthalpy_density
    expression = 'rho_a*rho_b + 0.5*temperature^2'
    derivative_order = 2
  []
  [fluid_eos]
    type = ADHelmholtzElectricEnthalpyEOSMaterial
    phase = fluid
    phase_registry = phases
    partial_densities = 'rho_a rho_b'
    temperature = temperature
    phase_fraction = phase_fraction
    helmholtz_density_name = material_helmholtz_density
    electric_enthalpy_name = electric_enthalpy_density
  []
[]

[Kernels]
  [temperature_dummy]
    type = ADReaction
    variable = temperature
  []
[]

[Functions]
  [pressure_exact]
    type = ConstantFunction
    value = 4
  []
  [material_pressure_exact]
    type = ConstantFunction
    value = -8
  []
  [dielectric_pressure_exact]
    type = ConstantFunction
    value = 12
  []
  [intrinsic_density_exact]
    type = ConstantFunction
    value = 5
  []
  [bulk_density_exact]
    type = ConstantFunction
    value = 2.5
  []
  [specific_helmholtz_exact]
    type = ConstantFunction
    value = 4.4
  []
  [specific_internal_energy_exact]
    type = ConstantFunction
    value = 2
  []
  [entropy_density_exact]
    type = ConstantFunction
    value = -3
  []
  [mu_a_exact]
    type = ConstantFunction
    value = 7
  []
  [mu_b_exact]
    type = ConstantFunction
    value = 4
  []
  [electric_phase_fraction_rate_exact]
    type = ConstantFunction
    value = 14
  []
  [electric_temperature_rate_exact]
    type = ConstantFunction
    value = 2
  []
  [electric_rho_a_rate_exact]
    type = ConstantFunction
    value = 1.5
  []
  [electric_rho_b_rate_exact]
    type = ConstantFunction
    value = 1
  []
[]

[Postprocessors]
  [pressure_l2]
    type = ADMaterialScalarL2Error
    property = fluid_pressure
    function = pressure_exact
  []
  [material_pressure_l2]
    type = ADMaterialScalarL2Error
    property = fluid_material_pressure
    function = material_pressure_exact
  []
  [dielectric_pressure_l2]
    type = ADMaterialScalarL2Error
    property = fluid_dielectric_pressure_correction
    function = dielectric_pressure_exact
  []
  [intrinsic_density_l2]
    type = ADMaterialScalarL2Error
    property = fluid_intrinsic_density
    function = intrinsic_density_exact
  []
  [bulk_density_l2]
    type = ADMaterialScalarL2Error
    property = fluid_bulk_phase_density
    function = bulk_density_exact
  []
  [specific_helmholtz_l2]
    type = ADMaterialScalarL2Error
    property = fluid_specific_helmholtz_free_energy
    function = specific_helmholtz_exact
  []
  [specific_internal_energy_l2]
    type = ADMaterialScalarL2Error
    property = fluid_specific_internal_energy
    function = specific_internal_energy_exact
  []
  [entropy_density_l2]
    type = ADMaterialScalarL2Error
    property = fluid_entropy_density
    function = entropy_density_exact
  []
  [mu_a_l2]
    type = ADMaterialScalarL2Error
    property = fluid_neutral_chemical_potential_0
    function = mu_a_exact
  []
  [mu_b_l2]
    type = ADMaterialScalarL2Error
    property = fluid_neutral_chemical_potential_1
    function = mu_b_exact
  []
  [electric_phase_fraction_rate_l2]
    type = ADMaterialScalarL2Error
    property = fluid_electric_phase_fraction_rate_coefficient
    function = electric_phase_fraction_rate_exact
  []
  [electric_temperature_rate_l2]
    type = ADMaterialScalarL2Error
    property = fluid_electric_temperature_rate_coefficient
    function = electric_temperature_rate_exact
  []
  [electric_rho_a_rate_l2]
    type = ADMaterialScalarL2Error
    property = fluid_electric_partial_density_rate_coefficient_0
    function = electric_rho_a_rate_exact
  []
  [electric_rho_b_rate_l2]
    type = ADMaterialScalarL2Error
    property = fluid_electric_partial_density_rate_coefficient_1
    function = electric_rho_b_rate_exact
  []
[]

[Executioner]
  type = Steady
[]

[Outputs]
  csv = true
[]
