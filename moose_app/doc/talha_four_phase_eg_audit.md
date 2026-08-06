# Talha four-phase EG audit

Source inspected read-only: `https://github.com/s-tirmizi/ReactingMixtureMechanics2026`,
branch `four_phase`, downloaded by GitHub API to
`/tmp/ReactingMixtureMechanics2026-four_phase`.

## Applicable patterns

- Keep conservative fluxes as material properties and let kernels consume them.
  The EG pressure and saturation DG kernels read `rel_mass_flux_ref` and mobility
  tensors from materials instead of rebuilding Darcy laws inside face kernels.
- Separate continuous Galerkin volume residuals from enriched face coupling.
  The branch uses DG kernels for enrichment jumps and companion CG-row symmetry
  terms where the enrichment test-gradient is zero.
- Scale interior penalties with local face length and normal mobility, for
  example `(sigma / h) {{n . M . n}} [[u]] [[v]]` for pressure-like operators.
- Treat upwind choices as value-based branch decisions while keeping the chosen
  flux expression automatic-differentiation active.
- Freeze entropy-viscosity stabilization in element-wise auxiliary variables
  and use separate CG and DG diffusion objects for volume and face terms.
- Document penalty options and degeneracy explicitly. The branch notes that
  flux-scaled saturation jump damping degenerates when the driving flux vanishes.

## Incompatible assumptions for this repository

- The deformation-gradient material is hard-coded for two displacement variables
  and a 2D inverse. The compositional app must keep the dimension-aware
  `ADSolidReferenceKinematics` pattern for 1D, 2D, and 3D.
- The flux materials are tied to partially saturated liquid/gas variables,
  saturation enrichments, tau enrichments, and Corey/Kozeny-Carman choices. The
  current theory requires phase/component labels and closures to remain explicit.
- Several materials combine capillary pressure, relative permeability,
  conversion source, tau forcing, and solid velocity in one object. For the new
  implementation those closures should be split into storage, thermodynamics,
  phase mobility, relative flux, and component-flux assembly materials.
- Existing EG kernels assume specific enriched variables such as `p_f_enr`,
  `S_f_enr`, and `tau` enrichment. They should be used as interface guidance,
  not copied into the solid-reference component-balance slice.
- Entropy viscosity is tailored to a saturation equation. The reusable part is
  the lagged element-wise stabilization interface; the residual definition must
  be rederived for each component or phase equation before use here.

## Near-term reuse decision

For the next compositional milestones, reuse the interface pattern: AD material
properties for fluxes and mobilities, kernels as residual-only consumers, and
explicit face objects for future EG penalties. Do not port the old 2D
deformation-gradient code, saturation-specific flux closures, or tau-enrichment
objects into the clean app.
