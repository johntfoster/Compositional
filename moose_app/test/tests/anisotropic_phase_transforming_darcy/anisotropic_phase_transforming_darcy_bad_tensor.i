[Mesh]
  type = GeneratedMesh
  dim = 1
[]

[Problem]
  solve = false
[]

[Variables]
  [ux]
  []
  [tau]
  []
[]

[Functions]
  [zero]
    type = ParsedFunction
    expression = '0'
  []
[]

[Materials]
  [kinematics]
    type = ADSolidReferenceKinematics
    displacements = ux
  []
  [bad_permeability]
    type = ADGenericConstantRankTwoTensor
    tensor_name = bad_permeability
    tensor_values = '1 0 0 0 -1 0 0 0 1'
  []
  [vectors]
    type = ADGenericConstantVectorMaterial
    prop_names = pressure_gradient
    prop_values = '0 0 0'
  []
  [scalars]
    type = ADGenericConstantMaterial
    prop_names = 'intrinsic_density bulk_density conversion_source'
    prop_values = '1 1 0'
  []
  [darcy]
    type = ADPhaseTransformingPressureGradientDarcyReferenceFluxMaterial
    phase_pressure_gradient_name = pressure_gradient
    intrinsic_density_source = material
    intrinsic_density_name = intrinsic_density
    bulk_density_name = bulk_density
    conversion_source_name = conversion_source
    tau = tau
    solid_displacements = ux
    permeability_name = bad_permeability
  []
[]

[Postprocessors]
  [force_evaluation]
    type = ADMaterialVectorL2Error
    property = reference_relative_mass_flux
    gradient_function = zero
  []
[]

[Executioner]
  type = Transient
  num_steps = 1
[]
