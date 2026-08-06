# Modular SPE2 reconstruction and manuscript phase-pressure identity. The
# official neutral electrical and zero dynamic-capillary specializations are
# explicit properties, so each family remains present and reportable.
[Materials]
  [spe2_oil_pressure_reconstruction]
    type = ADEGReconstructedScalarMaterial
    field_name = spe2_oil_pressure
    backbone = oil_pressure
    enrichment = oil_pressure_enrichment
  []
  [spe2_water_saturation_reconstruction]
    type = ADEGReconstructedScalarMaterial
    field_name = spe2_water_saturation
    backbone = water_saturation
    enrichment = water_saturation_enrichment
    value_transform = identity
  []
  [spe2_gas_saturation_reconstruction]
    type = ADEGReconstructedScalarMaterial
    field_name = spe2_gas_saturation
    backbone = gas_saturation
    enrichment = gas_saturation_enrichment
    value_transform = identity
  []
  [spe2_water_oil_pressure_difference_reconstruction]
    type = ADEGReconstructedScalarMaterial
    field_name = spe2_water_oil_pressure_difference
    backbone = water_oil_pressure_difference
  []
  [spe2_gas_oil_pressure_difference_reconstruction]
    type = ADEGReconstructedScalarMaterial
    field_name = spe2_gas_oil_pressure_difference
    backbone = gas_oil_pressure_difference
  []
  [spe2_tau_reconstruction]
    type = ADEGReconstructedScalarMaterial
    field_name = spe2_tau
    backbone = tau
    enrichment = tau_enrichment
  []
  [spe2_fluid_temperature_reconstruction]
    type = ADEGReconstructedScalarMaterial
    field_name = spe2_fluid_temperature
    backbone = fluid_temperature
  []
  [spe2_solid_temperature_reconstruction]
    type = ADEGReconstructedScalarMaterial
    field_name = spe2_solid_temperature
    backbone = solid_temperature
  []

  [spe2_water_saturation_rate_gradient]
    type = ADEGScalarRateGradientMaterial
    backbone = water_saturation
    enrichment = water_saturation_enrichment
    total_rate_gradient_name = spe2_water_saturation_total_dot_gradient
  []
  [spe2_gas_saturation_rate_gradient]
    type = ADEGScalarRateGradientMaterial
    backbone = gas_saturation
    enrichment = gas_saturation_enrichment
    total_rate_gradient_name = spe2_gas_saturation_total_dot_gradient
  []
  [spe2_saturation_onsager]
    type = ADSaturationOnsagerForceMaterial
    independent_phase_names = 'water gas'
    saturation_rate_names = 'spe2_water_saturation_total_dot spe2_gas_saturation_total_dot'
    # SPE2 publishes no dynamic-capillary resistance; the full symmetric-PSD
    # input path is retained with the documented zero specialization.
    resistance_matrix = '0 0 0 0'
    porosity_name = solid_current_porosity
    fluid_temperature_name = spe2_fluid_temperature_total
    property_prefix = spe2_saturation_onsager
  []
  [spe2_saturation_onsager_gradients]
    type = ADSaturationOnsagerForceGradientMaterial
    independent_phase_names = 'water gas'
    saturation_rate_gradient_names = 'spe2_water_saturation_total_dot_gradient spe2_gas_saturation_total_dot_gradient'
    resistance_matrix = '0 0 0 0'
    property_prefix = spe2_saturation_onsager
  []

  [spe2_neutral_electrical_enthalpy_differences]
    type = ADGenericConstantMaterial
    prop_names = 'spe2_water_oil_electrical_enthalpy_difference spe2_gas_oil_electrical_enthalpy_difference'
    prop_values = '0 0'
  []
  [spe2_neutral_electrical_enthalpy_difference_gradients]
    type = ADGenericConstantVectorMaterial
    prop_names = 'spe2_water_oil_electrical_enthalpy_difference_gradient spe2_gas_oil_electrical_enthalpy_difference_gradient'
    prop_values = '0 0 0 0 0 0'
  []

  [spe2_stored_capillary_gradients]
    type = ADBlackOilStoredCapillaryGradientMaterial
    water_saturation_name = spe2_water_saturation_total
    water_saturation_gradient_name = spe2_water_saturation_total_gradient
    gas_saturation_name = spe2_gas_saturation_total
    gas_saturation_gradient_name = spe2_gas_saturation_total_gradient
    water_saturation_points = '0.22 0.30 0.40 0.50 0.60 0.80 0.90 1.00'
    water_oil_capillary_pressure_values = '48263.301052176 27579.029172672 20684.271879504 17236.89323292 13789.514586336 6894.757293168 3447.378646584 0'
    gas_saturation_points = '0 0.04 0.10 0.20 0.30 0.40 0.50 0.60 0.70 0.78'
    gas_oil_capillary_pressure_values = '0 1378.9514586336 3447.378646584 6894.757293168 10342.135939752 13789.514586336 17236.89323292 20684.271879504 24131.650526088 26889.5534433552'
    out_of_range_policy = clamp
    property_prefix = spe2_stored_capillary
  []
  [spe2_phase_pressure_differences]
    type = ADBlackOilPhasePressureDifferenceMaterial
    water_pressure_difference = water_oil_pressure_difference
    gas_pressure_difference = gas_oil_pressure_difference
    water_saturation_name = spe2_water_saturation_total
    gas_saturation_name = spe2_gas_saturation_total
    water_saturation_points = '0.22 0.30 0.40 0.50 0.60 0.80 0.90 1.00'
    water_oil_capillary_pressure_values = '48263.301052176 27579.029172672 20684.271879504 17236.89323292 13789.514586336 6894.757293168 3447.378646584 0'
    gas_saturation_points = '0 0.04 0.10 0.20 0.30 0.40 0.50 0.60 0.70 0.78'
    gas_oil_capillary_pressure_values = '0 1378.9514586336 3447.378646584 6894.757293168 10342.135939752 13789.514586336 17236.89323292 20684.271879504 24131.650526088 26889.5534433552'
    water_electrical_enthalpy_difference_name = spe2_water_oil_electrical_enthalpy_difference
    gas_electrical_enthalpy_difference_name = spe2_gas_oil_electrical_enthalpy_difference
    water_saturation_force_difference_name = spe2_saturation_onsager_water_force_difference
    gas_saturation_force_difference_name = spe2_saturation_onsager_gas_force_difference
    out_of_range_policy = clamp
    property_prefix = spe2_phase_pressure
  []

  [spe2_water_actual_pressure]
    type = ADParsedMaterial
    material_property_names = 'spe2_oil_pressure_total spe2_phase_pressure_water_reconstructed_pressure_difference'
    property_name = spe2_water_pressure
    expression = 'spe2_oil_pressure_total+spe2_phase_pressure_water_reconstructed_pressure_difference'
  []
  [spe2_gas_actual_pressure]
    type = ADParsedMaterial
    material_property_names = 'spe2_oil_pressure_total spe2_phase_pressure_gas_reconstructed_pressure_difference'
    property_name = spe2_gas_pressure
    expression = 'spe2_oil_pressure_total+spe2_phase_pressure_gas_reconstructed_pressure_difference'
  []

  [spe2_oil_actual_pressure_gradient]
    type = ADPhasePressureGradientAssemblerMaterial
    base_pressure_gradient_name = spe2_oil_pressure_total_gradient
    phase_pressure_gradient_name = spe2_oil_pressure_gradient
  []
  [spe2_water_actual_pressure_gradient]
    type = ADPhasePressureGradientAssemblerMaterial
    base_pressure_gradient_name = spe2_oil_pressure_total_gradient
    correction_gradient_names = 'spe2_stored_capillary_water_pressure_difference_gradient spe2_water_oil_electrical_enthalpy_difference_gradient spe2_saturation_onsager_water_force_difference_gradient'
    correction_scales = '1 1 1'
    phase_pressure_gradient_name = spe2_water_pressure_gradient
  []
  [spe2_gas_actual_pressure_gradient]
    type = ADPhasePressureGradientAssemblerMaterial
    base_pressure_gradient_name = spe2_oil_pressure_total_gradient
    correction_gradient_names = 'spe2_stored_capillary_gas_pressure_difference_gradient spe2_gas_oil_electrical_enthalpy_difference_gradient spe2_saturation_onsager_gas_force_difference_gradient'
    correction_scales = '1 1 1'
    phase_pressure_gradient_name = spe2_gas_pressure_gradient
  []
[]
