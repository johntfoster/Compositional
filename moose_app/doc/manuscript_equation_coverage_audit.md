# Manuscript equation coverage audit

The generated audit in `manuscript_equation_coverage_audit.yml` follows the
input graph rooted at `main.tex`. It inventories every `eq:` label in the
included source, records its file and line, and classifies it as a runtime
operator, constitutive or algebraic relation, definition or kinematic
identity, derivation-only equation, comparison reduction, or excluded fracture
equation. The generator joins those records to the structured implementation
and validation maps listed in the YAML file.

The current graph contains 444 unique equation labels. It contains no
fracture-labeled equation. `sections/coleman_noll.tex` is explicitly reported as
a nonincluded source and does not contribute labels.

The audit distinguishes equivalent formulations and derived constraints from
independent residuals. The early and summary momentum forms are linked to the
mapped production momentum residuals; charge conservation and the phase mass
sum are consequences of the conserved component equations. All 24 runtime
operators now have an object and test mapping. In particular,
`eq:solid_reference_solid_component_balance` maps to the atomic reference
storage, separately selectable dispersion/diffusion flux, and source kernels;
the source-free single-solid-component reduction is covered by the
`solid_phase_mass_volume` regression.

Constitutive coverage gaps are reported separately. These are equations for
which the existing structured maps contain no exact object or test
association; the flag does not by itself prove that no reusable implementation
exists. The principal review families are:

- general solid free energy, phase pressure, stress, entropy, phase Legendre,
  and phase/component Biot relations;
- the complete generic plastic-deformation and plastic-distension flow laws;
- generic pairwise mechanical interaction, drag heating, internal-energy
  exchange, and fluid-solid heat exchange;
- dynamic-capillary and capillary-history admissibility relations;
- reaction-energy allocation and the older/final Onsager reaction, diffusion,
  and dispersion forms;
- coupled relative-flux linear-system and modified-permeability relations; and
- the crystallization-pressure specialization.

Regenerate after any manuscript or mapping change with:

```bash
PYTHONDONTWRITEBYTECODE=1 python3 moose_app/doc/build_manuscript_equation_audit.py
```

The YAML source hashes make a stale audit detectable. A coverage gap should be
closed by adding an exact mapping to an implemented object and durable test, or
by recording why the equation is an identity, derived constraint, admissibility
check, or equivalent form that requires no independent runtime object.
