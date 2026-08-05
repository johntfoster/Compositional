# The 10 x 10 x 3 SPE1 Cartesian cells define the physical layers,
# completions, and report locations. Each cell is subdivided into six TET4
# elements and elevated to TET10. The resulting 1800-element mesh is a
# finite-element mapping of the reference grid, not the official 300-cell
# discretization.
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
  [spe1_tet4]
    type = ElementsToTetrahedronsConverter
    input = spe1_cartesian_base
  []
  [spe1_tet10]
    type = ElementOrderConversionGenerator
    input = spe1_tet4
    conversion_type = SECOND_ORDER
  []
  [spe1_translated]
    type = TransformGenerator
    input = spe1_tet10
    transform = TRANSLATE
    vector_value = '0 0 2537.46'
  []
  [spe1_producer_completion]
    type = SubdomainBoundingBoxGenerator
    input = spe1_translated
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
    type = BoundingBoxNodeSetGenerator
    input = spe1_injector_completion
    new_boundary = spe1_injector_completion_nodes
    bottom_left = '0 0 2537.46'
    top_right = '304.8 304.8 2543.556'
  []
  [spe1_producer_completion_nodes]
    type = BoundingBoxNodeSetGenerator
    input = spe1_injector_completion_nodes
    new_boundary = spe1_producer_completion_nodes
    bottom_left = '2743.2 2743.2 2552.7'
    top_right = '3048 3048 2567.94'
  []
  # Six scalar constraints remove only the three translations and three rigid
  # rotations of the traction-boundary skeleton: xyz at A, yz at B, and z at C.
  [spe1_mechanics_pin_xyz]
    type = BoundingBoxNodeSetGenerator
    input = spe1_producer_completion_nodes
    new_boundary = spe1_mechanics_pin_xyz
    bottom_left = '0 0 2537.46'
    top_right = '0 0 2537.46'
  []
  [spe1_mechanics_pin_yz]
    type = BoundingBoxNodeSetGenerator
    input = spe1_mechanics_pin_xyz
    new_boundary = spe1_mechanics_pin_yz
    bottom_left = '3048 0 2537.46'
    top_right = '3048 0 2537.46'
  []
  [spe1_mechanics_pin_z]
    type = BoundingBoxNodeSetGenerator
    input = spe1_mechanics_pin_yz
    new_boundary = spe1_mechanics_pin_z
    bottom_left = '0 3048 2537.46'
    top_right = '0 3048 2537.46'
  []
  final_generator = spe1_mechanics_pin_z
[]
