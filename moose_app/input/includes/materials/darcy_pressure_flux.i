[Materials]
  [eg_fluid_constants]
    type = ADGenericConstantMaterial
    prop_names = 'eg_fluid_intrinsic_density'
    prop_values = '${eg_fluid_density}'
  []
  [p_darcy_flux]
    type = ADStandardDarcyReferenceFluxMaterial
    jacobian_name = solid_reference_J
    inverse_deformation_gradient_name = solid_reference_F_inv
    pressure = p
    pressure_enrichment = p_enr
    intrinsic_density_source = material
    intrinsic_density_name = eg_fluid_intrinsic_density
    permeability = ${eg_permeability}
    viscosity = ${eg_viscosity}
    darcy_mobility_ref_name = p_mobility
    reference_relative_mass_flux_name = p_reference_flux
  []
[]
