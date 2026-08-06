!include ../../../input/includes/common/solver_defaults.i

mesh_nx := 3
mesh_ny := 3
mesh_nz := 3
all_boundaries = 'left right bottom top back front'
eg_epsilon := -1.0
eg_sigma := 12.0
solve_dt := 1.0
solve_steps := 1
solid_shear_modulus := 3.0
solid_lame_lambda := 5.0
solid_biot := 0.25

!include ../../../input/includes/mesh/generated_3d_q2.i
!include ../../../input/includes/fields/solid_q2_3d.i
!include ../../../input/includes/fields/eg_pressure.i

[Functions]
  # TET10/Q2 represents these non-affine displacement components exactly, and
  # tetrahedral P1 represents the spatially varying pressure exactly. Their
  # time dependence is linear, so the material rates are exact at t=solve_dt.
  [ux_exact]
    type = ParsedFunction
    expression = '(0.04+0.01*t)*x*(1-x)'
  []
  [uy_exact]
    type = ParsedFunction
    expression = '(0.03+0.015*t)*y*(1-y)'
  []
  [uz_exact]
    type = ParsedFunction
    expression = '(0.02+0.012*t)*z*(1-z)'
  []
  [p_exact]
    type = ParsedFunction
    expression = '1+0.2*x+0.15*y+0.1*z+0.1*t'
  []
  [fluid_component_mass_fraction]
    type = ParsedFunction
    expression = '1'
  []
  [solid_reference_jacobian_exact]
    type = ParsedFunction
    expression = '(1+(0.04+0.01*t)*(1-2*x))*(1+(0.03+0.015*t)*(1-2*y))*(1+(0.02+0.012*t)*(1-2*z))'
  []
  [fluid_intrinsic_density_exact]
    type = ParsedFunction
    expression = '2+0.5*(1+0.2*x+0.15*y+0.1*z+0.1*t)'
  []
  [summed_reference_component_storage_exact]
    type = ParsedFunction
    expression = '0.25*(1+(0.04+0.01*t)*(1-2*x))*(1+(0.03+0.015*t)*(1-2*y))*(1+(0.02+0.012*t)*(1-2*z))*(2+0.5*(1+0.2*x+0.15*y+0.1*z+0.1*t))'
  []
  [summed_reference_component_storage_rate_exact]
    type = ParsedFunction
    expression = '0.25*((0.01*(1-2*x)*(1+(0.03+0.015*t)*(1-2*y))*(1+(0.02+0.012*t)*(1-2*z))+(1+(0.04+0.01*t)*(1-2*x))*0.015*(1-2*y)*(1+(0.02+0.012*t)*(1-2*z))+(1+(0.04+0.01*t)*(1-2*x))*(1+(0.03+0.015*t)*(1-2*y))*0.012*(1-2*z))*(2+0.5*(1+0.2*x+0.15*y+0.1*z+0.1*t))+(1+(0.04+0.01*t)*(1-2*x))*(1+(0.03+0.015*t)*(1-2*y))*(1+(0.02+0.012*t)*(1-2*z))*0.05)'
  []
  # Div_X W for W = -rhobar_f k J F^{-1} F^{-T} Grad_X p,
  # specialized to the diagonal manufactured F and k=0.3.
  [summed_reference_component_flux_divergence_exact]
    type = ParsedFunction
    expression = '-0.3*((1+(0.03+0.015*t)*(1-2*y))*(1+(0.02+0.012*t)*(1-2*z))*(0.5*0.2^2/(1+(0.04+0.01*t)*(1-2*x))+2*(0.04+0.01*t)*(2+0.5*(1+0.2*x+0.15*y+0.1*z+0.1*t))*0.2/(1+(0.04+0.01*t)*(1-2*x))^2)+(1+(0.04+0.01*t)*(1-2*x))*(1+(0.02+0.012*t)*(1-2*z))*(0.5*0.15^2/(1+(0.03+0.015*t)*(1-2*y))+2*(0.03+0.015*t)*(2+0.5*(1+0.2*x+0.15*y+0.1*z+0.1*t))*0.15/(1+(0.03+0.015*t)*(1-2*y))^2)+(1+(0.04+0.01*t)*(1-2*x))*(1+(0.03+0.015*t)*(1-2*y))*(0.5*0.1^2/(1+(0.02+0.012*t)*(1-2*z))+2*(0.02+0.012*t)*(2+0.5*(1+0.2*x+0.15*y+0.1*z+0.1*t))*0.1/(1+(0.02+0.012*t)*(1-2*z))^2))'
  []
  [fluid_component_source]
    type = ParsedFunction
    symbol_names = 'storage_rate flux_divergence current_J'
    symbol_values = 'summed_reference_component_storage_rate_exact summed_reference_component_flux_divergence_exact solid_reference_jacobian_exact'
    expression = '(storage_rate+flux_divergence)/current_J'
  []
  # b_0 = -Div_X(P'' - B p J F^{-T}) for Div_X P + b_0 = 0.
  [body_x]
    type = ParsedFunction
    expression = '-(3*(-2*(0.04+0.01*t))*(1+1/(1+(0.04+0.01*t)*(1-2*x))^2)+5*(-2*(0.04+0.01*t))*(1-log((1+(0.04+0.01*t)*(1-2*x))*(1+(0.03+0.015*t)*(1-2*y))*(1+(0.02+0.012*t)*(1-2*z))))/(1+(0.04+0.01*t)*(1-2*x))^2-0.25*0.2*(1+(0.03+0.015*t)*(1-2*y))*(1+(0.02+0.012*t)*(1-2*z)))'
  []
  [body_y]
    type = ParsedFunction
    expression = '-(3*(-2*(0.03+0.015*t))*(1+1/(1+(0.03+0.015*t)*(1-2*y))^2)+5*(-2*(0.03+0.015*t))*(1-log((1+(0.04+0.01*t)*(1-2*x))*(1+(0.03+0.015*t)*(1-2*y))*(1+(0.02+0.012*t)*(1-2*z))))/(1+(0.03+0.015*t)*(1-2*y))^2-0.25*0.15*(1+(0.04+0.01*t)*(1-2*x))*(1+(0.02+0.012*t)*(1-2*z)))'
  []
  [body_z]
    type = ParsedFunction
    expression = '-(3*(-2*(0.02+0.012*t))*(1+1/(1+(0.02+0.012*t)*(1-2*z))^2)+5*(-2*(0.02+0.012*t))*(1-log((1+(0.04+0.01*t)*(1-2*x))*(1+(0.03+0.015*t)*(1-2*y))*(1+(0.02+0.012*t)*(1-2*z))))/(1+(0.02+0.012*t)*(1-2*z))^2-0.25*0.1*(1+(0.04+0.01*t)*(1-2*x))*(1+(0.03+0.015*t)*(1-2*y)))'
  []
  [zero]
    type = ParsedFunction
    expression = '0'
  []
[]

[ICs]
  [ux_ic]
    type = FunctionIC
    variable = ux
    function = ux_exact
  []
  [uy_ic]
    type = FunctionIC
    variable = uy
    function = uy_exact
  []
  [uz_ic]
    type = FunctionIC
    variable = uz
    function = uz_exact
  []
  [p_ic]
    type = FunctionIC
    variable = p
    function = p_exact
  []
[]

!include ../../../input/includes/materials/solid_kinematics_3d.i
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
  [summed_reference_component_flux_divergence]
    type = ADGenericFunctionMaterial
    prop_names = summed_reference_component_flux_divergence
    prop_values = summed_reference_component_flux_divergence_exact
  []
  [summed_reference_component_balance_residual]
    type = ADParsedMaterial
    material_property_names = 'summed_reference_component_storage_rate summed_reference_component_flux_divergence summed_reference_component_source'
    property_name = summed_reference_component_balance_residual
    expression = 'summed_reference_component_storage_rate+summed_reference_component_flux_divergence-summed_reference_component_source'
  []
[]

!include ../../../input/includes/operators/eg_reference_component_balance.i
!include ../../../input/includes/operators/solid_momentum_3d.i

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
  [uy_l2]
    type = ElementL2Error
    variable = uy
    function = uy_exact
    execute_on = TIMESTEP_END
  []
  [uy_h1_semi]
    type = ElementH1SemiError
    variable = uy
    function = uy_exact
    execute_on = TIMESTEP_END
  []
  [uz_l2]
    type = ElementL2Error
    variable = uz
    function = uz_exact
    execute_on = TIMESTEP_END
  []
  [uz_h1_semi]
    type = ElementH1SemiError
    variable = uz
    function = uz_exact
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
  [summed_reference_component_balance_residual_l2]
    type = ADMaterialScalarL2Error
    property = summed_reference_component_balance_residual
    function = zero
    execute_on = TIMESTEP_END
  []
[]

[Executioner]
  type = Transient
  start_time = 0
  dt = ${solve_dt}
  num_steps = ${solve_steps}
  solve_type = NEWTON
  nl_rel_tol = 1e-14
  nl_abs_tol = 1e-14
  l_tol = 1e-14
  line_search = none
  petsc_options_iname = '-ksp_type -pc_type'
  petsc_options_value = 'preonly lu'
[]
!include ../../../input/includes/outputs/csv.i
