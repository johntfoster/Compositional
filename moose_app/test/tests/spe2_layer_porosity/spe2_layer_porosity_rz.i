!include ../../../input/includes/mesh/spe2_rz_q2_quad9.i

[Problem]
  solve = false
[]

[Variables]
  [ux]
    family = LAGRANGE
    order = SECOND
  []
  [uy]
    family = LAGRANGE
    order = SECOND
  []
  [matrix_reference_component_storage]
    family = MONOMIAL
    order = CONSTANT
  []
[]

!include ../../../input/includes/ics/spe2_layer_solid_storage.i

[Functions]
  [published_porosity]
    type = PiecewiseConstant
    axis = y
    direction = left
    x = '2743.2 2749.296 2753.868 2761.7928 2766.3648 2771.2416 2775.5088 2777.9472 2780.3856 2785.872 2789.5296 2795.3208 2800.8072 2806.9032 2822.1432 2852.6232'
    y = '0.087 0.097 0.111 0.16 0.13 0.17 0.17 0.08 0.14 0.13 0.12 0.105 0.12 0.116 0.157 0.157'
  []
  [zero]
    type = ParsedFunction
    expression = '0'
  []
[]

[Materials]
  [axisymmetric_kinematics]
    type = ADAxisymmetricSolidReferenceKinematics
    radial_displacement = ux
    axial_displacement = uy
  []
  [solid_mass_and_volume]
    type = ADSolidPhaseMassVolumeMaterial
    reference_component_storage = matrix_reference_component_storage
    solid_intrinsic_density = 1
  []
[]

[Postprocessors]
  [porosity_l2]
    type = ADMaterialScalarL2Error
    property = solid_current_porosity
    function = published_porosity
  []
  [phase_volume_constraint_l2]
    type = ADMaterialScalarL2Error
    property = phase_volume_constraint_residual
    function = zero
  []
[]

[Executioner]
  type = Steady
[]

[Outputs]
  csv = true
[]
