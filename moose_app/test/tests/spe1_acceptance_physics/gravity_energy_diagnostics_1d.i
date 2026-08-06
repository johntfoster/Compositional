[Mesh]
  type = GeneratedMesh
  dim = 1
  nx = 2
[]
[Variables]
  [u]
  []
  [temperature]
    initial_condition = 3
  []
[]
[Materials]
  [constants]
    type = ADGenericConstantMaterial
    prop_names = 'solid_reference_J storage heat_source'
    prop_values = '1 2 4'
  []
  [densities]
    type = ADParsedMaterial
    coupled_variables = u
    property_name = density_a
    expression = '2+u'
  []
  [density_b]
    type = ADGenericConstantMaterial
    prop_names = density_b
    prop_values = 3
  []
  [external_work]
    type = ADParsedMaterial
    coupled_variables = u
    property_name = external_work
    expression = '1+u'
  []
  [gravity]
    type = ADMixtureGravityMaterial
    bulk_density_names = 'density_a density_b'
    gravity = '4 0 0'
  []
  [energy_diagnostic]
    type = ADReferenceSubsystemEnergyDiagnosticMaterial
    temperature = temperature
    storage_coefficient_name = storage
    reference_flux_divergence_name = flux_divergence
    current_source_names = heat_source
    current_external_work_names = external_work
    property_prefix = test_energy
  []
  [heat_flux]
    type = ADScalarDiffusionReferenceFluxMaterial
    backbone = temperature
    diffusivity = 1
    reference_flux_name = test_heat_flux
    reference_flux_divergence_name = flux_divergence
  []
[]
[Kernels]
  [diffusion]
    type = ADDiffusion
    variable = u
  []
  [gravity]
    type = ADReferenceVectorMaterialSourceTerm
    variable = u
    component = 0
    source_name = mixture_gravity_force
  []
  [storage]
    type = ADReferenceEnergyStorageTerm
    variable = temperature
    coefficient_name = storage
  []
  [source]
    type = ADReferenceEnergySourceTerm
    variable = temperature
    source_name = heat_source
  []
  [external_work]
    type = ADReferenceEnergySourceTerm
    variable = temperature
    source_name = external_work
  []
[]
[BCs]
  [u_left]
    type = ADDirichletBC
    variable = u
    boundary = left
    value = 0
  []
  [u_right]
    type = ADDirichletBC
    variable = u
    boundary = right
    value = 0
  []
[]
[Postprocessors]
  [energy_local_l2]
    type = ADMaterialScalarL2Error
    property = test_energy_local_residual
    function = 0
  []
  [average_density]
    type = ADElementAverageMaterialProperty
    mat_prop = mixture_current_density
  []
  [energy_storage]
    type = ADElementIntegralMaterialProperty
    mat_prop = test_energy_storage_rate
  []
  [energy_flux_divergence]
    type = ADElementIntegralMaterialProperty
    mat_prop = test_energy_flux_divergence
  []
  [energy_source]
    type = ADElementIntegralMaterialProperty
    mat_prop = test_energy_source_power
  []
  [energy_external_work]
    type = ADElementIntegralMaterialProperty
    mat_prop = test_energy_external_work_power
  []
  [energy_conversion]
    type = ADElementIntegralMaterialProperty
    mat_prop = test_energy_conversion_power
  []
  [energy_global_balance]
    type = LinearCombinationPostprocessor
    pp_names = 'energy_storage energy_flux_divergence energy_source energy_external_work energy_conversion'
    pp_coefs = '1 1 -1 -1 1'
  []
[]
[Executioner]
  type = Transient
  solve_type = NEWTON
  dt = 0.1
  num_steps = 1
[]
[Outputs]
  csv = true
[]
