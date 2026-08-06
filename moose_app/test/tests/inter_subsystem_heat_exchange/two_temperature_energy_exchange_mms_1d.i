mesh_nx := 2
all_boundaries := 'left right'
eg_epsilon := -1
eg_sigma := 16
theta_f_initial := 300
theta_s_initial := 330
theta_f_exact_expression := '300+x^2'
theta_s_exact_expression := '330+0.5*x^2'
fluid_flux_potential_expression := '-2*(300+x^2)'
solid_flux_potential_expression := '-3*(330+0.5*x^2)'
fluid_exchange_expression := '(4+0.01*x^2)*(30-0.5*x^2)'
solid_exchange_expression := '-(4+0.01*x^2)*(30-0.5*x^2)'
fluid_external_expression := '-4-(4+0.01*x^2)*(30-0.5*x^2)'
solid_external_expression := '-3+(4+0.01*x^2)*(30-0.5*x^2)'

!include ../../../input/includes/mesh/generated_1d_q2.i
!include two_temperature_energy_exchange_hierarchy.i
