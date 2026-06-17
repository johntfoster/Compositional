# AGENTS.md

## Manuscript source of truth

- Read `VISION.md` at the start of manuscript work and use it as the high-level guide for the paper's purpose, comparisons, and special-case derivations.
- Treat `main.tex` as the canonical root of the manuscript. Start from `main.tex`, follow its `\\input`, `\\include`, bibliography, macro, and package declarations, and interpret all included TeX in that root context.
- Manuscript body files are organized under `sections/`, but they are not standalone documents. Interpret them only through the `main.tex` root context.
- Store intentional research PDFs in `references/pdfs/` and human reading notes in `references/notes/`. Use the `latex-research-ingest` skill's local `.codex-research/` store for PDF ingestion and retrieval. Treat generated LaTeX, preview, and retrieval state as non-authoritative workflow artifacts.
- When answering questions about the paper, prefer exact evidence from `main.tex` and included TeX files over memory, generated PDFs, auxiliary files, notes, or ingested reference chunks.
- Cite source locations as `file:line` whenever making claims about manuscript text, notation, assumptions, derivations, equation labels, or references.
- Do not infer global notation from isolated snippets. Resolve definitions, labels, counters, macros, and theorem/equation environments through the `main.tex` compilation graph.

## Precision LaTeX parsing and reading

- Act as a precision LaTeX parser and reader, not a loose text searcher. Preserve TeX semantics, macro expansion context, math-mode boundaries, environment nesting, labels, refs, citations, and local definitions.
- Always inspect `defs.tex` when interpreting notation or shorthand the user writes in chat, since chat shorthand may refer to manuscript macros or local notation conventions.
- When discussing mathematical notation with the user, show displayed/rendered LaTeX by default. Provide raw TeX source only when the user explicitly asks for code or when an edit/diff requires source-level precision. Since chat renderers do not automatically load project-local macros from `defs.tex`, expand shorthand such as `\mc`, `\mbf`, `\bs`, and `\p` to standard LaTeX in displayed chat math unless you also provide the macro definitions in that response.
- Before changing equations, labels, notation, cross-references, theorem statements, or bibliography usage, inspect the surrounding TeX source and the relevant definitions/macros.
- Treat text between `% AGENT-LOCK-BEGIN` and `% AGENT-LOCK-END` as protected manuscript source. Do not edit locked equations or surrounding locked text unless the user explicitly says to unlock them or explicitly names the locked equation as an edit target.
- Prefer source-based LaTeX inspection rooted at `main.tex`, texlab/LSP diagnostics, and local build artifacts for equation/citation/file inspection.
- Use focused equation, citation, and source-file inspection before broad filesystem rewrites.
- Distinguish manuscript source from generated artifacts. LaTeX build products such as `.aux`, `.log`, `.out`, `.bbl`, `.fls`, `.fdb_latexmk`, and PDFs are not authoritative except for diagnostics or rendered-number lookup.

## texlab / LSP awareness

- The TeX language server `texlab` is available. Use direct LSP diagnostics, definitions, references, document symbols, hovers, renames, and code actions when precise LaTeX navigation or validation is needed.
- For compile or editor-style issues, prefer texlab diagnostics, LaTeX Workshop output, and narrow source edits before making broader changes. Make narrow source edits that address the reported line, label, macro, or environment.
- If aux data or equation numbering is stale, compile from `main.tex` or refresh the relevant preview/index before relying on rendered numbers.

## Local research retrieval

Use the `latex-research-ingest` skill for research PDF ingestion and retrieval.
It creates and queries `.codex-research/` without relying on chat-preview,
rag-pi, or `.ragpi/`.

- Prefer `references/pdfs/` for original PDFs and `references/notes/` for durable notes.
- Build/update the local store with `research_store.py ingest`.
- Retrieve targeted context with `research_store.py retrieve`.
- Do not read or send the whole vector store when a targeted retrieval is enough.
- For manuscript mechanics claims, the TeX source rooted at `main.tex` still overrides retrieved reference chunks.
