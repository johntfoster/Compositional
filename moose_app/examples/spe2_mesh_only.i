# SPE2 axisymmetric Q2 finite-element mesh audit.
!include ../input/includes/mesh/spe2_rz_q2_quad9.i

[Problem]
  solve = false
[]

[Mesh]
  parallel_type = replicated
[]

[Executioner]
  type = Steady
[]

[Outputs]
  exodus = true
  file_base = spe2_mesh_only
[]
