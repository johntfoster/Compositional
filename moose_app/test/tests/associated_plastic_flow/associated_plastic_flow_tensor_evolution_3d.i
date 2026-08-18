[Mesh]
  type = GeneratedMesh
  dim = 3
  nx = 1
  ny = 1
  nz = 1
[]

[Variables]
  [c]
  []
  [Fp00]
  []
  [Fp01]
  []
  [Fp02]
  []
  [Fp10]
  []
  [Fp11]
  []
  [Fp12]
  []
  [Fp20]
  []
  [Fp21]
  []
  [Fp22]
  []
  [Fp_isochoric_multiplier]
  []
  [Ap00]
  []
  [Ap01]
  []
  [Ap02]
  []
  [Ap10]
  []
  [Ap11]
  []
  [Ap12]
  []
  [Ap20]
  []
  [Ap21]
  []
  [Ap22]
  []
  [ap]
  []
[]

[ICs]
  [c_ic]
    type = ConstantIC
    variable = c
    value = 0.1
  []
  [Fp00_ic]
    type = ConstantIC
    variable = Fp00
    value = 1
  []
  [Fp11_ic]
    type = ConstantIC
    variable = Fp11
    value = 1
  []
  [Fp22_ic]
    type = ConstantIC
    variable = Fp22
    value = 1
  []
  [Ap00_ic]
    type = ConstantIC
    variable = Ap00
    value = 1
  []
  [Ap11_ic]
    type = ConstantIC
    variable = Ap11
    value = 1
  []
  [Ap22_ic]
    type = ConstantIC
    variable = Ap22
    value = 1
  []
  [ap_ic]
    type = ConstantIC
    variable = ap
    value = 1
  []
[]

[Functions]
  [c_exact]
    type = ConstantFunction
    value = 0.25
  []
  [Fp00_exact]
    type = ConstantFunction
    value = 1.0519244384046138
  []
  [Fp11_exact]
    type = ConstantFunction
    value = 0.9893918393124516
  []
  [Fp22_exact]
    type = ConstantFunction
    value = 0.9608312759251154
  []
  [Ap00_exact]
    type = ConstantFunction
    value = 1.0638297872340425
  []
  [Fp_isochoric_multiplier_exact]
    type = ConstantFunction
    value = -0.007066654973947721
  []
  [Ap11_exact]
    type = ConstantFunction
    value = 1
  []
  [Ap22_exact]
    type = ConstantFunction
    value = 0.970873786407767
  []
  [ap_exact]
    type = ConstantFunction
    value = 1.0101010101010102
  []
  [one]
    type = ConstantFunction
    value = 1
  []
  [zero]
    type = ConstantFunction
    value = 0
  []
[]

[Materials]
  [lambda_F]
    type = ADParsedMaterial
    property_name = lambda_F
    coupled_variables = c
    expression = '0.075+0.1*c'
  []
  [lambda_A]
    type = ADParsedMaterial
    property_name = lambda_A
    coupled_variables = c
    expression = '0.095+0.02*c'
  []
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
    plastic_deformation_mobility_property = lambda_F
    plastic_distension_mobility_property = lambda_A
  []
  [c_residual]
    type = ADParsedMaterial
    property_name = c_residual
    coupled_variables = c
    expression = 'c-0.25'
  []
  [Fp_determinant]
    type = ADParsedMaterial
    property_name = Fp_determinant
    coupled_variables = 'Fp00 Fp01 Fp02 Fp10 Fp11 Fp12 Fp20 Fp21 Fp22'
    expression = 'Fp00*(Fp11*Fp22-Fp12*Fp21)-Fp01*(Fp10*Fp22-Fp12*Fp20)+Fp02*(Fp10*Fp21-Fp11*Fp20)'
  []
[]

[Kernels]
  [c_equation]
    type = ADMaterialPropertyResidual
    variable = c
    property = c_residual
  []
  [Fp00_rate]
    type = ADPlasticDeformationEvolution
    variable = Fp00
    row = 0
    column = 0
    plastic_deformation_gradient = 'Fp00 Fp01 Fp02 Fp10 Fp11 Fp12 Fp20 Fp21 Fp22'
    isochoric_multiplier = Fp_isochoric_multiplier
  []
  [Fp01_rate]
    type = ADPlasticDeformationEvolution
    variable = Fp01
    row = 0
    column = 1
    plastic_deformation_gradient = 'Fp00 Fp01 Fp02 Fp10 Fp11 Fp12 Fp20 Fp21 Fp22'
    isochoric_multiplier = Fp_isochoric_multiplier
  []
  [Fp02_rate]
    type = ADPlasticDeformationEvolution
    variable = Fp02
    row = 0
    column = 2
    plastic_deformation_gradient = 'Fp00 Fp01 Fp02 Fp10 Fp11 Fp12 Fp20 Fp21 Fp22'
    isochoric_multiplier = Fp_isochoric_multiplier
  []
  [Fp10_rate]
    type = ADPlasticDeformationEvolution
    variable = Fp10
    row = 1
    column = 0
    plastic_deformation_gradient = 'Fp00 Fp01 Fp02 Fp10 Fp11 Fp12 Fp20 Fp21 Fp22'
    isochoric_multiplier = Fp_isochoric_multiplier
  []
  [Fp11_rate]
    type = ADPlasticDeformationEvolution
    variable = Fp11
    row = 1
    column = 1
    plastic_deformation_gradient = 'Fp00 Fp01 Fp02 Fp10 Fp11 Fp12 Fp20 Fp21 Fp22'
    isochoric_multiplier = Fp_isochoric_multiplier
  []
  [Fp12_rate]
    type = ADPlasticDeformationEvolution
    variable = Fp12
    row = 1
    column = 2
    plastic_deformation_gradient = 'Fp00 Fp01 Fp02 Fp10 Fp11 Fp12 Fp20 Fp21 Fp22'
    isochoric_multiplier = Fp_isochoric_multiplier
  []
  [Fp20_rate]
    type = ADPlasticDeformationEvolution
    variable = Fp20
    row = 2
    column = 0
    plastic_deformation_gradient = 'Fp00 Fp01 Fp02 Fp10 Fp11 Fp12 Fp20 Fp21 Fp22'
    isochoric_multiplier = Fp_isochoric_multiplier
  []
  [Fp21_rate]
    type = ADPlasticDeformationEvolution
    variable = Fp21
    row = 2
    column = 1
    plastic_deformation_gradient = 'Fp00 Fp01 Fp02 Fp10 Fp11 Fp12 Fp20 Fp21 Fp22'
    isochoric_multiplier = Fp_isochoric_multiplier
  []
  [Fp22_rate]
    type = ADPlasticDeformationEvolution
    variable = Fp22
    row = 2
    column = 2
    plastic_deformation_gradient = 'Fp00 Fp01 Fp02 Fp10 Fp11 Fp12 Fp20 Fp21 Fp22'
    isochoric_multiplier = Fp_isochoric_multiplier
  []
  [Fp_isochoric_constraint]
    type = ADPlasticDeformationDeterminantConstraint
    variable = Fp_isochoric_multiplier
    plastic_deformation_gradient = 'Fp00 Fp01 Fp02 Fp10 Fp11 Fp12 Fp20 Fp21 Fp22'
  []
  [Ap00_rate]
    type = ADPlasticDistensionEvolution
    variable = Ap00
    row = 0
    column = 0
    plastic_distension_tensor = 'Ap00 Ap01 Ap02 Ap10 Ap11 Ap12 Ap20 Ap21 Ap22'
  []
  [Ap01_rate]
    type = ADPlasticDistensionEvolution
    variable = Ap01
    row = 0
    column = 1
    plastic_distension_tensor = 'Ap00 Ap01 Ap02 Ap10 Ap11 Ap12 Ap20 Ap21 Ap22'
  []
  [Ap02_rate]
    type = ADPlasticDistensionEvolution
    variable = Ap02
    row = 0
    column = 2
    plastic_distension_tensor = 'Ap00 Ap01 Ap02 Ap10 Ap11 Ap12 Ap20 Ap21 Ap22'
  []
  [Ap10_rate]
    type = ADPlasticDistensionEvolution
    variable = Ap10
    row = 1
    column = 0
    plastic_distension_tensor = 'Ap00 Ap01 Ap02 Ap10 Ap11 Ap12 Ap20 Ap21 Ap22'
  []
  [Ap11_rate]
    type = ADPlasticDistensionEvolution
    variable = Ap11
    row = 1
    column = 1
    plastic_distension_tensor = 'Ap00 Ap01 Ap02 Ap10 Ap11 Ap12 Ap20 Ap21 Ap22'
  []
  [Ap12_rate]
    type = ADPlasticDistensionEvolution
    variable = Ap12
    row = 1
    column = 2
    plastic_distension_tensor = 'Ap00 Ap01 Ap02 Ap10 Ap11 Ap12 Ap20 Ap21 Ap22'
  []
  [Ap20_rate]
    type = ADPlasticDistensionEvolution
    variable = Ap20
    row = 2
    column = 0
    plastic_distension_tensor = 'Ap00 Ap01 Ap02 Ap10 Ap11 Ap12 Ap20 Ap21 Ap22'
  []
  [Ap21_rate]
    type = ADPlasticDistensionEvolution
    variable = Ap21
    row = 2
    column = 1
    plastic_distension_tensor = 'Ap00 Ap01 Ap02 Ap10 Ap11 Ap12 Ap20 Ap21 Ap22'
  []
  [Ap22_rate]
    type = ADPlasticDistensionEvolution
    variable = Ap22
    row = 2
    column = 2
    plastic_distension_tensor = 'Ap00 Ap01 Ap02 Ap10 Ap11 Ap12 Ap20 Ap21 Ap22'
  []
  [ap_rate]
    type = ADScalarPlasticDistensionEvolution
    variable = ap
  []
[]

[Postprocessors]
  [c_l2]
    type = ElementL2Error
    variable = c
    function = c_exact
  []
  [Fp00_l2]
    type = ElementL2Error
    variable = Fp00
    function = Fp00_exact
  []
  [Fp11_l2]
    type = ElementL2Error
    variable = Fp11
    function = Fp11_exact
  []
  [Fp22_l2]
    type = ElementL2Error
    variable = Fp22
    function = Fp22_exact
  []
  [Fp_determinant_l2]
    type = ADMaterialScalarL2Error
    property = Fp_determinant
    function = one
  []
  [Fp_isochoric_multiplier_l2]
    type = ElementL2Error
    variable = Fp_isochoric_multiplier
    function = Fp_isochoric_multiplier_exact
  []
  [Ap00_l2]
    type = ElementL2Error
    variable = Ap00
    function = Ap00_exact
  []
  [Ap11_l2]
    type = ElementL2Error
    variable = Ap11
    function = Ap11_exact
  []
  [Ap22_l2]
    type = ElementL2Error
    variable = Ap22
    function = Ap22_exact
  []
  [ap_l2]
    type = ElementL2Error
    variable = ap
    function = ap_exact
  []
  [Fp_trace_l2]
    type = ADMaterialScalarL2Error
    property = true_plastic_driving_stress_trace
    function = zero
  []
[]

[Executioner]
  type = Transient
  solve_type = NEWTON
  scheme = implicit-euler
  dt = 0.1
  end_time = 0.1
  nl_abs_tol = 1e-12
  nl_rel_tol = 1e-12
[]

[Outputs]
  csv = true
[]
