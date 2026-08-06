mesh_nx := 2
mesh_ny := 2
all_boundaries := 'left right bottom top'
eg_epsilon := -1
eg_sigma := 16
fluid_velocity_components := 'fluid_velocity_x fluid_velocity_y'
solid_velocity_components := 'solid_velocity_x solid_velocity_y'
fluid_velocity_y_expression := '2*y'
fluid_velocity_z_expression := '0'
solid_velocity_y_expression := 'y'
solid_velocity_z_expression := '0'
theta_f_exact_expression := '300+t+x^2+0.5*y^2'
theta_s_exact_expression := '330+2*t+0.25*x^2+1.5*y^2'
electric_potential_expression := 'x+2*y'
fluid_advection_flux_potential_expression := '-0.5*(300+t+x^2+0.5*y^2)'
fluid_heat_flux_potential_expression := '-2*(300+t+x^2+0.5*y^2)'
fluid_total_flux_potential_expression := '-2.5*(300+t+x^2+0.5*y^2)'
solid_advection_flux_potential_expression := '-0.4*(330+2*t+0.25*x^2+1.5*y^2)'
solid_heat_flux_potential_expression := '-3*(330+2*t+0.25*x^2+1.5*y^2)'
solid_total_flux_potential_expression := '-3.4*(330+2*t+0.25*x^2+1.5*y^2)'
fluid_stress_power_rhs := 8
solid_stress_power_rhs := 5.5
fluid_electric_work_rhs := -1.6
solid_electric_work_rhs := -1
fluid_exchange_expression := '(1+0.01*(300+t+x^2+0.5*y^2))*(30+t-0.75*x^2+y^2)'
solid_exchange_expression := '-(1+0.01*(300+t+x^2+0.5*y^2))*(30+t-0.75*x^2+y^2)'
fluid_external_expression := '-10.7-(1+0.01*(300+t+x^2+0.5*y^2))*(30+t-0.75*x^2+y^2)'
solid_external_expression := '-11+(1+0.01*(300+t+x^2+0.5*y^2))*(30+t-0.75*x^2+y^2)'
fluid_total_source_expression := '-5.5'
solid_total_source_expression := '-5.9'

!include ../../../input/includes/mesh/generated_2d_q2.i
!include two_temperature_energy_all_terms_hierarchy.i
