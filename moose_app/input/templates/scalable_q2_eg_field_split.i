# Scalable starting point for coupled Q2 mechanics and CG/EG transport.
[Preconditioning]
  active = scalable_q2_eg
  [scalable_q2_eg]
    type = FSP
    topsplit = coupled
    [coupled]
      splitting = 'mechanics transport'
      splitting_type = multiplicative
      petsc_options_iname = '-ksp_type -ksp_rtol -ksp_max_it'
      petsc_options_value = 'fgmres 1e-8 200'
    []
    [mechanics]
      vars = 'ux uy uz'
      petsc_options_iname = '-ksp_type -ksp_rtol -ksp_max_it -pc_type -pc_hypre_type'
      petsc_options_value = 'gmres 1e-3 100 hypre boomeramg'
    []
    [transport]
      vars = 'oil_pressure oil_pressure_enrichment solution_gas_oil_ratio water_saturation water_saturation_enrichment gas_saturation gas_saturation_enrichment tau tau_enrichment gas_phase_transformation_rate fluid_temperature solid_temperature matrix_reference_component_storage injector_bhp_scalar producer_bhp_scalar'
      petsc_options_iname = '-ksp_type -ksp_rtol -ksp_max_it -pc_type -pc_asm_overlap -sub_pc_type'
      petsc_options_value = 'gmres 1e-3 150 asm 1 ilu'
    []
  []
[]
