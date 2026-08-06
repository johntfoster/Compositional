[Materials]
  [tau_evolution]
    type = ADTauEvolutionMaterial
    tau = tau
    tau_enrichment = tau_enr
    reference_phase_velocity = ${tau_reference_phase_velocity}
    forcing = tau_evolution_forcing
  []
[]
