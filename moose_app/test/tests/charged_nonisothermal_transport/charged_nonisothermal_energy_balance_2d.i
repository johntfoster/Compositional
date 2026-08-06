mesh_nx := 4
mesh_ny := 4
solve_dt := 1
solve_steps := 1

!include ../../../input/includes/mesh/generated_2d_q2.i
!include ../../../input/includes/fields/solid_q2_aux_2d.i

[Variables]
  [temperature]
    family = LAGRANGE
    order = FIRST
  []
[]

[AuxVariables]
  [temperature_enr]
    family = MONOMIAL
    order = CONSTANT
  []
  [neutral_potential]
    family = LAGRANGE
    order = FIRST
  []
  [neutral_potential_enr]
    family = MONOMIAL
    order = CONSTANT
  []
  [electric_potential]
    family = LAGRANGE
    order = FIRST
  []
  [electric_potential_enr]
    family = MONOMIAL
    order = CONSTANT
  []
  [current_heat_flux_x_aux]
    family = MONOMIAL
    order = FIRST
  []
  [current_heat_flux_y_aux]
    family = MONOMIAL
    order = FIRST
  []
  [reference_heat_flux_x_aux]
    family = MONOMIAL
    order = FIRST
  []
  [reference_heat_flux_y_aux]
    family = MONOMIAL
    order = FIRST
  []
  [reference_heat_flux_divergence_aux]
    family = MONOMIAL
    order = CONSTANT
  []
  [reference_electric_work_aux]
    family = MONOMIAL
    order = CONSTANT
  []
  [reference_heat_supply_aux]
    family = MONOMIAL
    order = CONSTANT
  []
  [reference_energy_source_aux]
    family = MONOMIAL
    order = CONSTANT
  []
  [local_energy_balance_residual_aux]
    family = MONOMIAL
    order = CONSTANT
  []
[]

[Functions]
  [zero]
    type = ParsedFunction
    expression = '0'
  []
  [ux_exact]
    type = ParsedFunction
    expression = '0.1*x'
  []
  [uy_exact]
    type = ParsedFunction
    expression = '0.1*y'
  []
  [temperature_backbone_exact]
    type = ParsedFunction
    expression = '1+x+2*y'
  []
  [temperature_enrichment_exact]
    type = ParsedFunction
    expression = '0.5'
  []
  [temperature_total_exact]
    type = ParsedFunction
    expression = '1.5+x+2*y'
  []
  [neutral_potential_backbone_exact]
    type = ParsedFunction
    expression = '0.25*x+6.5*y'
  []
  [neutral_potential_enrichment_exact]
    type = ParsedFunction
    expression = '0.1'
  []
  [neutral_potential_total_exact]
    type = ParsedFunction
    expression = '0.1+0.25*x+6.5*y'
  []
  [electric_potential_backbone_exact]
    type = ParsedFunction
    expression = 'x-y'
  []
  [electric_potential_enrichment_exact]
    type = ParsedFunction
    expression = '5'
  []
  [electric_potential_total_exact]
    type = ParsedFunction
    expression = '5+x-y'
  []
  [conductivity_exact]
    type = ParsedFunction
    expression = '1.21*(3.5+x+2*y)'
  []
  [current_heat_flux_antiderivative_exact]
    type = ParsedFunction
    expression = '-0.55*(3.5+x+2*y)^2'
  []
  [current_heat_flux_x_exact]
    type = ParsedFunction
    expression = '-1.1*(3.5+x+2*y)'
  []
  [current_heat_flux_y_exact]
    type = ParsedFunction
    expression = '-2.2*(3.5+x+2*y)'
  []
  [reference_heat_flux_antiderivative_exact]
    type = ParsedFunction
    expression = '-0.605*(3.5+x+2*y)^2'
  []
  [reference_heat_flux_x_exact]
    type = ParsedFunction
    expression = '-1.21*(3.5+x+2*y)'
  []
  [reference_heat_flux_y_exact]
    type = ParsedFunction
    expression = '-2.42*(3.5+x+2*y)'
  []
  [reference_heat_flux_divergence_exact]
    type = ParsedFunction
    expression = '-6.05'
  []
  [reference_electric_work_exact]
    type = ParsedFunction
    expression = '-2.42'
  []
  [reference_heat_supply_exact]
    type = ParsedFunction
    expression = '-3.63'
  []
  [reference_energy_source_exact]
    type = ParsedFunction
    expression = '-6.05'
  []
  [current_volumetric_heat_supply_exact]
    type = ParsedFunction
    expression = '-3'
  []
[]

[ICs]
  [temperature_ic]
    type = FunctionIC
    variable = temperature
    function = temperature_backbone_exact
  []
  [temperature_enr_ic]
    type = FunctionIC
    variable = temperature_enr
    function = temperature_enrichment_exact
  []
  [neutral_potential_ic]
    type = FunctionIC
    variable = neutral_potential
    function = neutral_potential_backbone_exact
  []
  [neutral_potential_enr_ic]
    type = FunctionIC
    variable = neutral_potential_enr
    function = neutral_potential_enrichment_exact
  []
  [electric_potential_ic]
    type = FunctionIC
    variable = electric_potential
    function = electric_potential_backbone_exact
  []
  [electric_potential_enr_ic]
    type = FunctionIC
    variable = electric_potential_enr
    function = electric_potential_enrichment_exact
  []
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
[]

!include ../../../input/includes/materials/solid_kinematics_2d.i

[Materials]
  [temperature_reconstructed]
    type = ADEGReconstructedScalarMaterial
    field_name = temperature
    backbone = temperature
    enrichment = temperature_enr
  []
  [neutral_potential_reconstructed]
    type = ADEGReconstructedScalarMaterial
    field_name = neutral_potential
    backbone = neutral_potential
    enrichment = neutral_potential_enr
  []
  [electric_potential_reconstructed]
    type = ADEGReconstructedScalarMaterial
    field_name = electric_potential
    backbone = electric_potential
    enrichment = electric_potential_enr
  []
  [charged_flux]
    type = ADChargedNonisothermalComponentFluxMaterial
    neutral_potential_gradient_name = neutral_potential_total_gradient
    electric_potential_gradient_name = electric_potential_total_gradient
    temperature_gradient_name = temperature_total_gradient
    mobility = 0.5
    charge_number = 2
    thermal_force_coefficient = -0.25
    current_component_flux_name = energy_mms_current_component_flux
    current_charge_flux_name = energy_mms_current_charge_flux
    electric_field_work_name = energy_mms_electric_field_work
  []
  [thermal_conductivity]
    type = ADParsedMaterial
    material_property_names = 'solid_reference_J temperature_total'
    property_name = energy_mms_thermal_conductivity
    expression = 'solid_reference_J*(2+temperature_total)'
  []
  [thermal_energy]
    type = ADReferenceThermalEnergyMaterial
    reference_temperature_gradient_name = temperature_total_gradient
    thermal_conductivity_name = energy_mms_thermal_conductivity
    electric_field_work_names = 'energy_mms_electric_field_work'
    current_volumetric_heat_supply = current_volumetric_heat_supply_exact
  []
  [reference_heat_flux_divergence]
    type = ADGenericFunctionMaterial
    prop_names = reference_heat_flux_divergence
    prop_values = reference_heat_flux_divergence_exact
  []
  [local_energy_balance_residual]
    type = ADParsedMaterial
    material_property_names = 'reference_heat_flux_divergence reference_electric_work reference_heat_supply'
    property_name = local_energy_balance_residual
    expression = '-reference_heat_flux_divergence+reference_electric_work+reference_heat_supply'
  []
[]

[AuxKernels]
  [ux_prescribed]
    type = FunctionAux
    variable = ux
    function = ux_exact
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [uy_prescribed]
    type = FunctionAux
    variable = uy
    function = uy_exact
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
  [current_heat_flux_x_output]
    type = ADMaterialRealVectorValueAux
    variable = current_heat_flux_x_aux
    property = current_heat_flux
    component = 0
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [current_heat_flux_y_output]
    type = ADMaterialRealVectorValueAux
    variable = current_heat_flux_y_aux
    property = current_heat_flux
    component = 1
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [reference_heat_flux_x_output]
    type = ADMaterialRealVectorValueAux
    variable = reference_heat_flux_x_aux
    property = reference_heat_flux
    component = 0
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [reference_heat_flux_y_output]
    type = ADMaterialRealVectorValueAux
    variable = reference_heat_flux_y_aux
    property = reference_heat_flux
    component = 1
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [reference_heat_flux_divergence_output]
    type = ADMaterialRealAux
    variable = reference_heat_flux_divergence_aux
    property = reference_heat_flux_divergence
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [reference_electric_work_output]
    type = ADMaterialRealAux
    variable = reference_electric_work_aux
    property = reference_electric_work
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [reference_heat_supply_output]
    type = ADMaterialRealAux
    variable = reference_heat_supply_aux
    property = reference_heat_supply
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [reference_energy_source_output]
    type = ADMaterialRealAux
    variable = reference_energy_source_aux
    property = reference_energy_source
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [local_energy_balance_residual_output]
    type = ADMaterialRealAux
    variable = local_energy_balance_residual_aux
    property = local_energy_balance_residual
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]

[Kernels]
  [stationary_energy_balance]
    type = ADReferenceStationaryEnergyBalance
    variable = temperature
  []
[]

[BCs]
  [temperature_exact]
    type = FunctionDirichletBC
    variable = temperature
    boundary = 'left right bottom top'
    function = temperature_backbone_exact
  []
[]

[Postprocessors]
  [ux_l2]
    type = ElementL2Error
    variable = ux
    function = ux_exact
  []
  [uy_l2]
    type = ElementL2Error
    variable = uy
    function = uy_exact
  []
  [temperature_backbone_l2]
    type = ElementL2Error
    variable = temperature
    function = temperature_backbone_exact
  []
  [temperature_enrichment_l2]
    type = ElementL2Error
    variable = temperature_enr
    function = temperature_enrichment_exact
  []
  [temperature_total_l2]
    type = ADMaterialScalarL2Error
    property = temperature_total
    function = temperature_total_exact
  []
  [temperature_gradient_l2]
    type = ADMaterialVectorL2Error
    property = temperature_total_gradient
    gradient_function = temperature_total_exact
  []
  [neutral_potential_backbone_l2]
    type = ElementL2Error
    variable = neutral_potential
    function = neutral_potential_backbone_exact
  []
  [neutral_potential_enrichment_l2]
    type = ElementL2Error
    variable = neutral_potential_enr
    function = neutral_potential_enrichment_exact
  []
  [neutral_potential_total_l2]
    type = ADMaterialScalarL2Error
    property = neutral_potential_total
    function = neutral_potential_total_exact
  []
  [neutral_potential_gradient_l2]
    type = ADMaterialVectorL2Error
    property = neutral_potential_total_gradient
    gradient_function = neutral_potential_total_exact
  []
  [electric_potential_backbone_l2]
    type = ElementL2Error
    variable = electric_potential
    function = electric_potential_backbone_exact
  []
  [electric_potential_enrichment_l2]
    type = ElementL2Error
    variable = electric_potential_enr
    function = electric_potential_enrichment_exact
  []
  [electric_potential_total_l2]
    type = ADMaterialScalarL2Error
    property = electric_potential_total
    function = electric_potential_total_exact
  []
  [electric_potential_gradient_l2]
    type = ADMaterialVectorL2Error
    property = electric_potential_total_gradient
    gradient_function = electric_potential_total_exact
  []
  [thermal_conductivity_l2]
    type = ADMaterialScalarL2Error
    property = energy_mms_thermal_conductivity
    function = conductivity_exact
  []
  [current_heat_flux_l2]
    type = ADMaterialVectorL2Error
    property = current_heat_flux
    gradient_function = current_heat_flux_antiderivative_exact
  []
  [current_heat_flux_x_l2]
    type = ElementL2Error
    variable = current_heat_flux_x_aux
    function = current_heat_flux_x_exact
  []
  [current_heat_flux_y_l2]
    type = ElementL2Error
    variable = current_heat_flux_y_aux
    function = current_heat_flux_y_exact
  []
  [reference_heat_flux_l2]
    type = ADMaterialVectorL2Error
    property = reference_heat_flux
    gradient_function = reference_heat_flux_antiderivative_exact
  []
  [reference_heat_flux_x_l2]
    type = ElementL2Error
    variable = reference_heat_flux_x_aux
    function = reference_heat_flux_x_exact
  []
  [reference_heat_flux_y_l2]
    type = ElementL2Error
    variable = reference_heat_flux_y_aux
    function = reference_heat_flux_y_exact
  []
  [reference_heat_flux_divergence_l2]
    type = ADMaterialScalarL2Error
    property = reference_heat_flux_divergence
    function = reference_heat_flux_divergence_exact
  []
  [reference_electric_work_l2]
    type = ADMaterialScalarL2Error
    property = reference_electric_work
    function = reference_electric_work_exact
  []
  [reference_heat_supply_l2]
    type = ADMaterialScalarL2Error
    property = reference_heat_supply
    function = reference_heat_supply_exact
  []
  [reference_energy_source_l2]
    type = ADMaterialScalarL2Error
    property = reference_energy_source
    function = reference_energy_source_exact
  []
  [local_energy_balance_residual_l2]
    type = ADMaterialScalarL2Error
    property = local_energy_balance_residual
    function = zero
  []
  [reference_heat_flux_divergence_integral]
    type = ElementIntegralVariablePostprocessor
    variable = reference_heat_flux_divergence_aux
  []
  [reference_electric_work_integral]
    type = ElementIntegralVariablePostprocessor
    variable = reference_electric_work_aux
  []
  [reference_heat_supply_integral]
    type = ElementIntegralVariablePostprocessor
    variable = reference_heat_supply_aux
  []
  [reference_energy_source_integral]
    type = ElementIntegralVariablePostprocessor
    variable = reference_energy_source_aux
  []
  [local_energy_balance_residual_integral]
    type = ElementIntegralVariablePostprocessor
    variable = local_energy_balance_residual_aux
  []
  [left_reference_heat_flux_x]
    type = ADSideIntegralMaterialProperty
    boundary = left
    property = reference_heat_flux
    component = 0
  []
  [right_reference_heat_flux_x]
    type = ADSideIntegralMaterialProperty
    boundary = right
    property = reference_heat_flux
    component = 0
  []
  [bottom_reference_heat_flux_y]
    type = ADSideIntegralMaterialProperty
    boundary = bottom
    property = reference_heat_flux
    component = 1
  []
  [top_reference_heat_flux_y]
    type = ADSideIntegralMaterialProperty
    boundary = top
    property = reference_heat_flux
    component = 1
  []
  [net_outward_reference_heat_flux]
    type = LinearCombinationPostprocessor
    pp_names = 'right_reference_heat_flux_x left_reference_heat_flux_x top_reference_heat_flux_y bottom_reference_heat_flux_y'
    pp_coefs = '1 -1 1 -1'
  []
  [direct_global_energy_balance]
    type = LinearCombinationPostprocessor
    pp_names = 'net_outward_reference_heat_flux reference_electric_work_integral reference_heat_supply_integral'
    pp_coefs = '-1 1 1'
  []
[]

!include ../../../input/includes/executioner/transient_newton.i
!include ../../../input/includes/outputs/csv.i
!include ../../../input/includes/common/solver_defaults.i
