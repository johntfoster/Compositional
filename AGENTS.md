# AGENTS.md

## Project roadmap

- Read `VISION.md` at the start of repository work and use it as the high-level guide for the three coordinated tracks: theory manuscript, MOOSE implementation and validation, and agent-assisted simulator workflow.
- Treat these tracks as coupled work, not isolated projects. Manuscript equations should inform implementation tasks; implementation and validation gaps should feed back into the manuscript; agent workflow assets should encode validated simulator practice.
- Keep the current manuscript as the source of truth for the theory until a separate implementation paper or simulator documentation explicitly supersedes a claim for its own scope.
- The active repository layout is:
  - `main.tex`, `defs.tex`, `sections/`, `all.bib` -- current theory manuscript.
  - `implementation_paper/` -- companion finite-element implementation and verification paper.
  - `moose_app/` -- clean MOOSE application scaffold for the new compositional implementation.
  - `validation/` -- validation matrix, reference data, and postprocessing assets.
  - `agent_workflows/` -- input-deck templates, schemas, run recipes, checks, and troubleshooting assets.
  - `references/` -- source PDFs and durable reading notes.
- Use `agent_workflows/decision_trees/request_router.md` as the first routing aid when a task is not purely local. Use the narrower decision trees, checklists, schemas, and runbooks under `agent_workflows/` when their trigger matches the request.
- Do not split repository structure, branch strategy, or workflow ownership casually. Prefer small, reversible additions that preserve cross-links between theory, code, validation examples, and agent templates.
- When a task touches more than one track, state which track owns the immediate edit and which downstream tracks need follow-up.

## Manuscript source of truth

- Treat `main.tex` as the canonical root of the manuscript. Start from `main.tex`, follow its `\\input`, `\\include`, bibliography, macro, and package declarations, and interpret all included TeX in that root context.
- Manuscript body files are organized under `sections/`, but they are not standalone documents. Interpret them only through the `main.tex` root context.
- Store intentional research PDFs in `references/pdfs/` and human reading notes in `references/notes/`. Use the `latex-research-ingest` skill's local `.codex-research/` store for PDF ingestion and retrieval. Treat generated LaTeX, preview, and retrieval state as non-authoritative workflow artifacts.
- When answering questions about the paper, prefer exact evidence from `main.tex` and included TeX files over memory, generated PDFs, auxiliary files, notes, or ingested reference chunks.
- Cite source locations as `file:line` whenever making claims about manuscript text, notation, assumptions, derivations, equation labels, or references.
- Do not infer global notation from isolated snippets. Resolve definitions, labels, counters, macros, and theorem/equation environments through the `main.tex` compilation graph.

## Operating checklist for manuscript tasks

- At the start of every repository task, read `AGENTS.md` and `VISION.md`, then classify the task as manuscript theory, MOOSE implementation, validation, agent workflow, or cross-track planning.
- At the start of every manuscript task, also read `main.tex` and `defs.tex` before interpreting section-local notation.
- If the user cites a rendered equation number, resolve it through the active build artifacts before answering or editing. Prefer `build/main.aux` when the build directory is active.
- Before answering conceptual questions, identify the exact source equations, definitions, and assumptions that control the question, and cite them as `file:line`.
- When a notation change affects a derivation, propagate it through state sets, chain-rule terms, thermodynamic forces, restrictions, and downstream prose instead of patching only the visible equation.
- Separate kinematic fields from constitutive arguments before renaming symbols. Do not replace every occurrence of a symbol merely because one role changed.
- When the user narrows an edit to a section, subsection, equation, or paragraph, keep edits strictly inside that scope unless the user explicitly expands it.
- Number and descriptively label every displayed equation or identity introduced by an agent, including helper identities. Do not introduce unnumbered displayed mathematics unless John explicitly requests it.
- For citation or external-paper equation claims, verify the cited equation in the source PDF before changing manuscript text.

## Response modes

- For interpretive questions, answer from the manuscript source first, then explain the mathematical implication. Avoid importing outside theory unless the manuscript source or user request calls for it.
- For edit requests, make the smallest source change that fixes the issue, then validate affected labels, references, and display math.
- For derivation audits, report whether the current source supports the claim, what assumptions would be needed if it does not, and where the downstream equations would change.
- For implementation planning, map each proposed kernel, material, variable, boundary condition, or action back to the controlling manuscript equation, assumption, or special-case reduction before proposing code structure.
- For validation planning, identify the physical regime, governing reduction, variables, expected observables, and pass/fail criterion. Prefer validation problems that exercise both the mathematical theory and the simulator interface.
- For agent-workflow tasks, treat templates, schemas, checks, prompts, run commands, and postprocessing scripts as repository artifacts that should be versioned, tested where practical, and kept consistent with the validated MOOSE interface.
- For cross-track implementation planning, keep `implementation_paper/equation_to_moose_map.yml`, `moose_app/doc/theory_traceability.yml`, and `validation/validation_matrix.yml` aligned when a decision becomes durable.

## MOOSE implementation track

- Implementation work lives in `moose_app/`, a clean MOOSE application scaffold that is intentionally independent of the earlier three-phase/Talha app. Use the earlier app as technical memory and evidence for AD patterns, not as a source tree to copy.
- The companion implementation-and-verification manuscript lives in `implementation_paper/`. Its finite-element equations should be written on the reference configuration of the solid skeleton unless John explicitly changes that decision.
- Keep MOOSE source, tests, examples, and documentation separate from LaTeX manuscript source. Do not put kernels or input decks under the theory manuscript `sections/` tree.
- Preserve traceability from code to theory. New kernels, materials, actions, boundary conditions, and tests should cite the manuscript equation labels or section names they implement whenever the connection is non-obvious.
- Start from the smallest useful kernel set. Prefer one validated residual path over broad scaffolding for many equations that are not yet tested.
- Keep finite-element, finite-volume, material-property, and PorousFlow integration decisions explicit. Do not hide discretization assumptions inside generic names or undocumented helper code.
- Treat implementation tests as part of the research argument. Unit tests, regression tests, manufactured solutions, special-case reductions, and benchmark input files should be organized so they can support the companion implementation-and-validation paper.
- Do not rewrite the theory to fit a convenient API without flagging the approximation. If a MOOSE implementation requires a closure, linearization, stabilization, variable choice, or weak-form assumption not present in the manuscript, record that gap in the implementation notes or validation plan.
- Use MOOSE automatic differentiation by default. Scalar thermodynamic potentials may be exposed through `ADDerivativeParsedMaterial` or derivative-material wrappers so oil/compositional partial derivatives can be generated automatically when the potential is a parsed scalar function of coupled variables. Still write explicit materials/user objects for tensor kinematics, pull-backs, phase closure, flash/EOS solves, tabulated PVT/CALPHAD data, flux laws, constraints, and any nontrivial state transformation.
- Future kernels should remain residual objects: they consume AD material properties and encode weak-form terms, but they should not hide thermodynamics, phase behavior, and mechanics inside one monolithic object.

## Validation and benchmark track

- Maintain a validation matrix as this track develops. Each entry should list the target phenomenon, manuscript reduction, MOOSE objects required, input deck location, reference result, expected outputs, and current status.
- Begin with special cases already derived or planned in the manuscript: black-oil-style equations, compositional flow, coupled mechanics limits, phase equilibrium reductions, reaction/source problems, and phase-transformation examples.
- Add reservoir-simulation challenge problems, including SPE comparison-style benchmarks, only with clear notes about which parts of the full theory they validate and which assumptions they impose.
- Prefer validation problems that can become durable regression tests. If a problem is too expensive for routine testing, create a smaller smoke test or reduced analogue that protects the same implementation path.
- Keep benchmark data, generated outputs, and postprocessing products distinct. Source input decks, reference data, and analysis scripts are authoritative; transient run outputs are not.

## Agent-assisted simulator workflow

- Build agent-facing simulator assets as explicit files: input-deck templates, parameter schemas, checklist prompts, validation scripts, run recipes, postprocessing recipes, and troubleshooting notes.
- Generate MOOSE input decks from structured templates whenever possible. Avoid one-off freeform decks unless the task is exploratory and the uncertainty is clearly stated.
- Before running a generated deck, validate required variables, kernels, materials, boundary conditions, units, mesh assumptions, executioner settings, outputs, and postprocessors against the selected template or schema.
- Ask clarification questions when the physical problem is underspecified in a way that changes the governing equations, constitutive closures, boundary conditions, initial conditions, or validation target.
- When a simulation fails, diagnose in layers: input syntax, missing MOOSE objects, inconsistent variables/material properties, solver configuration, discretization/stabilization, then model assumptions.
- Successful agent workflows should feed back into durable templates and checks so future problem setup becomes more reliable rather than remaining chat-local.

## Precision LaTeX parsing and reading

- Act as a precision LaTeX parser and reader, not a loose text searcher. Preserve TeX semantics, macro expansion context, math-mode boundaries, environment nesting, labels, refs, citations, and local definitions.
- Always inspect `defs.tex` when interpreting notation or shorthand the user writes in chat, since chat shorthand may refer to manuscript macros or local notation conventions.
- When discussing mathematical notation with the user, show displayed/rendered LaTeX by default. Provide raw TeX source only when the user explicitly asks for code or when an edit/diff requires source-level precision. Since chat renderers do not automatically load project-local macros from `defs.tex`, expand shorthand such as `\mc`, `\mbf`, `\bs`, and `\p` to standard LaTeX in displayed chat math unless you also provide the macro definitions in that response.
- Before changing equations, labels, notation, cross-references, theorem statements, or bibliography usage, inspect the surrounding TeX source and the relevant definitions/macros.
- Prefer reusing existing notation and writing short expressions inline over introducing new named symbols. This manuscript already has many symbols, so introduce a new symbol only when it materially improves clarity, reduces repeated complexity, or is needed for a standard term.
- Do not introduce new derived variables, helper tensors, residuals, rate symbols, force maps, or shorthand symbols such as `L`, `R`, `Q`, `C`, or similar unless you first ask the user and receive explicit approval. When revising entropy inequalities or Coleman--Noll collections, write the terms directly in the primitive manuscript variables instead of introducing helper notation.
- For mechanism-indexed quantities, use parenthesized subscripts on the variables, such as `\dot r_{(m)}`, `\nu_{\xi (m)}^\alpha`, and `\mc A_{(m)}`. Do not parenthesize the dummy summation index under the summation sign: write `\sum_m`, not `\sum_{(m)}`.
- Do not write numbered display equations as chained multiple-equals expressions on one line. When a result needs multiple equality steps, use an `align` environment and align the equals signs vertically so each step is visually and mathematically clear.
- Treat displayed equations as grammatical parts of their surrounding sentences. Punctuate each display accordingly, and do not place a colon at the end of the prose immediately preceding a display that completes the same sentence.
- Write manuscript prose for a new audience versed in continuum mechanics and reservoir simulation. The text must be self-contained and must not read as a development note to the author, assume knowledge of prior conversations, or refer implicitly to discarded formulations and earlier drafting decisions.
- Do not use manual delimiter sizing commands such as `\Big`, `\bigg`, `\Bigg`, or related variants for parentheses, brackets, or braces. Use nested automatic delimiters such as `\left(` and `\right)`, `\left[` and `\right]`, or `\left\{` and `\right\}` instead.
- Treat text between `% AGENT-LOCK-BEGIN` and `% AGENT-LOCK-END` as protected manuscript source. Do not edit locked equations or surrounding locked text unless the user explicitly says to unlock them or explicitly names the locked equation as an edit target.
- Prefer source-based LaTeX inspection rooted at `main.tex`, texlab/LSP diagnostics, and local build artifacts for equation/citation/file inspection.
- Use focused equation, citation, and source-file inspection before broad filesystem rewrites.
- Distinguish manuscript source from generated artifacts. LaTeX build products such as `.aux`, `.log`, `.out`, `.bbl`, `.blg`, `.fls`, `.fdb_latexmk`, `.synctex.gz`, and PDFs under `build/` are not authoritative except for diagnostics or rendered-number lookup.
- Never commit LaTeX build artifacts. Keep `build/` and generated LaTeX outputs untracked; if any are accidentally staged or tracked, remove them from the Git index with `git rm --cached` rather than deleting the user's local build outputs.

## texlab / LSP awareness

- The TeX language server `texlab` is available. Use direct LSP diagnostics, definitions, references, document symbols, hovers, renames, and code actions when precise LaTeX navigation or validation is needed.
- Use the `latex-workshop-recompile` skill every time a manuscript build, rebuild, recompile, PDF refresh, aux refresh, or equation-number validation is needed.
- For compile or editor-style issues, prefer texlab diagnostics, LaTeX Workshop output, and narrow source edits before making broader changes. Make narrow source edits that address the reported line, label, macro, or environment.
- When a LaTeX build is needed and VS Code LaTeX Workshop tooling is available, trigger the build through LaTeX Workshop rather than invoking a raw LaTeX command directly.
- Use LaTeX Workshop build commands as the default build path for this workspace so the PDF viewer open in VS Code refreshes. Prefer the extension's build/build-and-view workflow over shell commands such as `lualatex`, `pdflatex`, or `latexmk`. Use raw shell compilation only when LaTeX Workshop is unavailable, when a non-view diagnostic compile is explicitly needed, or when the user explicitly asks for it; in that case, say that the open PDF may not refresh.
- If aux data, equation numbering, or the open PDF preview is stale, refresh through LaTeX Workshop from `main.tex` before relying on rendered numbers.

## Local research retrieval

Use the `latex-research-ingest` skill for research PDF ingestion and retrieval.
It creates and queries `.codex-research/` without relying on chat-preview,
rag-pi, or `.ragpi/`.

- Prefer `references/pdfs/` for original PDFs and `references/notes/` for durable notes.
- Build/update the local store with `research_store.py ingest`.
- Retrieve targeted context with `research_store.py retrieve`.
- Do not read or send the whole vector store when a targeted retrieval is enough.
- For manuscript mechanics claims, the TeX source rooted at `main.tex` still overrides retrieved reference chunks.
