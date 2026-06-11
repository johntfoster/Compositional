# AGENTS.md

## Manuscript source of truth

- Treat `main.tex` as the canonical root of the manuscript. Start from `main.tex`, follow its `\\input`, `\\include`, bibliography, macro, and package declarations, and interpret all included TeX in that root context.
- When answering questions about the paper, prefer exact evidence from `main.tex` and included TeX files over memory, generated PDFs, auxiliary files, notes, or ingested reference chunks.
- Cite source locations as `file:line` whenever making claims about manuscript text, notation, assumptions, derivations, equation labels, or references.
- Do not infer global notation from isolated snippets. Resolve definitions, labels, counters, macros, and theorem/equation environments through the `main.tex` compilation graph.

## Precision LaTeX parsing and reading

- Act as a precision LaTeX parser and reader, not a loose text searcher. Preserve TeX semantics, macro expansion context, math-mode boundaries, environment nesting, labels, refs, citations, and local definitions.
- Before changing equations, labels, notation, cross-references, theorem statements, or bibliography usage, inspect the surrounding TeX source and the relevant definitions/macros.
- Use chat-preview as the central interactive interface for navigating, previewing, selecting, editing, and discussing manuscript TeX. Prefer chat-preview browser workflows for equation/citation/file inspection when available, while still treating `main.tex` and included source files as authoritative.
- Use focused equation, citation, file-editor, preview, and browser-side selectors exposed through chat-preview before falling back to older mech-pi-specific workflows or broad filesystem rewrites.
- Distinguish manuscript source from generated artifacts. LaTeX build products such as `.aux`, `.log`, `.out`, `.bbl`, `.fls`, `.fdb_latexmk`, and PDFs are not authoritative except for diagnostics or rendered-number lookup.

## texlab / LSP awareness

- The TeX language server `texlab` is available. Use chat-preview/latex-edit integrations or direct LSP diagnostics, definitions, references, document symbols, hovers, renames, and code actions when precise LaTeX navigation or validation is needed.
- For compile or editor-style issues, prefer chat-preview-driven diagnostics/preview and narrow source edits before making broader changes. Make narrow source edits that address the reported line, label, macro, or environment.
- If aux data or equation numbering is stale, compile from `main.tex` or refresh the relevant preview/index before relying on rendered numbers.

## Chat-preview as the central manuscript interface

- Use `chat-preview-pi` as the primary interface to this repository's TeX workflow: chat, prompt editing, equation browsing/editing, citation/BibTeX inspection, PDF/source preview, file editing, and RAG ingestion should be driven from chat-preview when available.
- When debugging or changing `chat-preview-pi`, first read and follow `/home/john/Documents/pi-extensions/packages/chat-preview-pi/DESIGN.md`.
- Conform to the chat-preview design contract: preserve the minimal dark interface, avoid broad layout/theme rewrites without explicit approval, prefer additive/narrow changes, keep frontend/backend APIs explicit, and keep runtime/generated state out of git.
- Before confirming any chat-preview fix, use browser-control tools to open the running preview when available, reproduce or inspect the issue, and verify the changed behavior. If no preview server is running or browser verification is impossible, state that explicitly and do not present the change as browser-verified.
- For visual or interaction changes, capture or describe before/after behavior and test through the browser UI, not only TypeScript compilation.
- Treat mech-pi as a legacy/supplemental toolkit for this project. Do not center new manuscript workflows, guidance, or UI expectations around mech-pi unless the user explicitly asks for mech-pi behavior.

<!-- RAGPI_INGEST_GUIDANCE_START -->
## Chat-preview / rag-pi retrieval

When `.ragpi/vector-store.json` exists, treat it as the first-pass retrieval cache for ingested references, background papers, and remembered phrases.

- Use chat-preview `/ingest` for selecting, rectifying, adding/removing, and rebuilding repo-local RAG sources whenever possible.
- Use `rag_retrieve` for targeted retrieval from `.ragpi/vector-store.json` instead of reading or sending the whole vector store.
- Do not run broad filesystem searches just to duplicate vector-store retrieval. If retrieval is insufficient, inspect `.ragpi/manifest.json`, `.ragpi/text/`, or source files to verify exact quotations/line numbers before wider searches.
- If `RAG-PI AUTO-RETRIEVED CONTEXT` is present, use it first when sufficient.
- For manuscript mechanics claims, the TeX source rooted at `main.tex` still overrides retrieved reference chunks.
<!-- RAGPI_INGEST_GUIDANCE_END -->
