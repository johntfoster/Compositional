# Distributed overlapping Schwarz preconditioner for the complete Q2/CG/EG Jacobian.
[Preconditioning]
  active = scalable_asm
  [scalable_asm]
    type = SMP
    full = true
    petsc_options_iname = '-ksp_type -ksp_rtol -ksp_max_it -pc_type -pc_asm_overlap -sub_pc_type -sub_pc_factor_shift_type'
    petsc_options_value = 'fgmres 1e-8 300 asm 1 lu nonzero'
  []
[]

