mesh_nx := 1
mesh_ny := 1
mesh_nz := 1
all_boundaries := 'left right bottom top front back'
eg_epsilon := -1
eg_sigma := 16
theta_f_initial := 300
theta_s_initial := 330
theta_f_exact_expression := '300+x^2+0.5*y^2+0.25*z^2'
theta_s_exact_expression := '330+0.25*x^2+1.5*y^2+0.75*z^2'
fluid_flux_potential_expression := '-2*(300+x^2+0.5*y^2+0.25*z^2)'
solid_flux_potential_expression := '-3*(330+0.25*x^2+1.5*y^2+0.75*z^2)'
fluid_exchange_expression := '(4+0.01*x^2+0.005*y^2+0.0025*z^2)*(30-0.75*x^2+y^2+0.5*z^2)'
solid_exchange_expression := '-(4+0.01*x^2+0.005*y^2+0.0025*z^2)*(30-0.75*x^2+y^2+0.5*z^2)'
fluid_external_expression := '-7-(4+0.01*x^2+0.005*y^2+0.0025*z^2)*(30-0.75*x^2+y^2+0.5*z^2)'
solid_external_expression := '-15+(4+0.01*x^2+0.005*y^2+0.0025*z^2)*(30-0.75*x^2+y^2+0.5*z^2)'

!include ../../../input/includes/mesh/generated_3d_q2.i
!include two_temperature_energy_exchange_hierarchy.i
