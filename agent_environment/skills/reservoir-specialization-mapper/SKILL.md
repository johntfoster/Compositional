---
name: reservoir-specialization-mapper
description: Map the manuscript's general mixture theory to reservoir-simulation and geomechanics special cases. Use for questions or edits about black-oil limits, compositional flow, capillary pressure, relative permeability, Darcy closures, pressure-saturation equations, phase equilibrium assumptions, Biot or poromechanics limits, and what thermodynamic structure is retained or lost.
---

# Reservoir Specialization Mapper

Use this skill to bridge the manuscript theory to familiar reservoir forms.

## Workflow

1. Read `AGENTS.md`, `main.tex`, and `defs.tex`.
2. Locate the controlling source in `sections/correspondence_to_other_theories.tex`
   and any upstream equation labels it cites.
3. Identify the target special case:
   - black-oil style
   - compositional flow
   - capillary pressure
   - Darcy flux
   - phase equilibrium
   - poromechanics or Biot limit
   - reaction/source reduction
4. Build the map:
   - general manuscript quantity
   - familiar reservoir quantity
   - assumptions added
   - terms retained
   - terms dropped or hidden by closure
   - current-volume versus reference-side bookkeeping
5. Keep terminology manuscript-consistent. Use phase-indexed or water/oil/gas
   language for relative permeability unless the context is capillary-pressure
   wetting/non-wetting pairs.

## Output

Lead with the local physical story, then give the formal map. Cite manuscript
source locations for every controlling equation or definition.
