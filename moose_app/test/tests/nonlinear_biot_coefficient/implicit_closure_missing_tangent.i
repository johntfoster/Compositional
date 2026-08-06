mesh_nx := 1

!include ../../../input/includes/mesh/generated_1d_q2.i

[Materials]
  [solid_specific_volume]
    type = ADGenericConstantMaterial
    prop_names = 'solid_intrinsic_specific_volume'
    prop_values = '2'
  []
  [solid_biot]
    type = ADSkeletonSpecificVolumeBiotMaterial
    intrinsic_specific_volume_name = solid_intrinsic_specific_volume
    reference_specific_volume = 2
    implicit_closure = true
  []
[]

!include ../../../input/includes/executioner/steady_material.i
