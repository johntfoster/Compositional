# Bothe and Dreyer (2015): reacting fluid mixtures

## Source

Dieter Bothe and Wolfgang Dreyer, “Continuum Thermodynamics of Chemically
Reacting Fluid Mixtures,” *Acta Mechanica* 226(6), 1757–1805 (2015).
DOI: 10.1007/s00707-014-1275-1.  Manuscript preprint: arXiv:1401.5991v3.

Repository PDF:
`references/pdfs/bothe-dreyer-2015-reacting-fluid-mixtures.pdf`.

BibTeX key: `bothe2015continuum`.

## Why it matters here

- The introduction clearly separates universal balance laws from constitutive
  assumptions and compares thermodynamics of irreversible processes, rational
  thermodynamics, extended thermodynamics, and continuum thermodynamics.
- The class-II model uses constituent mass densities and velocities together
  with one common mixture temperature (preprint pp. 5–6).
- The mixture internal-energy balance is transported by the barycentric
  velocity (preprint p. 8).
- The entropy principle is formulated for mixture entropy and exploited using
  the mixture, or barycentric, velocity (preprint pp. 15–17).
- The paper distinguishes class-I, class-II, and class-III descriptions.  The
  last permits constituent-specific temperatures; the first two use one common
  temperature (preprint pp. 5–6).
- It derives thermodynamically consistent reaction, diffusion, heat-conduction,
  and partial-momentum closures and discusses entropy-invariant reduction from
  partial to barycentric momentum balances.

## Relevance to the manuscript rate convention

The paper supports using constituent-following rates for constituent balances
and a barycentric rate for collective mixture quantities.  A common temperature
is a single spatial field, but its derivative along constituent motion differs
from its barycentric derivative unless relative-velocity gradient terms vanish
or are retained explicitly.

For the present manuscript, a consistent convention would therefore:

1. retain \(D_\xi(\cdot)/Dt\) for phase-indexed thermodynamic quantities;
2. use \(D_\xi\theta/Dt\) when differentiating a phase free energy along phase
   \(\xi\);
3. use the barycentric derivative for collective interfacial energy
   \(\phi\gamma\), with the chosen transport velocity stated explicitly; and
4. retain the relative-velocity correction when converting between phase and
   barycentric temperature rates.

## Future citation placement

The paper is best cited in the introduction or literature-positioning section
when that section is written.  It can support:

- the distinction between balance-law structure and constitutive closure;
- the use of a common-temperature class-II mixture model;
- the relationship between partial-momentum and barycentric formulations; and
- thermodynamically consistent reaction and diffusion closures.

Do not add it merely as a generic citation to a local algebraic step.  A later
technical citation may be appropriate where the manuscript explicitly declares
its common-temperature and barycentric-rate conventions.
