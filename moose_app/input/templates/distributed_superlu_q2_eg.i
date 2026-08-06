# Distributed direct solve fallback for robust Q2/CG/EG acceptance runs.
[Preconditioning]
  active = distributed_superlu
  [distributed_superlu]
    type = SMP
    full = true
    petsc_options_iname = '-pc_type -pc_factor_mat_solver_type -ksp_type'
    petsc_options_value = 'lu superlu_dist preonly'
  []
[]
