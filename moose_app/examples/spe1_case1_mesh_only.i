# Official SPE1 Case 1 10 x 10 x 3 Cartesian grid in SI length units.
[Mesh]
  [spe1_cartesian_base]
    type = CartesianMeshGenerator
    dim = 3
    dx = '3048'
    ix = '10'
    dy = '3048'
    iy = '10'
    dz = '6.096 9.144 15.24'
    iz = '1 1 1'
    subdomain_id = '1 2 3'
  []
  [spe1_cartesian]
    type = TransformGenerator
    input = spe1_cartesian_base
    transform = TRANSLATE
    vector_value = '0 0 2537.46'
  []
  [spe1_producer_completion]
    type = SubdomainBoundingBoxGenerator
    input = spe1_cartesian
    bottom_left = '2743.2 2743.2 2552.7'
    top_right = '3048 3048 2567.94'
    block_id = 13
  []
  [spe1_injector_completion]
    type = SubdomainBoundingBoxGenerator
    input = spe1_producer_completion
    bottom_left = '0 0 2537.46'
    top_right = '304.8 304.8 2543.556'
    block_id = 11
  []
  [spe1_injector_completion_nodes]
    type = ExtraNodesetGenerator
    input = spe1_injector_completion
    new_boundary = spe1_injector_completion_nodes
    nodes = '0 1 11 12 121 122 132 133'
  []
  [spe1_producer_completion_nodes]
    type = ExtraNodesetGenerator
    input = spe1_injector_completion_nodes
    new_boundary = spe1_producer_completion_nodes
    nodes = '350 351 361 362 471 472 482 483'
  []
  final_generator = spe1_producer_completion_nodes
[]

[Materials]
  [spe1_layer_1]
    type = ADGenericConstantMaterial
    block = '1 11'
    prop_names = 'spe1_porosity spe1_intrinsic_permeability spe1_rock_reference_pressure spe1_rock_compressibility'
    prop_values = '0.3 4.9346165e-13 101352.9322095696 4.3511321319065047e-10'
  []
  [spe1_layer_2]
    type = ADGenericConstantMaterial
    block = 2
    prop_names = 'spe1_porosity spe1_intrinsic_permeability spe1_rock_reference_pressure spe1_rock_compressibility'
    prop_values = '0.3 4.9346165e-14 101352.9322095696 4.3511321319065047e-10'
  []
  [spe1_layer_3]
    type = ADGenericConstantMaterial
    block = '3 13'
    prop_names = 'spe1_porosity spe1_intrinsic_permeability spe1_rock_reference_pressure spe1_rock_compressibility'
    prop_values = '0.3 1.9738466e-13 101352.9322095696 4.3511321319065047e-10'
  []
[]
