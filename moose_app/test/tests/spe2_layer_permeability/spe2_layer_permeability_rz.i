!include ../../../input/includes/mesh/spe2_rz_q2_quad9.i

[Problem]
  solve = false
[]

[Functions]
  [published_radial_permeability]
    type = PiecewiseConstant
    axis = y
    direction = left
    x = '2743.2 2749.296 2753.868 2761.7928 2766.3648 2771.2416 2775.5088 2777.9472 2780.3856 2785.872 2789.5296 2795.3208 2800.8072 2806.9032 2822.1432 2852.6232'
    y = '3.45423155e-14 4.687885675e-14 1.460646484e-13 1.993585066e-13 8.8823097e-14 4.1302740105e-13 7.648655575e-13 5.9215398e-14 6.730816906e-13 4.658277976e-13 1.233654125e-13 2.9607699e-13 1.3570195375e-13 1.885023503e-13 3.45423155e-13 3.45423155e-13'
  []
  [published_vertical_permeability]
    type = PiecewiseConstant
    axis = y
    direction = left
    x = '2743.2 2749.296 2753.868 2761.7928 2766.3648 2771.2416 2775.5088 2777.9472 2780.3856 2785.872 2789.5296 2795.3208 2800.8072 2806.9032 2822.1432 2852.6232'
    y = '3.45423155e-15 4.687885675e-15 1.460646484e-14 1.993585066e-14 8.8823097e-15 4.1302740105e-14 7.648655575e-14 5.9215398e-15 6.730816906e-14 4.658277976e-14 1.233654125e-14 2.9607699e-14 1.3570195375e-14 1.885023503e-14 3.45423155e-14 3.45423155e-14'
  []
[]

!include ../../../input/includes/materials/spe2_layer_permeability.i

[Postprocessors]
  [radial_permeability_l2]
    type = ADMaterialRankTwoComponentL2Error
    property = spe2_absolute_permeability
    row = 0
    column = 0
    function = published_radial_permeability
  []
  [vertical_permeability_l2]
    type = ADMaterialRankTwoComponentL2Error
    property = spe2_absolute_permeability
    row = 1
    column = 1
    function = published_vertical_permeability
  []
  [hoop_permeability_l2]
    type = ADMaterialRankTwoComponentL2Error
    property = spe2_absolute_permeability
    row = 2
    column = 2
    function = published_radial_permeability
  []
[]

[Executioner]
  type = Steady
[]

[Outputs]
  csv = true
[]
