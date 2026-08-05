[Materials]
  [p_diffusion_flux]
    type = ADScalarDiffusionReferenceFluxMaterial
    backbone = p
    enrichment = p_enr
    diffusivity = ${eg_pressure_diffusivity}
    mobility_name = p_mobility
    reference_flux_name = p_reference_flux
  []
[]
