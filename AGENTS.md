# AGENTS.md

## Manuscript source of truth

- Read `VISION.md` at the start of manuscript work and use it as the high-level guide for the paper's purpose, comparisons, and special-case derivations.
- Treat `main.tex` as the canonical root of the manuscript. Start from `main.tex`, follow its `\\input`, `\\include`, bibliography, macro, and package declarations, and interpret all included TeX in that root context.
- Manuscript body files are organized under `sections/`, but they are not standalone documents. Interpret them only through the `main.tex` root context.
- Store intentional research PDFs in `references/pdfs/` and human reading notes in `references/notes/`. Use the `latex-research-ingest` skill's local `.codex-research/` store for PDF ingestion and retrieval. Treat generated LaTeX, preview, and retrieval state as non-authoritative workflow artifacts.
- When answering questions about the paper, prefer exact evidence from `main.tex` and included TeX files over memory, generated PDFs, auxiliary files, notes, or ingested reference chunks.
- Cite source locations as `file:line` whenever making claims about manuscript text, notation, assumptions, derivations, equation labels, or references.
- Do not infer global notation from isolated snippets. Resolve definitions, labels, counters, macros, and theorem/equation environments through the `main.tex` compilation graph.

## Operating checklist for manuscript tasks

- At the start of every manuscript task, read `AGENTS.md`, `VISION.md`, `main.tex`, and `defs.tex` before interpreting section-local notation.
- If the user cites a rendered equation number, resolve it through the active build artifacts before answering or editing. Prefer `build/main.aux` when the build directory is active.
- Before answering conceptual questions, identify the exact source equations, definitions, and assumptions that control the question, and cite them as `file:line`.
- When a notation change affects a derivation, propagate it through state sets, chain-rule terms, thermodynamic forces, restrictions, and downstream prose instead of patching only the visible equation.
- Separate kinematic fields from constitutive arguments before renaming symbols. Do not replace every occurrence of a symbol merely because one role changed.
- When the user narrows an edit to a section, subsection, equation, or paragraph, keep edits strictly inside that scope unless the user explicitly expands it.
- If adding a helper identity only for clarity, prefer an unnumbered display unless the identity is intended to be referenced later.
- For citation or external-paper equation claims, verify the cited equation in the source PDF before changing manuscript text.

## Response modes

- For interpretive questions, answer from the manuscript source first, then explain the mathematical implication. Avoid importing outside theory unless the manuscript source or user request calls for it.
- For edit requests, make the smallest source change that fixes the issue, then validate affected labels, references, and display math.
- For derivation audits, report whether the current source supports the claim, what assumptions would be needed if it does not, and where the downstream equations would change.

## Precision LaTeX parsing and reading

- Act as a precision LaTeX parser and reader, not a loose text searcher. Preserve TeX semantics, macro expansion context, math-mode boundaries, environment nesting, labels, refs, citations, and local definitions.
- Always inspect `defs.tex` when interpreting notation or shorthand the user writes in chat, since chat shorthand may refer to manuscript macros or local notation conventions.
- When discussing mathematical notation with the user, show displayed/rendered LaTeX by default. Provide raw TeX source only when the user explicitly asks for code or when an edit/diff requires source-level precision. Since chat renderers do not automatically load project-local macros from `defs.tex`, expand shorthand such as `\mc`, `\mbf`, `\bs`, and `\p` to standard LaTeX in displayed chat math unless you also provide the macro definitions in that response.
- Before changing equations, labels, notation, cross-references, theorem statements, or bibliography usage, inspect the surrounding TeX source and the relevant definitions/macros.
- Prefer reusing existing notation and writing short expressions inline over introducing new named symbols. This manuscript already has many symbols, so introduce a new symbol only when it materially improves clarity, reduces repeated complexity, or is needed for a standard term.
- Do not introduce new derived variables, helper tensors, residuals, rate symbols, force maps, or shorthand symbols such as `L`, `R`, `Q`, `C`, or similar unless you first ask the user and receive explicit approval. When revising entropy inequalities or Coleman--Noll collections, write the terms directly in the primitive manuscript variables instead of introducing helper notation.
- For mechanism-indexed quantities, use parenthesized subscripts on the variables, such as `\dot r_{(m)}`, `\nu_{\xi (m)}^\alpha`, and `\mc A_{(m)}`. Do not parenthesize the dummy summation index under the summation sign: write `\sum_m`, not `\sum_{(m)}`.
- Do not write numbered display equations as chained multiple-equals expressions on one line. When a result needs multiple equality steps, use an `align` environment and align the equals signs vertically so each step is visually and mathematically clear.
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
