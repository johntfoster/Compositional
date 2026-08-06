# SPE2 Table 2 anisotropic absolute permeability in SI units. Coordinate 0 is
# radial, coordinate 1 is axial/depth, and the unrepresented hoop direction
# uses the published horizontal permeability. Completion blocks 107 and 108
# inherit layer 7 and 8 properties respectively.
[Materials]
  [spe2_layer_1_permeability]
    type = ADGenericConstantRankTwoTensor
    block = 1
    tensor_name = spe2_absolute_permeability
    tensor_values = '3.45423155e-14 0 0 0 3.45423155e-15 0 0 0 3.45423155e-14'
  []
  [spe2_layer_2_permeability]
    type = ADGenericConstantRankTwoTensor
    block = 2
    tensor_name = spe2_absolute_permeability
    tensor_values = '4.687885675e-14 0 0 0 4.687885675e-15 0 0 0 4.687885675e-14'
  []
  [spe2_layer_3_permeability]
    type = ADGenericConstantRankTwoTensor
    block = 3
    tensor_name = spe2_absolute_permeability
    tensor_values = '1.460646484e-13 0 0 0 1.460646484e-14 0 0 0 1.460646484e-13'
  []
  [spe2_layer_4_permeability]
    type = ADGenericConstantRankTwoTensor
    block = 4
    tensor_name = spe2_absolute_permeability
    tensor_values = '1.993585066e-13 0 0 0 1.993585066e-14 0 0 0 1.993585066e-13'
  []
  [spe2_layer_5_permeability]
    type = ADGenericConstantRankTwoTensor
    block = 5
    tensor_name = spe2_absolute_permeability
    tensor_values = '8.8823097e-14 0 0 0 8.8823097e-15 0 0 0 8.8823097e-14'
  []
  [spe2_layer_6_permeability]
    type = ADGenericConstantRankTwoTensor
    block = 6
    tensor_name = spe2_absolute_permeability
    tensor_values = '4.1302740105e-13 0 0 0 4.1302740105e-14 0 0 0 4.1302740105e-13'
  []
  [spe2_layer_7_permeability]
    type = ADGenericConstantRankTwoTensor
    block = '7 107'
    tensor_name = spe2_absolute_permeability
    tensor_values = '7.648655575e-13 0 0 0 7.648655575e-14 0 0 0 7.648655575e-13'
  []
  [spe2_layer_8_permeability]
    type = ADGenericConstantRankTwoTensor
    block = '8 108'
    tensor_name = spe2_absolute_permeability
    tensor_values = '5.9215398e-14 0 0 0 5.9215398e-15 0 0 0 5.9215398e-14'
  []
  [spe2_layer_9_permeability]
    type = ADGenericConstantRankTwoTensor
    block = 9
    tensor_name = spe2_absolute_permeability
    tensor_values = '6.730816906e-13 0 0 0 6.730816906e-14 0 0 0 6.730816906e-13'
  []
  [spe2_layer_10_permeability]
    type = ADGenericConstantRankTwoTensor
    block = 10
    tensor_name = spe2_absolute_permeability
    tensor_values = '4.658277976e-13 0 0 0 4.658277976e-14 0 0 0 4.658277976e-13'
  []
  [spe2_layer_11_permeability]
    type = ADGenericConstantRankTwoTensor
    block = 11
    tensor_name = spe2_absolute_permeability
    tensor_values = '1.233654125e-13 0 0 0 1.233654125e-14 0 0 0 1.233654125e-13'
  []
  [spe2_layer_12_permeability]
    type = ADGenericConstantRankTwoTensor
    block = 12
    tensor_name = spe2_absolute_permeability
    tensor_values = '2.9607699e-13 0 0 0 2.9607699e-14 0 0 0 2.9607699e-13'
  []
  [spe2_layer_13_permeability]
    type = ADGenericConstantRankTwoTensor
    block = 13
    tensor_name = spe2_absolute_permeability
    tensor_values = '1.3570195375e-13 0 0 0 1.3570195375e-14 0 0 0 1.3570195375e-13'
  []
  [spe2_layer_14_permeability]
    type = ADGenericConstantRankTwoTensor
    block = 14
    tensor_name = spe2_absolute_permeability
    tensor_values = '1.885023503e-13 0 0 0 1.885023503e-14 0 0 0 1.885023503e-13'
  []
  [spe2_layer_15_permeability]
    type = ADGenericConstantRankTwoTensor
    block = 15
    tensor_name = spe2_absolute_permeability
    tensor_values = '3.45423155e-13 0 0 0 3.45423155e-14 0 0 0 3.45423155e-13'
  []
[]
