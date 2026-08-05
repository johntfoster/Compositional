# GENERATED FILE: assemble from verified blocks; do not add protected objects here.
# problem_spec: agent_workflows/specs/verified_q2_eg_mms_2d.problem.json
# registry_sha256: f8be1f7d96016162a97cd3d33905efc691a715ff52fcabfabe5d31379d04e7e3

mesh_nx := 4
mesh_ny := 4
all_boundaries := 'left right bottom top'
eg_epsilon := -1.0
eg_sigma := 12.0
eg_tau_anchor := 1.0
eg_permeability := 1.0
eg_viscosity := 1.0
eg_fluid_density := 1.0
solid_shear_modulus := 4.0
solid_lame_lambda := 6.0
solid_biot := 0.4
solve_dt := 1.0
solve_steps := 1

# verified-block: common.solver_defaults@1.0.0
!include ../../../.codex/verified-input-blocks/common.solver_defaults/1.0.0.i
# verified-block: mesh.generated_2d_q2@1.0.0
!include ../../../.codex/verified-input-blocks/mesh.generated_2d_q2/1.0.0.i
# verified-block: fields.solid_q2_2d@1.0.0
!include ../../../.codex/verified-input-blocks/fields.solid_q2_2d/1.0.0.i
# verified-block: fields.eg_pressure_tau@1.0.0
!include ../../../.codex/verified-input-blocks/fields.eg_pressure_tau/1.0.0.i
# verified-block: materials.solid_kinematics_2d@1.0.0
!include ../../../.codex/verified-input-blocks/materials.solid_kinematics_2d/1.0.0.i
# verified-block: materials.eg_reconstruction@1.0.0
!include ../../../.codex/verified-input-blocks/materials.eg_reconstruction/1.0.0.i
# verified-block: materials.darcy_pressure_flux@1.0.0
!include ../../../.codex/verified-input-blocks/materials.darcy_pressure_flux/1.0.0.i
# verified-block: materials.solid_stress_eg_pressure@1.0.0
!include ../../../.codex/verified-input-blocks/materials.solid_stress_eg_pressure/1.0.0.i
# verified-block: materials.eg_tau_evolution@1.0.0
!include ../../../.codex/verified-input-blocks/materials.eg_tau_evolution/1.0.0.i
# verified-block: operators.eg_pressure_diffusion@1.0.0
!include ../../../.codex/verified-input-blocks/operators.eg_pressure_diffusion/1.0.0.i
# verified-block: operators.eg_tau_fluxless@1.0.0
!include ../../../.codex/verified-input-blocks/operators.eg_tau_fluxless/1.0.0.i
# verified-block: operators.solid_momentum_2d@1.0.0
!include ../../../.codex/verified-input-blocks/operators.solid_momentum_2d/1.0.0.i
# verified-block: executioner.transient_newton@1.0.0
!include ../../../.codex/verified-input-blocks/executioner.transient_newton/1.0.0.i
# verified-block: outputs.csv@1.0.0
!include ../../../.codex/verified-input-blocks/outputs.csv/1.0.0.i

# Scenario-local, non-protected objects.
!include ../scenarios/verified_q2_eg_mms_2d.i
