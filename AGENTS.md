# AGENTS.md

## Active coordination notice: verified input blocks

- Code-verification agents must re-read the verified input-block rules in the
  Agent-assisted simulator workflow section and the scoped instructions in
  `moose_app/input/AGENTS.md` and `moose_app/test/AGENTS.md` before editing or
  running input decks. The registry and protected versioned payload store are
  active as of 2026-08-05.

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
- Before making any repository edit, read `author_style_profile_2026-07-27.md`. Apply its full prose rules to manuscript text, captions, tables, source comments, documentation, and agent-workflow material; for non-prose edits, apply its constraints against unnecessary terminology, notation, commentary, and scope changes.
- If the user cites a rendered equation number, resolve it through the active build artifacts before answering or editing. Prefer `build/main.aux` when the build directory is active.
- Before answering conceptual questions, identify the exact source equations, definitions, and assumptions that control the question, and cite them as `file:line`.
- When a notation change affects a derivation, propagate it through state sets, chain-rule terms, thermodynamic forces, restrictions, and downstream prose instead of patching only the visible equation.
- Separate kinematic fields from constitutive arguments before renaming symbols. Do not replace every occurrence of a symbol merely because one role changed.
- When the user narrows an edit to a section, subsection, equation, or paragraph, keep edits strictly inside that scope unless the user explicitly expands it.
- Number and descriptively label every displayed equation or identity introduced by an agent, including helper identities. Do not introduce unnumbered displayed mathematics unless John explicitly requests it.
- For citation or external-paper equation claims, verify the cited equation in the source PDF before changing manuscript text.
- After any edit to manuscript source, including `main.tex`, `defs.tex`, `sections/*.tex`, or `all.bib`, rebuild the manuscript from `main.tex` with the `latex-workshop-recompile` skill before reporting the edit complete.

## Response modes

- For interpretive questions, answer from the manuscript source first, then explain the mathematical implication. Avoid importing outside theory unless the manuscript source or user request calls for it.
- For edit requests, make the smallest source change that fixes the issue, then validate affected labels, references, and display math.
- For derivation audits, report whether the current source supports the claim, what assumptions would be needed if it does not, and where the downstream equations would change.
- For implementation planning, map each proposed kernel, material, variable, boundary condition, or action back to the controlling manuscript equation, assumption, or special-case reduction before proposing code structure.
- For validation planning, identify the physical regime, governing reduction, variables, expected observables, and pass/fail criterion. Prefer validation problems that exercise both the mathematical theory and the simulator interface.
- For agent-workflow tasks, treat templates, schemas, checks, prompts, run commands, and postprocessing scripts as repository artifacts that should be versioned, tested where practical, and kept consistent with the validated MOOSE interface.
- For cross-track implementation planning, keep `implementation_paper/equation_to_moose_map.yml`, `moose_app/doc/theory_traceability.yml`, and `validation/validation_matrix.yml` aligned when a decision becomes durable.

## MOOSE implementation track

- Before building or running `moose_app/`, use the repository-local
  `setup-moose-conda` skill at `.codex/skills/setup-moose-conda/SKILL.md`. Run
  its non-destructive diagnostic first; it documents the verified `moose`
  Conda environment, durable MOOSE checkout, `/tmp/moose` compatibility link,
  explicit `conda run` invocation, conservative build command, and MPI sandbox
  escalation guidance. The coupled Q2/EG production element requires a
  128-entry MOOSE AD backing store, a matching installed
  `include/moose/ADRealMonolithic.h`, and runtime execution inside the same
  Conda environment. After changing AD size, move any existing
  `moose_app/.jitcache` to a recoverable, uniquely named `/tmp` backup before
  rerunning; stale JIT shared objects are ABI-incompatible. Do not replace a
  conflicting runtime path or install a new toolchain without user approval.
- Treat the MOOSE checkout as pinned external source. Any intentional edit
  under /home/jfoster/.local/moose must be stored as a numbered patch under
  moose_app/patches/moose/, recorded with base commit, SHA-256, rationale,
  tests, and application state in series.yml, and assessed in
  moose_app/doc/moose_upstream_candidates.yml for an upstream pull request.
  Every series entry must list its exact affected files. The
  setup-moose-conda diagnostic must validate the complete ordered series and
  reject unrecognized staged, unstaged, or untracked core changes. The
  canonical `moose_app/cmake/build_opt.cmake` wrapper records MOOSE HEAD and
  status and runs that diagnostic before and after each build attempt.
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

- Before editing application source, input decks, verification scripts, or
  manuscript source, and before building or running tests, check for
  `/tmp/multicomponent_reactive_flow_spe_acceptance.lock`.  The SPE acceptance
  runner creates this marker while it hashes and executes a provenance-critical
  benchmark.  While the recorded process is live, defer every edit, build, or
  test that could change the source tree, executable, runtime library, resolved
  deck, or manuscript; read-only inspection may continue.  A stale marker is
  moved to a uniquely named recoverable file by the next acceptance run.

### SPE verification model and discretization

- SPE benchmark acceptance must exercise this repository's finite-deformation,
  solid-reference mixture theory. A benchmark-specific finite-volume reduction
  may be retained as a separately labeled numerical diagnostic, but it cannot
  satisfy SPE acceptance and its agreement with OPM must not be reported as
  verification of the production theory.
- SPE1 uses the physically required four-phase registry: one deformable solid
  matrix phase plus water, oil, and gas fluid phases. The conserved fluid
  components are stock-tank water, stock-tank oil, and stock-tank gas; gas is
  present in the gas phase and dissolved in the oil phase according to the
  black-oil closure. Register and conserve the solid constituent as required by
  the finite-deformation mixture equations. Do not collapse the solid phase to
  imposed `J = 1` kinematics in the production benchmark.
- Solve solid displacement and the coupled component/phase state from the
  finite-deformation solid-reference momentum, component-balance, phase-volume,
  constitutive, and well/source equations. Every residual, material property,
  closure, boundary condition, and observable must trace to the manuscript or
  to an explicitly identified SPE1 constitutive datum.
- Use the validated CG/EG architecture: Q2 Lagrange displacement; a P1
  continuous oil/equivalent-pressure backbone plus P0 enrichment and total
  reconstructed pressure; P2 continuous water and gas saturation backbones
  plus P0 enrichments with physical reconstructed saturation and entropy
  viscosity; the required EG interior-facet and weak boundary operators; and
  the parent continuous closure for solution gas. The production SPE
  acceptance deck must not switch these
  primaries to cell-centered finite-volume variables, pure CG pressure, or a
  fixed-skeleton surrogate.
- Preserve the official SPE1 geometry, layers, PVT and saturation tables,
  schedule, completions, controls, and reference observables. Resolve the
  compatible Q2/EG three-dimensional mesh policy explicitly and document any
  reference-grid-to-finite-element mapping; do not silently call a different
  mesh the official 300-cell discretization.
- Passing means that the theory-to-code traceability, AD/PETSc Jacobian,
  component and solid mass balances, phase-volume closure, mechanics balance,
  mesh/time-step convergence, and required solver tests pass without skips.
  OPM/published comparison errors are reported as physical benchmark results,
  not as a gate that may be achieved by tuning, weakening tolerances, changing
  discretization, prescribing fields, or substituting cached/reference values.
- Never weaken, delete, skip, xfail, bypass, or redefine a required test to make
  SPE acceptance pass. Never relabel an FV, `solve = false`, prescribed-field,
  material-only, or postprocessed reference path as a coupled CG/EG
  finite-deformation solve.

- Maintain a validation matrix as this track develops. Each entry should list the target phenomenon, manuscript reduction, MOOSE objects required, input deck location, reference result, expected outputs, and current status.
- Begin with special cases already derived or planned in the manuscript: black-oil-style equations, compositional flow, coupled mechanics limits, phase equilibrium reductions, reaction/source problems, and phase-transformation examples.
- Add reservoir-simulation challenge problems, including SPE comparison-style benchmarks, only with clear notes about which parts of the full theory they validate and which assumptions they impose.
- Prefer validation problems that can become durable regression tests. If a problem is too expensive for routine testing, create a smaller smoke test or reduced analogue that protects the same implementation path.
- Keep benchmark data, generated outputs, and postprocessing products distinct. Source input decks, reference data, and analysis scripts are authoritative; transient run outputs are not.

## Agent-assisted simulator workflow

- Build agent-facing simulator assets as explicit files: input-deck templates, parameter schemas, checklist prompts, validation scripts, run recipes, postprocessing recipes, and troubleshooting notes.
- Treat `moose_app/input/verified_block_registry.yml` as the authority for reusable input-fragment status and exact content. Each `verified` fragment has a versioned protected payload under `.codex/verified-input-blocks/`; assembled decks consume that payload. The matching include-tree source is also locked so candidate development cannot diverge silently. Agents may include verified blocks, but they must not edit either copy, the registry digest, recorded object inventory, version, or verification evidence. An intentional change requires John’s explicit authorization, a higher semantic version, fresh mapped test evidence, and the `verified-block-promotion` skill. Run the `deck-integrity-validator` skill before accepting or running an assembled deck and after any edit under `moose_app/input/`.
- Use the repository-local `deck-block-inventory` skill to account for new input fragments and individual MOOSE objects. Candidate fragments remain editable, but their catalog and candidate registry records must be refreshed together. Use the `deck-assembler` skill for regression, benchmark, and production decks so protected kernels, DG kernels, materials, scalar kernels, auxiliary kernels, and user objects enter generated decks only through verified includes.
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
- Do not place a multi-line `aligned`, `split`, `gathered`, or similar subenvironment inside a single pair of brackets or parentheses. When one equation must span several lines within a delimiter, break the outer equation across the `align` rows and continue the delimiter with matched invisible delimiters such as `\left[ ... \right.` on the first row, `\left. ... \right.` on continuation rows, and `\left. ... \right]` on the final row.
- Treat displayed equations as grammatical parts of their surrounding sentences. Punctuate each display accordingly, and do not place a colon at the end of the prose immediately preceding a display that completes the same sentence.
- Write manuscript prose for a new audience versed in continuum mechanics and reservoir simulation. The text must be self-contained and must not read as a development note to the author, assume knowledge of prior conversations, or refer implicitly to discarded formulations and earlier drafting decisions.
- Do not use negative-positioning prose to advertise the manuscript. In particular, do not characterize the contribution by listing what prior papers, precedents, earlier formulations, or the present model "do not" contain, "have not" developed, or are "not like." After reviewing prior work, state positively what each cited source contributes and then state directly what this paper derives. Use negation only when it is required to define a mathematical condition, distinguish two quantities that could genuinely be confused, state an operative modeling assumption or excluded physical mechanism, or delimit a result whose interpretation would otherwise be incorrect.
- Before completing any manuscript prose edit, scan the edited paragraphs for contrastive constructions such as "but ... do not," "does not present," "has not," "unlike," "rather than," "not merely," "not ad hoc," and "not a." Rewrite any rhetorical or contribution-positioning use as a positive statement of physical role, derivation, result, or scope. Do not mechanically remove necessary mathematical negations or precise model limitations.
- Do not use manual delimiter sizing commands such as `\Big`, `\bigg`, `\Bigg`, or related variants for parentheses, brackets, or braces. Use nested automatic delimiters such as `\left(` and `\right)`, `\left[` and `\right]`, or `\left\{` and `\right\}` instead.
- Treat text between `% AGENT-LOCK-BEGIN` and `% AGENT-LOCK-END` as protected manuscript source. Do not edit locked equations or surrounding locked text unless the user explicitly says to unlock them or explicitly names the locked equation as an edit target.
- Prefer source-based LaTeX inspection rooted at `main.tex`, texlab/LSP diagnostics, and local build artifacts for equation/citation/file inspection.
- Use focused equation, citation, and source-file inspection before broad filesystem rewrites.
- Distinguish manuscript source from generated artifacts. LaTeX build products such as `.aux`, `.log`, `.out`, `.bbl`, `.blg`, `.fls`, `.fdb_latexmk`, `.synctex.gz`, and PDFs under `build/` are not authoritative except for diagnostics or rendered-number lookup.
- Never commit LaTeX build artifacts. Keep `build/` and generated LaTeX outputs untracked; if any are accidentally staged or tracked, remove them from the Git index with `git rm --cached` rather than deleting the user's local build outputs.
- When an agent invokes a LaTeX build itself, with `latexmk`, `pdflatex`, `lualatex`, or similar, direct every build artifact into the `build/` directory and never into the repository root. Run raw builds with an explicit output directory, for example `latexmk -outdir=build main.tex` or `pdflatex -output-directory=build main.tex`. The repository-root `.latexmkrc` already sets `$out_dir = 'build'`, so a bare `latexmk main.tex` invoked from the repository root also writes into `build/`; passing `-outdir=build` explicitly is equivalent and is what LaTeX Workshop does via `.vscode/settings.json`. After any such build, confirm that no `.aux`, `.bbl`, `.blg`, `.fls`, `.fdb_latexmk`, `.log`, `.out`, `.synctex.gz`, or PDF files were left at the repository root, and remove any strays before finishing. `build/` is the only sanctioned location for generated LaTeX output.

## texlab / LSP awareness

- The TeX language server `texlab` is available. Use direct LSP diagnostics, definitions, references, document symbols, hovers, renames, and code actions when precise LaTeX navigation or validation is needed.
- Use the `latex-workshop-recompile` skill every time a manuscript build, rebuild, recompile, PDF refresh, aux refresh, or equation-number validation is needed.
- After every manuscript compilation, inspect the rendered pages around displays that span or approach a page boundary. Choose semantically appropriate page-break locations, use local `amsmath` controls such as `\displaybreak` rather than leaving accidental breaks, split overlong rows when needed, and correct layouts that leave excessive whitespace. Recompile and visually verify the affected pages before reporting the build complete.
- For compile or editor-style issues, prefer texlab diagnostics, LaTeX Workshop output, and narrow source edits before making broader changes. Make narrow source edits that address the reported line, label, macro, or environment.
- When a LaTeX build is needed and VS Code LaTeX Workshop tooling is available, trigger the build through LaTeX Workshop rather than invoking a raw LaTeX command directly.
- Use LaTeX Workshop build commands as the default build path for this workspace so the PDF viewer open in VS Code refreshes. Prefer the extension's build/build-and-view workflow over shell commands such as `lualatex`, `pdflatex`, or `latexmk`. Use raw shell compilation only when LaTeX Workshop is unavailable, when a non-view diagnostic compile is explicitly needed, or when the user explicitly asks for it; in that case, direct all outputs into `build/` (for example `latexmk -outdir=build main.tex`), say that the open PDF may not refresh, and leave no build artifacts at the repository root.
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
