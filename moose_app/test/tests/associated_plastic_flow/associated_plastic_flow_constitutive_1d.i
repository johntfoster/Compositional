[Mesh]
  type = GeneratedMesh
  dim = 1
  nx = 1
[]

[Problem]
  solve = false
[]

[Functions]
  [S00_exact]
    type = ConstantFunction
    value = 4.7
  []
  [S11_exact]
    type = ConstantFunction
    value = -0.7
  []
  [S22_exact]
    type = ConstantFunction
    value = -4
  []
  [Lp00_exact]
    type = ConstantFunction
    value = 0.94
  []
  [Lp11_exact]
    type = ConstantFunction
    value = -0.14
  []
  [Lp22_exact]
    type = ConstantFunction
    value = -0.8
  []
  [mean_exact]
    type = ConstantFunction
    value = 1
  []
  [ap_rate_exact]
    type = ConstantFunction
    value = 0.3
  []
  [Fp_dissipation_exact]
    type = ConstantFunction
    value = 9.38482
  []
  [ap_dissipation_exact]
    type = ConstantFunction
    value = 0.3
  []
  [LAp00_exact]
    type = ConstantFunction
    value = 1.89
  []
  [LAp22_exact]
    type = ConstantFunction
    value = -0.9
  []
  [Ap_dissipation_exact]
    type = ConstantFunction
    value = 15.17163
  []
  [Lp01_exact]
    type = ConstantFunction
    value = 0.2
  []
  [LAp01_exact]
    type = ConstantFunction
    value = -0.267
  []
  [zero]
    type = ConstantFunction
    value = 0
  []
[]

[Materials]
  [mobilities]
    type = ADGenericConstantMaterial
    prop_names = 'lambda_F lambda_A'
    prop_values = '0.2 0.3'
  []
  [material_stress]
    type = ADGenericConstantRankTwoTensor
    tensor_name = sigma_prime
    tensor_values = '6 1 0  1 0 0  0 0 -3'
  []
  [elastic_true_deformation]
    type = ADGenericConstantRankTwoTensor
    tensor_name = Fbar_e
    tensor_values = '1 0 0  0.2 1 0  0 0 1'
  []
  [distension]
    type = ADGenericConstantRankTwoTensor
    tensor_name = A
    tensor_values = '1 0 0  0.1 1 0  0 0 1'
  []
  [elastic_distension]
    type = ADGenericConstantRankTwoTensor
    tensor_name = A_e
    tensor_values = '1 0.3 0  0 1 0  0 0 1'
  []
  [plastic_flow]
    type = ADAssociatedPlasticFlowMaterial
    material_stress_name = sigma_prime
    elastic_true_deformation_name = Fbar_e
    distension_tensor_name = A
    elastic_distension_tensor_name = A_e
    plastic_deformation_mobility_property = lambda_F
    plastic_distension_mobility_property = lambda_A
  []
[]

[Postprocessors]
  [S00_l2]
    type = ADMaterialRankTwoComponentL2Error
    property = true_plastic_driving_stress
    row = 0
    column = 0
    function = S00_exact
  []
  [S11_l2]
    type = ADMaterialRankTwoComponentL2Error
    property = true_plastic_driving_stress
    row = 1
    column = 1
    function = S11_exact
  []
  [S22_l2]
    type = ADMaterialRankTwoComponentL2Error
    property = true_plastic_driving_stress
    row = 2
    column = 2
    function = S22_exact
  []
  [Lp00_l2]
    type = ADMaterialRankTwoComponentL2Error
    property = plastic_deformation_log_rate
    row = 0
    column = 0
    function = Lp00_exact
  []
  [Lp11_l2]
    type = ADMaterialRankTwoComponentL2Error
    property = plastic_deformation_log_rate
    row = 1
    column = 1
    function = Lp11_exact
  []
  [Lp01_l2]
    type = ADMaterialRankTwoComponentL2Error
    property = plastic_deformation_log_rate
    row = 0
    column = 1
    function = Lp01_exact
  []
  [Lp22_l2]
    type = ADMaterialRankTwoComponentL2Error
    property = plastic_deformation_log_rate
    row = 2
    column = 2
    function = Lp22_exact
  []
  [mean_l2]
    type = ADMaterialScalarL2Error
    property = plastic_mean_material_stress
    function = mean_exact
  []
  [ap_rate_l2]
    type = ADMaterialScalarL2Error
    property = scalar_plastic_distension_log_rate
    function = ap_rate_exact
  []
  [LAp00_l2]
    type = ADMaterialRankTwoComponentL2Error
    property = plastic_distension_log_rate
    row = 0
    column = 0
    function = LAp00_exact
  []
  [LAp22_l2]
    type = ADMaterialRankTwoComponentL2Error
    property = plastic_distension_log_rate
    row = 2
    column = 2
    function = LAp22_exact
  []
  [LAp01_l2]
    type = ADMaterialRankTwoComponentL2Error
    property = plastic_distension_log_rate
    row = 0
    column = 1
    function = LAp01_exact
  []
  [Fp_dissipation_l2]
    type = ADMaterialScalarL2Error
    property = plastic_deformation_dissipation
    function = Fp_dissipation_exact
  []
  [ap_dissipation_l2]
    type = ADMaterialScalarL2Error
    property = plastic_distension_dissipation
    function = ap_dissipation_exact
  []
  [Ap_dissipation_l2]
    type = ADMaterialScalarL2Error
    property = tensor_plastic_distension_dissipation
    function = Ap_dissipation_exact
  []
  [isochoric_trace_l2]
    type = ADMaterialScalarL2Error
    property = true_plastic_driving_stress_trace
    function = zero
  []
[]

[Executioner]
  type = Steady
[]

[Outputs]
  csv = true
[]
