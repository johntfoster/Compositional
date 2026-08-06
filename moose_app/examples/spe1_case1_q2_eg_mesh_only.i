# Q2/EG-compatible finite-element mapping of the SPE1 Case 1 geometry.
# This solve=false deck checks the production field spaces and mesh policy; it
# is not a coupled benchmark solve or production-acceptance evidence.
!include ../input/includes/mesh/spe1_case1_3d_q2_tet10.i
!include ../input/includes/fields/spe1_black_oil_q2_eg.i

[Problem]
  solve = false
[]

[Executioner]
  type = Steady
[]
