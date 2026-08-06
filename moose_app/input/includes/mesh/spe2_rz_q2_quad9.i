# Exact SPE2 10 x 15 radial cross section, converted from feet to SI.
# RZ quadrature supplies annular volume. This is a Q2 finite-element mesh.
[Mesh]
  coord_type = RZ
  [spe2_rz_quad4_at_origin]
    type = CartesianMeshGenerator
    dim = 2
    dx = '0.5334 0.707136 1.527048 3.304032 7.129272 15.40764 33.287208 71.908416 155.350464 335.609184'
    ix = '1 1 1 1 1 1 1 1 1 1'
    dy = '6.096 4.572 7.9248 4.572 4.8768 4.2672 2.4384 2.4384 5.4864 3.6576 5.7912 5.4864 6.096 15.24 30.48'
    iy = '1 1 1 1 1 1 1 1 1 1 1 1 1 1 1'
    # Ten IDs per vertical layer, ordered from the well outward. Completion
    # cells are radial block 1 in layers 7 and 8 (IDs 107 and 108).
    subdomain_id = '
      1 1 1 1 1 1 1 1 1 1
      2 2 2 2 2 2 2 2 2 2
      3 3 3 3 3 3 3 3 3 3
      4 4 4 4 4 4 4 4 4 4
      5 5 5 5 5 5 5 5 5 5
      6 6 6 6 6 6 6 6 6 6
      107 7 7 7 7 7 7 7 7 7
      108 8 8 8 8 8 8 8 8 8
      9 9 9 9 9 9 9 9 9 9
      10 10 10 10 10 10 10 10 10 10
      11 11 11 11 11 11 11 11 11 11
      12 12 12 12 12 12 12 12 12 12
      13 13 13 13 13 13 13 13 13 13
      14 14 14 14 14 14 14 14 14 14
      15 15 15 15 15 15 15 15 15 15'
  []
  [spe2_rz_quad9_at_origin]
    type = ElementOrderConversionGenerator
    input = spe2_rz_quad4_at_origin
    conversion_type = SECOND_ORDER
  []
  [spe2_rz_quad9]
    type = TransformGenerator
    input = spe2_rz_quad9_at_origin
    transform = TRANSLATE
    # r_w = 0.25 ft; formation top = 9000 ft.
    vector_value = '0.0762 2743.2 0'
  []
  [spe2_inner_well_nodes]
    type = BoundingBoxNodeSetGenerator
    input = spe2_rz_quad9
    new_boundary = spe2_inner_well_boundary
    bottom_left = '0.07619 2743.19999 -1'
    top_right = '0.07621 2852.62321 1'
  []
  [spe2_outer_nodes]
    type = BoundingBoxNodeSetGenerator
    input = spe2_inner_well_nodes
    new_boundary = spe2_outer_boundary
    bottom_left = '624.83999 2743.19999 -1'
    top_right = '624.84001 2852.62321 1'
  []
  [spe2_top_nodes]
    type = BoundingBoxNodeSetGenerator
    input = spe2_outer_nodes
    new_boundary = spe2_top_boundary
    bottom_left = '0.07619 2743.19999 -1'
    top_right = '624.84001 2743.20001 1'
  []
  [spe2_bottom_nodes]
    type = BoundingBoxNodeSetGenerator
    input = spe2_top_nodes
    new_boundary = spe2_bottom_boundary
    bottom_left = '0.07619 2852.62319 -1'
    top_right = '624.84001 2852.62321 1'
  []
  final_generator = spe2_bottom_nodes
[]
