mesh_nx := 4

!include ../../../input/includes/mesh/generated_1d_q2.i
!include ../../../input/includes/fields/solid_q2_aux_1d.i

[AuxVariables]
  [phi_s]
    family = LAGRANGE
    order = SECOND
  []
  [rhobar_s]
    family = LAGRANGE
    order = SECOND
  []
[]

[Functions]
  [zero]
    type = ParsedFunction
    expression = '0'
  []
  [ux_exact]
    type = ParsedFunction
    expression = '0.1*x*x'
  []
  [phi_exact]
    type = ParsedFunction
    expression = '0.5+0.1*x'
  []
  [rhobar_exact]
    type = ParsedFunction
    expression = '2+0.2*x'
  []
  [solid_mass_exact]
    type = ParsedFunction
    expression = '(1+0.2*x)*(0.5+0.1*x)*(2+0.2*x)'
  []
[]

[ICs]
  [ux_ic]
    type = FunctionIC
    variable = ux
    function = ux_exact
  []
  [phi_ic]
    type = FunctionIC
    variable = phi_s
    function = phi_exact
  []
  [rhobar_ic]
    type = FunctionIC
    variable = rhobar_s
    function = rhobar_exact
  []
[]

!include ../../../input/includes/materials/solid_kinematics_1d.i

[Materials]
  [solid_spatial_mass]
    type = ADBinarySolidSpatialMassMaterial
    solid_volume_fraction = phi_s
    solid_intrinsic_density = rhobar_s
  []
[]

[Postprocessors]
  [solid_mass_l2]
    type = ADMaterialScalarL2Error
    property = solid_component_reference_accumulation
    function = solid_mass_exact
    execute_on = TIMESTEP_END
  []
  [solid_mass_rate_l2]
    type = ADMaterialScalarL2Error
    property = solid_component_reference_storage_rate
    function = zero
    execute_on = TIMESTEP_END
  []
[]

[Problem]
  solve = false
[]

[Executioner]
  type = Transient
  start_time = 0
  end_time = 1
  dt = 1
[]

[Outputs]
  console = true
  csv = true
  execute_on = TIMESTEP_END
[]
