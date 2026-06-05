# AGENTS.md

## Manuscript source of truth

- Treat `main.tex` as the canonical root of the manuscript. Start from `main.tex`, follow its `\\input`, `\\include`, bibliography, macro, and package declarations, and interpret all included TeX in that root context.
- When answering questions about the paper, prefer exact evidence from `main.tex` and included TeX files over memory, generated PDFs, auxiliary files, notes, or ingested reference chunks.
- Cite source locations as `file:line` whenever making claims about manuscript text, notation, assumptions, derivations, equation labels, or references.
- Do not infer global notation from isolated snippets. Resolve definitions, labels, counters, macros, and theorem/equation environments through the `main.tex` compilation graph.

## Precision LaTeX parsing and reading

- Act as a precision LaTeX parser and reader, not a loose text searcher. Preserve TeX semantics, macro expansion context, math-mode boundaries, environment nesting, labels, refs, citations, and local definitions.
- Before changing equations, labels, notation, cross-references, theorem statements, or bibliography usage, inspect the surrounding TeX source and the relevant definitions/macros.
- Use focused equation and symbol tools when possible (`mech_focus_equation`, `mech_search_symbol`, `mech_check`) rather than broad rewrites.
- Distinguish manuscript source from generated artifacts. LaTeX build products such as `.aux`, `.log`, `.out`, `.bbl`, `.fls`, `.fdb_latexmk`, and PDFs are not authoritative except for diagnostics or rendered-number lookup.

## texlab / LSP awareness

- The TeX language server `texlab` is available. Use `mech_lsp` for diagnostics, definitions, references, document symbols, hovers, renames, and code actions when precise LaTeX navigation or validation is needed.
- For compile or editor-style issues, prefer `mech_compile` and `mech_lsp` diagnostics before making edits. Make narrow source edits that address the reported line, label, macro, or environment.
- If aux data or equation numbering is stale, refresh the paper map or compile from `main.tex` before relying on rendered numbers.

## Chat-preview debugging discipline

- When debugging or changing `chat-preview-pi`, first read and follow `/home/john/Documents/pi-extensions/packages/chat-preview-pi/DESIGN.md`.
- Conform to the chat-preview design contract: preserve the minimal dark interface, avoid broad layout/theme rewrites without explicit approval, prefer additive/narrow changes, keep frontend/backend APIs explicit, and keep runtime/generated state out of git.
- Before confirming any chat-preview fix, use browser-control tools to open the running preview when available, reproduce or inspect the issue, and verify the changed behavior. If no preview server is running or browser verification is impossible, state that explicitly and do not present the change as browser-verified.
- For visual or interaction changes, capture or describe before/after behavior and test through the browser UI, not only TypeScript compilation.

<!-- MECHPI_INGEST_GUIDANCE_START -->
## Mech-pi ingest retrieval

When `.mechpi/ingest/vector-store.json` exists, treat it as the first-pass text-embedding retrieval cache for questions about ingested references, background papers, and remembered phrases.

- Use the `mech_retrieve` tool for targeted retrieval from `.mechpi/ingest/vector-store.json` instead of reading or sending the whole vector store.
- Do not run broad filesystem searches just to duplicate vector-store retrieval. If retrieval is insufficient, inspect `.mechpi/ingest/manifest.json`, `.mechpi/ingest/text/`, or source files to verify exact quotations/line numbers before wider `find`/`rg` searches.
- If `MECH-PI INGESTED REFERENCE CONTEXT` is present, it is auto-retrieved context; use it first when sufficient.
- For manuscript mechanics claims, the TeX source and `.mechpi/paper-map.json` still override retrieved reference chunks.
<!-- MECHPI_INGEST_GUIDANCE_END -->
