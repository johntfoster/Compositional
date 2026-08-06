!include ../../../input/includes/common/solver_defaults.i
!include ../../../input/includes/common/eg_pressure_defaults.i

mesh_nx := 4
mesh_ny := 4
all_boundaries = 'left right bottom top'

!include ../../../input/includes/mesh/generated_2d_q2.i
!include ../../../input/includes/fields/eg_pressure.i

[Functions]
  [p_exact]
    type = ParsedFunction
    expression = 'sin(pi*x)*sin(pi*y)'
  []
  [pressure_source]
    type = ParsedFunction
    expression = '2*pi*pi*sin(pi*x)*sin(pi*y)'
  []
[]

[ICs]
  [p_ic]
    type = FunctionIC
    variable = p
    function = p_exact
  []
[]

!include ../../../input/includes/materials/eg_pressure_reconstruction.i
!include ../../../input/includes/materials/eg_pressure_diffusion_flux.i
!include ../../../input/includes/operators/eg_pressure_diffusion.i

[Postprocessors]
  [p_material_l2]
    type = ADMaterialScalarL2Error
    property = p_total
    function = p_exact
    execute_on = TIMESTEP_END
  []
  [p_gradient_l2]
    type = ADMaterialVectorL2Error
    property = p_total_gradient
    gradient_function = p_exact
    execute_on = TIMESTEP_END
  []
  [p_enrichment_average]
    type = ElementAverageValue
    variable = p_enr
    execute_on = TIMESTEP_END
  []
[]

!include ../../../input/includes/executioner/transient_newton.i
!include ../../../input/includes/outputs/csv.i
