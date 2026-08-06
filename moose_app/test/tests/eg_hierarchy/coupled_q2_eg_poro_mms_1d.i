!include ../../../input/includes/common/solver_defaults.i

mesh_nx := 8
all_boundaries = 'left right'
eg_epsilon := -1.0
eg_sigma := 12.0
solve_dt := 0.1
solve_steps := 1
solid_shear_modulus := 3.0
solid_lame_lambda := 5.0
solid_biot := 0.25

!include ../../../input/includes/mesh/generated_1d_q2.i
!include ../../../input/includes/fields/solid_q2_1d.i
!include ../../../input/includes/fields/eg_pressure.i

[AuxVariables]
  [summed_reference_component_storage_aux]
    family = MONOMIAL
    order = FIRST
  []
[]

[Functions]
  [ux_exact]
    type = ParsedFunction
    expression = '(0.04+0.01*t)*x*(1-x)'
  []
  [p_exact]
    type = ParsedFunction
    expression = '1+0.2*x+0.1*t'
  []
  [fluid_component_mass_fraction]
    type = ParsedFunction
    expression = '1'
  []
  [solid_reference_jacobian_exact]
    type = ParsedFunction
    expression = '1+(0.04+0.01*t)*(1-2*x)'
  []
  [fluid_intrinsic_density_exact]
    type = ParsedFunction
    expression = '2+0.5*(1+0.2*x+0.1*t)'
  []
  [summed_reference_component_storage_exact]
    type = ParsedFunction
    expression = '0.25*(1+(0.04+0.01*t)*(1-2*x))*(2+0.5*(1+0.2*x+0.1*t))'
  []
  [summed_reference_component_storage_rate_exact]
    type = ParsedFunction
    symbol_names = 'current_J current_density'
    symbol_values = 'solid_reference_jacobian_exact fluid_intrinsic_density_exact'
    expression = '0.25*(0.01*(1-2*x)*current_density+current_J*0.05)'
  []
  [summed_reference_component_flux_divergence_exact]
    type = ParsedFunction
    expression = '-0.3*0.2*(0.1/(1+(0.04+0.01*t)*(1-2*x))+(2+0.5*(1+0.2*x+0.1*t))*2*(0.04+0.01*t)/(1+(0.04+0.01*t)*(1-2*x))^2)'
  []
  [fluid_component_source]
    type = ParsedFunction
    symbol_names = 'storage_rate flux_divergence current_J'
    symbol_values = 'summed_reference_component_storage_rate_exact summed_reference_component_flux_divergence_exact solid_reference_jacobian_exact'
    expression = '(storage_rate+flux_divergence)/current_J'
  []
  [body_x]
    type = ParsedFunction
    expression = '-(3*(-2*(0.04+0.01*t))*(1+1/(1+(0.04+0.01*t)*(1-2*x))^2)+5*(-2*(0.04+0.01*t))*(1-log(1+(0.04+0.01*t)*(1-2*x)))/(1+(0.04+0.01*t)*(1-2*x))^2-0.25*0.2)'
  []
[]

[ICs]
  [ux_ic]
    type = FunctionIC
    variable = ux
    function = ux_exact
  []
  [p_ic]
    type = FunctionIC
    variable = p
    function = p_exact
  []
[]

!include ../../../input/includes/materials/solid_kinematics_1d.i
!include ../../../input/includes/materials/eg_pressure_reconstruction.i
!include ../../../input/includes/materials/solid_stress_eg_pressure.i

[Materials]
  [fluid_intrinsic_density]
    type = ADParsedMaterial
    material_property_names = 'p_total'
    property_name = fluid_intrinsic_density
    expression = '2+0.5*p_total'
  []
  [summed_reference_component_storage]
    type = ADParsedMaterial
    material_property_names = 'solid_reference_J fluid_intrinsic_density'
    property_name = summed_reference_component_storage
    expression = 'solid_reference_J*0.25*fluid_intrinsic_density*1.0'
  []
  [summed_reference_component_storage_rate]
    type = ADParsedMaterial
    material_property_names = 'solid_reference_J solid_reference_J_dot fluid_intrinsic_density p_total_dot'
    property_name = summed_reference_component_storage_rate
    expression = '0.25*(solid_reference_J_dot*fluid_intrinsic_density+solid_reference_J*0.5*p_total_dot)*1.0'
  []
  [p_darcy_flux]
    type = ADStandardDarcyReferenceFluxMaterial
    pressure = p
    pressure_enrichment = p_enr
    intrinsic_density_source = material
    intrinsic_density_name = fluid_intrinsic_density
    permeability = 0.3
    viscosity = 1
    darcy_mobility_ref_name = p_mobility
    reference_relative_mass_flux_name = fluid_reference_relative_mass_flux
  []
  [summed_reference_component_flux_and_source]
    type = ADReferenceFluidComponentFluxMaterial
    reference_relative_mass_flux = fluid_reference_relative_mass_flux
    component_mass_fraction = fluid_component_mass_fraction
    current_component_source = fluid_component_source
    reference_component_flux_name = summed_reference_component_flux
    reference_component_source_name = summed_reference_component_source
  []
[]

!include ../../../input/includes/operators/eg_reference_component_balance.i
!include ../../../input/includes/operators/solid_momentum_1d.i

[BCs]
  [ux_exact]
    type = FunctionDirichletBC
    variable = ux
    boundary = ${all_boundaries}
    function = ux_exact
  []
[]

[AuxKernels]
  [summed_reference_component_storage_aux]
    type = ADMaterialRealAux
    variable = summed_reference_component_storage_aux
    property = summed_reference_component_storage
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]

[Postprocessors]
  [ux_l2]
    type = ElementL2Error
    variable = ux
    function = ux_exact
    execute_on = TIMESTEP_END
  []
  [ux_h1_semi]
    type = ElementH1SemiError
    variable = ux
    function = ux_exact
    execute_on = TIMESTEP_END
  []
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
  [p_enrichment_l2]
    type = ElementL2Norm
    variable = p_enr
    execute_on = TIMESTEP_END
  []
  [summed_reference_component_storage_l2]
    type = ADMaterialScalarL2Error
    property = summed_reference_component_storage
    function = summed_reference_component_storage_exact
    execute_on = TIMESTEP_END
  []
[]

!include ../../../input/includes/executioner/transient_newton.i
!include ../../../input/includes/outputs/csv.i
