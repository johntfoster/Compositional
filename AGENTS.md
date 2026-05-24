# AGENTS.md

<!-- MECHPI_INGEST_GUIDANCE_START -->
## Mech-pi ingest retrieval

When `.mechpi/ingest/vector-store.json` exists, treat it as the first-pass text-embedding retrieval cache for questions about ingested references, background papers, and remembered phrases.

- Use the `mech_retrieve` tool for targeted retrieval from `.mechpi/ingest/vector-store.json` instead of reading or sending the whole vector store.
- Do not run broad filesystem searches just to duplicate vector-store retrieval. If retrieval is insufficient, inspect `.mechpi/ingest/manifest.json`, `.mechpi/ingest/text/`, or source files to verify exact quotations/line numbers before wider `find`/`rg` searches.
- If `MECH-PI INGESTED REFERENCE CONTEXT` is present, it is auto-retrieved context; use it first when sufficient.
- For manuscript mechanics claims, the TeX source and `.mechpi/paper-map.json` still override retrieved reference chunks.
<!-- MECHPI_INGEST_GUIDANCE_END -->
