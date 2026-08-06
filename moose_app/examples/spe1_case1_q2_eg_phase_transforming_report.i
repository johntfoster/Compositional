# Report-grade acceptance overlay: preserves the production CG/EG solve and
# projects reconstructed AD thermodynamic properties at every accepted state.
!include spe1_case1_q2_eg_phase_transforming.i

[AuxVariables]
  [sample_oil_pressure]
    family = MONOMIAL
    order = CONSTANT
  []
  [sample_water_saturation]
    family = MONOMIAL
    order = CONSTANT
  []
  [sample_solution_gas_oil_ratio]
    family = MONOMIAL
    order = CONSTANT
  []
  [sample_gas_saturation]
    family = MONOMIAL
    order = CONSTANT
  []
  [sample_tau]
    family = MONOMIAL
    order = CONSTANT
  []
  [sample_dissolved_mu]
    family = MONOMIAL
    order = CONSTANT
  []
  [sample_free_mu]
    family = MONOMIAL
    order = CONSTANT
  []
  [sample_affinity]
    family = MONOMIAL
    order = CONSTANT
  []
  [sample_generalized_conversion]
    family = MONOMIAL
    order = CONSTANT
  []
  [sample_kinetic_residual]
    family = MONOMIAL
    order = CONSTANT
  []
  [sample_reaction_power]
    family = MONOMIAL
    order = CONSTANT
  []
  [sample_jacobian]
    family = MONOMIAL
    order = CONSTANT
  []
  [sample_oil_resistance]
    family = MONOMIAL
    order = CONSTANT
  []
  [sample_gas_resistance]
    family = MONOMIAL
    order = CONSTANT
  []
[]

[AuxKernels]
  [project_sample_oil_pressure]
    type = ADMaterialRealAux
    variable = sample_oil_pressure
    property = spe1_oil_pressure_total
    execute_on = timestep_end
  []
  [project_sample_water_saturation]
    type = ADMaterialRealAux
    variable = sample_water_saturation
    property = spe1_water_saturation_total
    execute_on = timestep_end
  []
  [project_sample_solution_gas_oil_ratio]
    type = ParsedAux
    variable = sample_solution_gas_oil_ratio
    coupled_variables = solution_gas_oil_ratio
    expression = 'solution_gas_oil_ratio'
    execute_on = timestep_end
  []
  [project_sample_gas_saturation]
    type = ADMaterialRealAux
    variable = sample_gas_saturation
    property = spe1_gas_saturation_total
    execute_on = timestep_end
  []
  [project_sample_tau]
    type = ADMaterialRealAux
    variable = sample_tau
    property = spe1_tau_total
    execute_on = timestep_end
  []
  [project_sample_dissolved_mu]
    type = ADMaterialRealAux
    variable = sample_dissolved_mu
    property = spe1_phase_transform_dissolved_gas_electrochemical_mu
    execute_on = timestep_end
  []
  [project_sample_free_mu]
    type = ADMaterialRealAux
    variable = sample_free_mu
    property = spe1_phase_transform_free_gas_electrochemical_mu
    execute_on = timestep_end
  []
  [project_sample_affinity]
    type = ADMaterialRealAux
    variable = sample_affinity
    property = spe1_phase_transfer_affinity_0
    execute_on = timestep_end
  []
  [project_sample_generalized_conversion]
    type = ADMaterialRealAux
    variable = sample_generalized_conversion
    property = spe1_phase_transfer_generalized_conversion_coefficient_0
    execute_on = timestep_end
  []
  [project_sample_kinetic_residual]
    type = ADMaterialRealAux
    variable = sample_kinetic_residual
    property = spe1_phase_transfer_kinetic_residual_0
    execute_on = timestep_end
  []
  [project_sample_reaction_power]
    type = ADMaterialRealAux
    variable = sample_reaction_power
    property = spe1_phase_transfer_reaction_power_0
    execute_on = timestep_end
  []
  [project_sample_jacobian]
    type = ADMaterialRealAux
    variable = sample_jacobian
    property = solid_reference_J
    execute_on = timestep_end
  []
  [project_sample_oil_resistance]
    type = ADMaterialRealAux
    variable = sample_oil_resistance
    property = oil_conversion_corrected_darcy_resistance
    execute_on = timestep_end
  []
  [project_sample_gas_resistance]
    type = ADMaterialRealAux
    variable = sample_gas_resistance
    property = gas_conversion_corrected_darcy_resistance
    execute_on = timestep_end
  []
[]

[VectorPostprocessors]
  [physical_element_fields]
    type = ElementValueSampler
    variable = 'sample_oil_pressure sample_solution_gas_oil_ratio sample_water_saturation sample_gas_saturation sample_tau sample_dissolved_mu sample_free_mu sample_affinity sample_generalized_conversion sample_kinetic_residual sample_reaction_power sample_jacobian sample_oil_resistance sample_gas_resistance'
    sort_by = id
    execute_on = timestep_end
  []
  [phase_rate_element_field]
    type = ElementValueSampler
    variable = gas_phase_transformation_rate
    sort_by = id
    execute_on = timestep_end
  []
  [nodal_mechanics]
    type = NodalValueSampler
    variable = 'ux uy uz'
    sort_by = id
    execute_on = timestep_end
  []
  [nodal_temperature]
    type = NodalValueSampler
    variable = 'fluid_temperature solid_temperature'
    sort_by = id
    execute_on = timestep_end
  []
[]

[Outputs]
  exodus = true
[]
