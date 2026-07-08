# Vision

This repository is developing a technical manuscript whose goal is to derive an exceptionally thermodynamically consistent formulation for coupled reservoir simulation and solid mechanics. The manuscript remains the source of truth for the theory, but the repository's broader purpose is to carry that theory into a validated MOOSE implementation and, eventually, an agent-assisted simulation workflow for general multicomponent, multiphase mixture mechanics.

The central aim is to build the theory from first principles: multicomponent, multiphase mass balance; phase transformations and chemical reactions; mixture kinematics; solid deformation; pore-scale volume constraints; entropy production; and constitutive restrictions. The formulation should make every force, flux, source, multiplier, and thermodynamic driving force traceable to a clear balance law, variational statement, or Coleman--Noll argument.

The paper should also connect this general theory to traditional reservoir simulation and geomechanics. That means showing exactly how standard compositional simulation, black-oil-style limits, phase equilibrium assumptions, Darcy-scale closures, poromechanics, and familiar pressure/saturation/composition equations appear as special cases or approximations of the more general framework.

Where possible, the manuscript should not stop at broad analogy. It should derive representative special cases all the way down to recognizable engineering equations, such as black-oil equations, compositional balance equations, and coupled mechanics limits, while making explicit what assumptions are required and what thermodynamic structure is lost or retained.

The tone of the work should be ambitious but precise: the claim is not merely that the framework is general, but that its consistency can be inspected equation by equation.

## Repository Roadmap

The work should now be organized around three coordinated tracks, not three isolated projects.

1. Theory, verification, and publication. Continue the current manuscript until it is ready for publication. This track owns the mathematical formulation, notation, thermodynamic restrictions, special-case reductions, and comparison to existing reservoir simulation, geomechanics, and mixture-theory models.

2. MOOSE implementation and validation. Build the finite-element and finite-volume kernels, materials, actions, boundary conditions, and test infrastructure needed to implement the theory in MOOSE. This track should produce a companion implementation-and-validation paper. Its validation suite should begin with the special cases derived in the theory paper, including black-oil-style equations, compositional flow, coupled mechanics limits, phase equilibrium reductions, reaction/source problems, and benchmark reservoir-simulation challenge problems such as SPE comparison problems.

3. Agent-assisted simulator workflow. Build an agent-facing workflow around the validated MOOSE implementation so that users can describe a multicomponent, multiphase mixture-mechanics problem in conversation and generate, check, run, and revise structured MOOSE input decks with high precision. This track should treat input-deck generation as an engineering interface: templates, schemas, validation checks, clarification questions, run commands, postprocessing routines, and failure diagnosis should become explicit repository artifacts rather than informal chat behavior.

The near-term repository structure should preserve tight feedback between these tracks. The theory should continue to live in the manuscript source. Implementation work should grow beside it in a MOOSE application or subdirectory, with tests and examples tied back to named equations and assumptions in the manuscript. Agent workflow assets should live in a separate instructions/templates area so they can evolve without polluting either the paper or the simulator source.

The first milestone is not to solve every validation problem. It is to define the interfaces cleanly: map manuscript equations to implementable residual terms, choose the first minimal kernel set, define the first validation matrix, and create a repeatable input-deck template/validation workflow for one or two representative problems. After that, each new benchmark should improve all three tracks at once: a clearer theoretical reduction, a tested simulator capability, and a more reliable agent workflow for setting up that class of problem.
