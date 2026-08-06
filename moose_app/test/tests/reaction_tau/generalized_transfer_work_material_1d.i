[Mesh]
  type = GeneratedMesh
  dim = 1
  nx = 2
[]

[Functions]
  [expected_transfer_work]
    type = ParsedFunction
    expression = '3.25'
  []
[]

[Materials]
  [thermodynamic_constants]
    type = ADGenericConstantMaterial
    prop_names = 'component_electrochemical_potential phase_specific_helmholtz phase_tau_transfer_offset'
    prop_values = '5 1.5 -0.25'
  []
  [transfer_work]
    type = ADGeneralizedTransferWorkMaterial
    chemical_potential_name = component_electrochemical_potential
    specific_helmholtz_name = phase_specific_helmholtz
    tau_transfer_offset_name = phase_tau_transfer_offset
    generalized_transfer_work_name = phase_component_generalized_transfer_work
  []
[]

[Postprocessors]
  [generalized_transfer_work_l2]
    type = ADMaterialScalarL2Error
    property = phase_component_generalized_transfer_work
    function = expected_transfer_work
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]

[Problem]
  solve = false
[]

[Executioner]
  type = Steady
[]

[Outputs]
  console = true
  csv = true
[]
