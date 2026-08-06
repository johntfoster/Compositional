[Mesh]
  type = GeneratedMesh
  dim = 1
  nx = 1
[]

[Problem]
  solve = false
[]

[AuxVariables]
  [eta0]
  []
  [eta1]
  []
  [phase_fraction]
  []
  [tau]
  []
  [reaction_rate]
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
  [tau_ic]
    type = ConstantIC
    variable = tau
    value = 0
  []
  [reaction_rate_ic]
    type = ConstantIC
    variable = reaction_rate
    value = 1
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
    prop_names = 'intrinsic_density phase_pressure solid_reference_J'
    prop_values = '5 7 1'
  []
  [zero_flux]
    type = ADGenericConstantVectorMaterial
    prop_names = fluid_reference_relative_mass_flux
    prop_values = '0 0 0'
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

  # Fluid Eq. (182): no solid stress-map corrections.
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
    property_prefix = fluid_projection
  []

  # Solid Eq. (183): each stress-free-map term is an independent selectable object.
  [distension_coefficient]
    type = ADGenericConstantRankTwoTensor
    tensor_name = distension_coefficient
    tensor_values = '1 0 0 0 2 0 0 0 3'
  []
  [distension_inverse]
    type = ADGenericConstantRankTwoTensor
    tensor_name = distension_inverse
    tensor_values = '1 0 0 0 1 0 0 0 1'
  []
  [distension_derivative_0]
    type = ADGenericConstantRankTwoTensor
    tensor_name = distension_derivative_0
    tensor_values = '0.1 0 0 0 0.2 0 0 0 0.3'
  []
  [distension_derivative_1]
    type = ADGenericConstantRankTwoTensor
    tensor_name = distension_derivative_1
    tensor_values = '0.2 0 0 0 0.1 0 0 0 0'
  []
  [distension_composition_correction]
    type = ADCompositionStressMapCorrectionMaterial
    coefficient_tensor_name = distension_coefficient
    stress_free_map_inverse_name = distension_inverse
    stress_free_map_derivative_names = 'distension_derivative_0 distension_derivative_1'
    correction_names = 'distension_correction_0 distension_correction_1'
  []

  [deformation_coefficient]
    type = ADGenericConstantRankTwoTensor
    tensor_name = deformation_coefficient
    tensor_values = '2 0 0 0 1 0 0 0 1'
  []
  [deformation_inverse]
    type = ADGenericConstantRankTwoTensor
    tensor_name = deformation_inverse
    tensor_values = '1 0 0 0 1 0 0 0 1'
  []
  [deformation_derivative_0]
    type = ADGenericConstantRankTwoTensor
    tensor_name = deformation_derivative_0
    tensor_values = '0.5 0 0 0 0 0 0 0 0'
  []
  [deformation_derivative_1]
    type = ADGenericConstantRankTwoTensor
    tensor_name = deformation_derivative_1
    tensor_values = '0 0 0 0 0.25 0 0 0 0.5'
  []
  [deformation_composition_correction]
    type = ADCompositionStressMapCorrectionMaterial
    coefficient_tensor_name = deformation_coefficient
    stress_free_map_inverse_name = deformation_inverse
    stress_free_map_derivative_names = 'deformation_derivative_0 deformation_derivative_1'
    correction_names = 'deformation_correction_0 deformation_correction_1'
  []

  [solid_projection]
    type = ADTheoryCompositionProjectionMaterial
    phase_registry = phases
    phase = solid
    mass_fractions = 'eta0 eta1'
    phase_fraction = phase_fraction
    intrinsic_density_name = intrinsic_density
    phase_pressure_name = phase_pressure
    specific_helmholtz_name = specific_helmholtz
    electric_enthalpy_name = electric_enthalpy
    composition_correction_names = 'distension_correction_0 distension_correction_1
                                    deformation_correction_0 deformation_correction_1'
    property_prefix = solid_projection
  []

  # End-to-end manuscript stitch; no conventional flash residual enters.
  [solid_tau_evolution]
    type = ADTauEvolutionMaterial
    tau = tau
    reference_neutral_potential_name = solid_projection_neutral_component_potential_1
    reference_specific_helmholtz_name = specific_helmholtz
    reference_pressure_work_name = solid_projection_specific_storage_work_1
    tau_evolution_residual_name = projected_tau_evolution_residual
  []
  [solid_tau_derivative]
    type = ADPhaseTauMaterialDerivative
    phase = solid
    phase_registry = phases
    phase_kind = solid_reference
    tau = tau
  []
  [fluid_tau_derivative]
    type = ADPhaseTauMaterialDerivative
    phase = fluid
    phase_registry = phases
    phase_kind = mobile
    tau = tau
    bulk_density_name = fluid_projection_bulk_phase_density
    reference_relative_mass_flux_name = fluid_reference_relative_mass_flux
  []
  [solid_component0_transfer_work_material]
    type = ADGeneralizedTransferWorkMaterial
    chemical_potential_name = solid_projection_neutral_component_potential_0
    specific_helmholtz_name = specific_helmholtz
    tau_transfer_offset_name = solid_tau_transfer_offset
    generalized_transfer_work_name = solid_component0_transfer_work
  []
  [fluid_component0_transfer_work_material]
    type = ADGeneralizedTransferWorkMaterial
    chemical_potential_name = fluid_projection_neutral_component_potential_0
    specific_helmholtz_name = specific_helmholtz
    tau_transfer_offset_name = fluid_tau_transfer_offset
    generalized_transfer_work_name = fluid_component0_transfer_work
  []
  [projected_reaction]
    type = ADReactionNetworkMaterial
    phase_registry = phases
    phases = 'solid fluid'
    components = 'component0 component1'
    reaction_rates = reaction_rate
    stoichiometric_coefficients = '-1 0 1 0'
    chemical_potential_names = 'solid_projection_neutral_component_potential_0
                                solid_projection_neutral_component_potential_1
                                fluid_projection_neutral_component_potential_0
                                fluid_projection_neutral_component_potential_1'
    phase_tau_offset_names = 'solid_tau_transfer_offset fluid_tau_transfer_offset'
    property_prefix = projected_reaction
  []
[]

[Postprocessors]
  [fluid_normalization]
    type = ADElementAverageMaterialProperty
    mat_prop = fluid_projection_normalization_residual
  []
  [fluid_pressure_storage]
    type = ADElementAverageMaterialProperty
    mat_prop = fluid_projection_phase_pressure_storage_residual
  []
  [fluid_projection_0]
    type = ADElementAverageMaterialProperty
    mat_prop = fluid_projection_projection_residual_0
  []
  [fluid_Pi]
    type = ADElementAverageMaterialProperty
    mat_prop = fluid_projection_composition_multiplier
  []
  [fluid_q0]
    type = ADElementAverageMaterialProperty
    mat_prop = fluid_projection_composition_coefficient_0
  []
  [fluid_q1]
    type = ADElementAverageMaterialProperty
    mat_prop = fluid_projection_composition_coefficient_1
  []
  [fluid_pi0]
    type = ADElementAverageMaterialProperty
    mat_prop = fluid_projection_storage_multiplier_0
  []
  [fluid_pi1]
    type = ADElementAverageMaterialProperty
    mat_prop = fluid_projection_storage_multiplier_1
  []
  [fluid_mu0]
    type = ADElementAverageMaterialProperty
    mat_prop = fluid_projection_neutral_component_potential_0
  []
  [fluid_mu1]
    type = ADElementAverageMaterialProperty
    mat_prop = fluid_projection_neutral_component_potential_1
  []
  [fluid_work0]
    type = ADElementAverageMaterialProperty
    mat_prop = fluid_projection_specific_storage_work_0
  []
  [fluid_work1]
    type = ADElementAverageMaterialProperty
    mat_prop = fluid_projection_specific_storage_work_1
  []

  [distension_correction_0]
    type = ADElementAverageMaterialProperty
    mat_prop = distension_correction_0
  []
  [distension_correction_1]
    type = ADElementAverageMaterialProperty
    mat_prop = distension_correction_1
  []
  [deformation_correction_0]
    type = ADElementAverageMaterialProperty
    mat_prop = deformation_correction_0
  []
  [deformation_correction_1]
    type = ADElementAverageMaterialProperty
    mat_prop = deformation_correction_1
  []
  [solid_normalization]
    type = ADElementAverageMaterialProperty
    mat_prop = solid_projection_normalization_residual
  []
  [solid_pressure_storage]
    type = ADElementAverageMaterialProperty
    mat_prop = solid_projection_phase_pressure_storage_residual
  []
  [solid_projection_0]
    type = ADElementAverageMaterialProperty
    mat_prop = solid_projection_projection_residual_0
  []
  [solid_Pi]
    type = ADElementAverageMaterialProperty
    mat_prop = solid_projection_composition_multiplier
  []
  [solid_q0]
    type = ADElementAverageMaterialProperty
    mat_prop = solid_projection_composition_coefficient_0
  []
  [solid_q1]
    type = ADElementAverageMaterialProperty
    mat_prop = solid_projection_composition_coefficient_1
  []
  [solid_pi0]
    type = ADElementAverageMaterialProperty
    mat_prop = solid_projection_storage_multiplier_0
  []
  [solid_pi1]
    type = ADElementAverageMaterialProperty
    mat_prop = solid_projection_storage_multiplier_1
  []
  [solid_mu0]
    type = ADElementAverageMaterialProperty
    mat_prop = solid_projection_neutral_component_potential_0
  []
  [solid_mu1]
    type = ADElementAverageMaterialProperty
    mat_prop = solid_projection_neutral_component_potential_1
  []
  [solid_work0]
    type = ADElementAverageMaterialProperty
    mat_prop = solid_projection_specific_storage_work_0
  []
  [solid_work1]
    type = ADElementAverageMaterialProperty
    mat_prop = solid_projection_specific_storage_work_1
  []
  [tau_residual]
    type = ADElementAverageMaterialProperty
    mat_prop = projected_tau_evolution_residual
  []
  [solid_transfer_work0]
    type = ADElementAverageMaterialProperty
    mat_prop = solid_component0_transfer_work
  []
  [fluid_transfer_work0]
    type = ADElementAverageMaterialProperty
    mat_prop = fluid_component0_transfer_work
  []
  [reaction_affinity]
    type = ADElementAverageMaterialProperty
    mat_prop = projected_reaction_affinity_0
  []
  [reaction_generalized]
    type = ADElementAverageMaterialProperty
    mat_prop = projected_reaction_generalized_conversion_coefficient_0
  []
  [solid_source0]
    type = ADElementAverageMaterialProperty
    mat_prop = projected_reaction_solid_current_component_source_0
  []
  [fluid_source0]
    type = ADElementAverageMaterialProperty
    mat_prop = projected_reaction_fluid_current_component_source_0
  []
  [reaction_power]
    type = ADElementAverageMaterialProperty
    mat_prop = projected_reaction_reaction_power_0
  []
[]

[Executioner]
  type = Transient
  dt = 1
  end_time = 1
[]

[Outputs]
  csv = true
[]
