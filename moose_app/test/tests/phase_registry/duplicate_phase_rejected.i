[Mesh]
  type = GeneratedMesh
  dim = 1
  nx = 1
[]

[UserObjects]
  [phases]
    type = PhaseRegistry
    phases = 'solid oil oil'
    reference_phase = solid
  []
[]

[Problem]
  solve = false
[]

[Executioner]
  type = Steady
[]
