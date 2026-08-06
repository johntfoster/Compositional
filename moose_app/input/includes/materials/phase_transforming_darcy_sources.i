# Add one block per transforming phase. Coefficients use the same mechanism
# ordering and units as ADReactionNetworkMaterial.
[Materials]
  [phase_conversion_source]
    type = ADPhaseConversionSourceMaterial
    reaction_rates = ${phase_conversion_reaction_rates}
    phase_stoichiometric_mass_coefficients = ${phase_conversion_mass_coefficients}
    phase_current_conversion_source_name = ${phase_conversion_source_name}
  []
[]
