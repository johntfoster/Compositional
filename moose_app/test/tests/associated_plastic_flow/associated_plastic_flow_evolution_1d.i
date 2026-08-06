[Mesh]
  type = GeneratedMesh
  dim = 1
  nx = 4
[]

[Variables]
  [Fp00]
  []
  [ap]
  []
[]

[ICs]
  [Fp00_ic]
    type = ConstantIC
    variable = Fp00
    value = 1
  []
  [ap_ic]
    type = ConstantIC
    variable = ap
    value = 1
  []
[]

[Functions]
  [Fp00_exact]
    type = ParsedFunction
    expression = 'exp(-log(0.9)*t/0.1)'
  []
  [ap_exact]
    type = ParsedFunction
    expression = 'exp(-log(0.97)*t/0.1)'
  []
[]

[Materials]
  [material_stress]
    type = ADGenericConstantRankTwoTensor
    tensor_name = sigma_prime
    tensor_values = '6 0 0  0 0 0  0 0 -3'
  []
  [elastic_true_deformation]
    type = ADGenericConstantRankTwoTensor
    tensor_name = Fbar_e
    tensor_values = '1 0 0  0 1 0  0 0 1'
  []
  [distension]
    type = ADGenericConstantRankTwoTensor
    tensor_name = A
    tensor_values = '1 0 0  0 1 0  0 0 1'
  []
  [elastic_distension]
    type = ADGenericConstantRankTwoTensor
    tensor_name = A_e
    tensor_values = '1 0 0  0 1 0  0 0 1'
  []
  [plastic_flow]
    type = ADAssociatedPlasticFlowMaterial
    material_stress_name = sigma_prime
    elastic_true_deformation_name = Fbar_e
    distension_tensor_name = A
    elastic_distension_tensor_name = A_e
    plastic_deformation_mobility = 0.2
    plastic_distension_mobility = 0.3
  []
[]

[Kernels]
  [Fp00_evolution]
    type = ADPlasticDeformationEvolution
    variable = Fp00
    row = 0
    column = 0
    plastic_deformation_gradient = Fp00
  []
  [ap_evolution]
    type = ADScalarPlasticDistensionEvolution
    variable = ap
  []
[]

[BCs]
  [Fp00_boundary]
    type = ADFunctionDirichletBC
    variable = Fp00
    boundary = 'left right'
    function = Fp00_exact
  []
  [ap_boundary]
    type = ADFunctionDirichletBC
    variable = ap
    boundary = 'left right'
    function = ap_exact
  []
[]

[Postprocessors]
  [Fp00_l2]
    type = ElementL2Error
    variable = Fp00
    function = Fp00_exact
    execute_on = TIMESTEP_END
  []
  [ap_l2]
    type = ElementL2Error
    variable = ap
    function = ap_exact
    execute_on = TIMESTEP_END
  []
[]

[Executioner]
  type = Transient
  solve_type = NEWTON
  scheme = implicit-euler
  dt = 0.1
  end_time = 0.2
  nl_abs_tol = 1e-12
  nl_rel_tol = 1e-12
[]

[Outputs]
  csv = true
[]
