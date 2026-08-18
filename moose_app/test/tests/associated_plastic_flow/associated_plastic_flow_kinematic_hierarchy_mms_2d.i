[Mesh]
  type = GeneratedMesh
  dim = 2
  nx = 2
  ny = 2
  elem_type = QUAD9
[]

[Variables]
  [ux]
    order = SECOND
  []
  [uy]
    order = SECOND
  []
  [c]
  []
  [A00]
  []
  [A01]
  []
  [A10]
  []
  [A11]
  []
  [Fp00]
  []
  [Fp01]
  []
  [Fp10]
  []
  [Fp11]
  []
  [Fp_isochoric_multiplier]
  []
  [Ap00]
  []
  [Ap01]
  []
  [Ap10]
  []
  [Ap11]
  []
[]

[Functions]
  [ux_exact]
    type = ParsedFunction
    expression = '57069*t*y^2/10000000+57069*t*y/2500000+4831*x/50000+3621*y/25000'
  []
  [uy_exact]
    type = ParsedFunction
    expression = '459*t*y^2/4000000+459*t*y/1000000+441*x/20000-2417*y/50000'
  []
  [c_exact]
    type = ParsedFunction
    expression = '0.2+0.05*x+0.02*y'
  []
  [A00_exact]
    type = ConstantFunction
    value = 1.1
  []
  [A01_exact]
    type = ConstantFunction
    value = 0.1
  []
  [A10_exact]
    type = ConstantFunction
    value = 0.05
  []
  [A11_exact]
    type = ConstantFunction
    value = 0.95
  []
  [Fp00_exact]
    type = ConstantFunction
    value = 1
  []
  [Fp01_exact]
    type = ParsedFunction
    expression = 't*(0.02+0.01*y)'
  []
  [Fp10_exact]
    type = ConstantFunction
    value = 0
  []
  [Fp11_exact]
    type = ConstantFunction
    value = 1
  []
  [multiplier_exact]
    type = ParsedFunction
    expression = '0.01+0.002*x-0.001*y'
  []
  [Ap00_exact]
    type = ParsedFunction
    expression = '1+0.02*t'
  []
  [Ap01_exact]
    type = ConstantFunction
    value = 0
  []
  [Ap10_exact]
    type = ConstantFunction
    value = 0
  []
  [Ap11_exact]
    type = ParsedFunction
    expression = '1+0.01*t'
  []
  [Fp00_forcing]
    type = ParsedFunction
    expression = '-(111394795*x-17892002*y+3035327680)/34694400000'
  []
  [Fp01_forcing]
    type = ParsedFunction
    expression = '-(42005995*t*x*y+84011990*t*x+16802398*t*y^2+2721988476*t*y+5376767360*t+2314478250*x-33768608700*y+78737808000)/3469440000000'
  []
  [Fp10_forcing]
    type = ParsedFunction
    expression = '(346944*t*x*y+693888*t*x-173472*t*y^2+1387776*t*y+3469440*t-13471475*x-5388590*y-862174400)/17347200000'
  []
  [Fp11_forcing]
    type = ParsedFunction
    expression = '-(2694295*t*x*y+5388590*t*x+1077718*t*y^2+174590316*t*y+344869760*t+383693650*x-471021740*y-16382998400)/346944000000'
  []
  [Ap00_forcing]
    type = ParsedFunction
    expression = '-(8215*t*x+3286*t*y+690060*t+410750*x+164300*y+26183000)/416000000'
  []
  [Ap01_forcing]
    type = ParsedFunction
    expression = '-237897*(t+100)^2*(5*x+2*y+420)/(840320000000*(t+50))'
  []
  [Ap10_forcing]
    type = ParsedFunction
    expression = '-33633*(t+50)^2*(5*x+2*y+420)/(11440000000*(t+100))'
  []
  [Ap11_forcing]
    type = ParsedFunction
    expression = '(935*t*x+374*t*y+78540*t+93500*x+37400*y+16174000)/832000000'
  []
  [Fe00_exact]
    type = ConstantFunction
    value = 1.02
  []
  [Fe01_exact]
    type = ConstantFunction
    value = 0.04
  []
  [Fe10_exact]
    type = ConstantFunction
    value = -0.03
  []
  [Fe11_exact]
    type = ConstantFunction
    value = 0.98
  []
  [plastic_dissipation_exact]
    type = ParsedFunction
    expression = '26297708646193*(5*x+2*y+320)/19259222261760000'
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

[ICs]
  [ux_ic]
    type = FunctionIC
    variable = ux
    function = ux_exact
  []
  [uy_ic]
    type = FunctionIC
    variable = uy
    function = uy_exact
  []
  [c_ic]
    type = FunctionIC
    variable = c
    function = c_exact
  []
  [A00_ic]
    type = FunctionIC
    variable = A00
    function = A00_exact
  []
  [A01_ic]
    type = FunctionIC
    variable = A01
    function = A01_exact
  []
  [A10_ic]
    type = FunctionIC
    variable = A10
    function = A10_exact
  []
  [A11_ic]
    type = FunctionIC
    variable = A11
    function = A11_exact
  []
  [Fp00_ic]
    type = FunctionIC
    variable = Fp00
    function = Fp00_exact
  []
  [Fp01_ic]
    type = FunctionIC
    variable = Fp01
    function = Fp01_exact
  []
  [Fp10_ic]
    type = FunctionIC
    variable = Fp10
    function = Fp10_exact
  []
  [Fp11_ic]
    type = FunctionIC
    variable = Fp11
    function = Fp11_exact
  []
  [multiplier_ic]
    type = FunctionIC
    variable = Fp_isochoric_multiplier
    function = multiplier_exact
  []
  [Ap00_ic]
    type = FunctionIC
    variable = Ap00
    function = Ap00_exact
  []
  [Ap01_ic]
    type = FunctionIC
    variable = Ap01
    function = Ap01_exact
  []
  [Ap10_ic]
    type = FunctionIC
    variable = Ap10
    function = Ap10_exact
  []
  [Ap11_ic]
    type = FunctionIC
    variable = Ap11
    function = Ap11_exact
  []
[]

[Materials]
  [solid_kinematics]
    type = ADSolidReferenceKinematics
    displacements = 'ux uy'
  []
  [distension_stress_free_map]
    type = ADGenericConstantRankTwoTensor
    tensor_name = A0
    tensor_values = '1.01 0 0  0 0.99 0  0 0 1'
  []
  [true_deformation_stress_free_map]
    type = ADGenericConstantRankTwoTensor
    tensor_name = Fbar0
    tensor_values = '0.98 0 0  0 1.02 0  0 0 1'
  []
  [plastic_kinematics]
    type = ADSolidPlasticKinematicsMaterial
    distension_tensor = 'A00 A01 A10 A11'
    plastic_distension_tensor = 'Ap00 Ap01 Ap10 Ap11'
    plastic_true_deformation = 'Fp00 Fp01 Fp10 Fp11'
    distension_stress_free_map_name = A0
    true_deformation_stress_free_map_name = Fbar0
    distension_name = A
    elastic_distension_name = A_e
    elastic_true_deformation_name = Fbar_e
  []
  [material_stress]
    type = ADGenericConstantRankTwoTensor
    tensor_name = sigma_prime
    tensor_values = '4 1.2 0  1.2 -0.5 0  0 0 0.8'
  []
  [lambda_F]
    type = ADParsedMaterial
    property_name = lambda_F
    coupled_variables = c
    expression = '0.03+0.01*c'
  []
  [lambda_A]
    type = ADParsedMaterial
    property_name = lambda_A
    coupled_variables = c
    expression = '0.02+0.005*c'
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
  [Fp_determinant]
    type = ADParsedMaterial
    property_name = Fp_determinant
    coupled_variables = 'Fp00 Fp01 Fp10 Fp11'
    expression = 'Fp00*Fp11-Fp01*Fp10'
  []
[]

[Kernels]
  [ux_target]
    type = ADReaction
    variable = ux
  []
  [ux_source]
    type = ADBodyForce
    variable = ux
    function = ux_exact
  []
  [uy_target]
    type = ADReaction
    variable = uy
  []
  [uy_source]
    type = ADBodyForce
    variable = uy
    function = uy_exact
  []
  [c_target]
    type = ADReaction
    variable = c
  []
  [c_source]
    type = ADBodyForce
    variable = c
    function = c_exact
  []
  [A00_target]
    type = ADReaction
    variable = A00
  []
  [A00_source]
    type = ADBodyForce
    variable = A00
    function = A00_exact
  []
  [A01_target]
    type = ADReaction
    variable = A01
  []
  [A01_source]
    type = ADBodyForce
    variable = A01
    function = A01_exact
  []
  [A10_target]
    type = ADReaction
    variable = A10
  []
  [A10_source]
    type = ADBodyForce
    variable = A10
    function = A10_exact
  []
  [A11_target]
    type = ADReaction
    variable = A11
  []
  [A11_source]
    type = ADBodyForce
    variable = A11
    function = A11_exact
  []
  [Fp00_rate]
    type = ADPlasticDeformationEvolution
    variable = Fp00
    row = 0
    column = 0
    plastic_deformation_gradient = 'Fp00 Fp01 Fp10 Fp11'
    isochoric_multiplier = Fp_isochoric_multiplier
    forcing = Fp00_forcing
  []
  [Fp01_rate]
    type = ADPlasticDeformationEvolution
    variable = Fp01
    row = 0
    column = 1
    plastic_deformation_gradient = 'Fp00 Fp01 Fp10 Fp11'
    isochoric_multiplier = Fp_isochoric_multiplier
    forcing = Fp01_forcing
  []
  [Fp10_rate]
    type = ADPlasticDeformationEvolution
    variable = Fp10
    row = 1
    column = 0
    plastic_deformation_gradient = 'Fp00 Fp01 Fp10 Fp11'
    isochoric_multiplier = Fp_isochoric_multiplier
    forcing = Fp10_forcing
  []
  [Fp11_rate]
    type = ADPlasticDeformationEvolution
    variable = Fp11
    row = 1
    column = 1
    plastic_deformation_gradient = 'Fp00 Fp01 Fp10 Fp11'
    isochoric_multiplier = Fp_isochoric_multiplier
    forcing = Fp11_forcing
  []
  [Fp_constraint]
    type = ADPlasticDeformationDeterminantConstraint
    variable = Fp_isochoric_multiplier
    plastic_deformation_gradient = 'Fp00 Fp01 Fp10 Fp11'
  []
[]

[Physics]
  [PlasticDistension]
    [solid_tensor_distension]
      mode = tensor
      tensor_variables = 'Ap00 Ap01 Ap10 Ap11'
      tensor_forcing_names = 'Ap00_forcing Ap01_forcing Ap10_forcing Ap11_forcing'
    []
  []
[]

[Postprocessors]
  [Fp01_l2]
    type = ElementL2Error
    variable = Fp01
    function = Fp01_exact
  []
  [multiplier_l2]
    type = ElementL2Error
    variable = Fp_isochoric_multiplier
    function = multiplier_exact
  []
  [Ap00_l2]
    type = ElementL2Error
    variable = Ap00
    function = Ap00_exact
  []
  [Ap01_l2]
    type = ElementL2Error
    variable = Ap01
    function = Ap01_exact
  []
  [Ap10_l2]
    type = ElementL2Error
    variable = Ap10
    function = Ap10_exact
  []
  [Ap11_l2]
    type = ElementL2Error
    variable = Ap11
    function = Ap11_exact
  []
  [Fp_determinant_l2]
    type = ADMaterialScalarL2Error
    property = Fp_determinant
    function = one
  []
  [decomposition_l2]
    type = ADMaterialScalarL2Error
    property = solid_distension_decomposition_error
    function = zero
  []
  [distension_split_l2]
    type = ADMaterialScalarL2Error
    property = solid_distension_split_error
    function = zero
  []
  [true_split_l2]
    type = ADMaterialScalarL2Error
    property = solid_true_deformation_split_error
    function = zero
  []
  [Fe00_l2]
    type = ADMaterialRankTwoComponentL2Error
    property = Fbar_e
    row = 0
    column = 0
    function = Fe00_exact
  []
  [Fe01_l2]
    type = ADMaterialRankTwoComponentL2Error
    property = Fbar_e
    row = 0
    column = 1
    function = Fe01_exact
  []
  [Fe10_l2]
    type = ADMaterialRankTwoComponentL2Error
    property = Fbar_e
    row = 1
    column = 0
    function = Fe10_exact
  []
  [Fe11_l2]
    type = ADMaterialRankTwoComponentL2Error
    property = Fbar_e
    row = 1
    column = 1
    function = Fe11_exact
  []
  [plastic_dissipation_l2]
    type = ADMaterialScalarL2Error
    property = plastic_deformation_dissipation
    function = plastic_dissipation_exact
  []
  [driving_trace_l2]
    type = ADMaterialScalarL2Error
    property = true_plastic_driving_stress_trace
    function = zero
  []
[]

[Executioner]
  type = Transient
  solve_type = NEWTON
  scheme = implicit-euler
  dt = 0.05
  end_time = 0.1
  nl_abs_tol = 1e-11
  nl_rel_tol = 1e-11
[]

[Outputs]
  csv = true
[]
