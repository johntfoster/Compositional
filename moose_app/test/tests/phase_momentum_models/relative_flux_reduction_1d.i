mesh_nx := 2

!include ../../../input/includes/mesh/generated_1d_q2.i
!include ../../../input/includes/fields/solid_q2_aux_1d.i
!include ../../../input/includes/fields/eg_pressure_legacy_aux.i
!include ../../../input/includes/fields/eg_capillary_pressure_aux.i

[AuxVariables]
  [intrinsic_density]
  []
  [phase_acceleration]
  []
  [saturation]
  []
  [W_x]
    family = MONOMIAL
    order = CONSTANT
  []
[]

[Functions]
  [zero]
    type = ParsedFunction
    expression = '0'
  []
  [one]
    type = ParsedFunction
    expression = '1'
  []
  [half]
    type = ParsedFunction
    expression = '0.5'
  []
  [pressure_exact]
    type = ParsedFunction
    expression = 'x'
  []
  [capillary_exact]
    type = ParsedFunction
    expression = '2*x'
  []
  [density_exact]
    type = ParsedFunction
    expression = '2'
  []
  [flux_exact]
    type = ParsedFunction
    expression = '-3'
  []
  [relative_permeability_flux_exact]
    type = ParsedFunction
    expression = '-0.75'
  []
  [material_viscosity_flux_exact]
    type = ParsedFunction
    expression = '-1.5'
  []
[]

[ICs]
  [ux_ic]
    type = FunctionIC
    variable = ux
    function = zero
  []
  [pressure_ic]
    type = FunctionIC
    variable = pressure
    function = pressure_exact
  []
  [pressure_enr_ic]
    type = FunctionIC
    variable = pressure_enr
    function = zero
  []
  [capillary_ic]
    type = FunctionIC
    variable = capillary_pressure
    function = capillary_exact
  []
  [capillary_enr_ic]
    type = FunctionIC
    variable = capillary_pressure_enr
    function = zero
  []
  [density_ic]
    type = FunctionIC
    variable = intrinsic_density
    function = density_exact
  []
  [acceleration_ic]
    type = FunctionIC
    variable = phase_acceleration
    function = one
  []
  [saturation_ic]
    type = FunctionIC
    variable = saturation
    function = half
  []
[]

[UserObjects]
  [phases]
    type = PhaseRegistry
    phases = 'matrix brine'
    reference_phase = matrix
    momentum_models = 'reference relative_flux'
  []
[]

!include ../../../input/includes/materials/solid_kinematics_1d.i
!include ../../../input/includes/materials/eg_pressure_legacy_reconstruction.i
!include ../../../input/includes/materials/eg_capillary_pressure_reconstruction.i

[Materials]
  [brine_relative_permeability]
    type = ADParsedMaterial
    coupled_variables = saturation
    property_name = brine_relative_permeability
    expression = 'saturation^2'
  []
  [negative_relative_permeability]
    type = ADGenericConstantMaterial
    prop_names = negative_relative_permeability
    prop_values = '-1'
  []
  [phase_viscosity]
    type = ADGenericConstantMaterial
    prop_names = phase_viscosity
    prop_values = '4'
  []
  [brine_darcy]
    type = ADStandardDarcyReferenceFluxMaterial
    phase = brine
    phase_registry = phases
    pressure = pressure
    pressure_enrichment = pressure_enr
    intrinsic_density_source = coupled
    intrinsic_density = intrinsic_density
    permeability = 3
    viscosity = 2
  []
[]

[AuxKernels]
  [W_x_aux]
    type = ADMaterialRealVectorValueAux
    variable = W_x
    property = reference_relative_mass_flux
    component = 0
    execute_on = INITIAL
  []
[]

[Postprocessors]
  [flux_l2]
    type = ElementL2Error
    variable = W_x
    function = flux_exact
    execute_on = INITIAL
  []
[]

!include ../../../input/includes/executioner/steady_material.i
!include ../../../input/includes/outputs/csv.i
