[Functions]
  [ux_exact]
    type = ParsedFunction
    expression = '0.04*x*(1-x)'
  []
  [uy_exact]
    type = ParsedFunction
    expression = '0.03*y*(1-y)'
  []
  [p_exact]
    type = ParsedFunction
    expression = 'sin(pi*x)*sin(pi*y)'
  []
  [pressure_source]
    type = ParsedFunction
    expression = '2*pi*pi*sin(pi*x)*sin(pi*y)'
  []
  [tau_initial]
    type = ParsedFunction
    expression = 'x+2*y'
  []
  [tau_exact]
    type = ParsedFunction
    expression = 'x+2*y+3*t'
  []
  [tau_evolution_forcing]
    type = ParsedFunction
    expression = '3'
  []
  [body_x]
    type = ParsedFunction
    expression = '-(4*(-0.08+(-0.08)/(1+0.04*(1-2*x))^2)+6*(-0.08)*(1-log((1+0.04*(1-2*x))*(1+0.03*(1-2*y))))/(1+0.04*(1-2*x))^2-0.4*pi*cos(pi*x)*sin(pi*y)*(1+0.03*(1-2*y)))'
  []
  [body_y]
    type = ParsedFunction
    expression = '-(4*(-0.06+(-0.06)/(1+0.03*(1-2*y))^2)+6*(-0.06)*(1-log((1+0.04*(1-2*x))*(1+0.03*(1-2*y))))/(1+0.03*(1-2*y))^2-0.4*pi*sin(pi*x)*cos(pi*y)*(1+0.04*(1-2*x)))'
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
  [p_ic]
    type = FunctionIC
    variable = p
    function = p_exact
  []
  [tau_ic]
    type = FunctionIC
    variable = tau
    function = tau_initial
  []
[]

[Postprocessors]
  [ux_l2]
    type = ElementL2Error
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
  [p_total_l2]
    type = ElementL2Error
    variable = p_total
    function = p_exact
    execute_on = TIMESTEP_END
  []
  [tau_total_l2]
    type = ElementL2Error
    variable = tau_total
    function = tau_exact
    execute_on = TIMESTEP_END
  []
  [p_enrichment_average]
    type = ElementAverageValue
    variable = p_enr
    execute_on = TIMESTEP_END
  []
  [tau_enrichment_average]
    type = ElementAverageValue
    variable = tau_enr
    execute_on = TIMESTEP_END
  []
[]
