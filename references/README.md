# Research Context Workflow

Use this directory for source papers and durable research notes that support the
manuscript.

## Add PDFs

1. Put original PDFs in `references/pdfs/`.
2. Use stable filenames:

   ```text
   author-year-short-title.pdf
   ```

3. Add or update the corresponding BibTeX entry in `all.bib` when the paper will
   be cited.
4. Provision the research profile on first use, then ingest the PDF:

   ```bash
   tools/agentctl provision research
   tools/run_python_profile.py research agent_environment/skills/latex-research-ingest/scripts/research_store.py ingest . references/pdfs/*.pdf
   ```

5. Keep generated retrieval files in `.agent-runtime/research/`; they are local cache
   state and are ignored by git.

## Use Ingested PDFs

Ask research questions against the ingested context, but verify precise claims
against the source PDF, extracted text, or a note before changing the manuscript.

Retrieve local context with:

```bash
tools/run_python_profile.py research agent_environment/skills/latex-research-ingest/scripts/research_store.py retrieve . "intrinsic density"
```

Good prompts:

```text
Using the ingested PDFs, compare our intrinsic density definition with Bedford
and Drumheller. Cite manuscript lines and reference evidence separately.
```

```text
Find where the ingested literature discusses phase transformations, then suggest
where this manuscript needs a citation.
```

## Write Notes

Use `references/notes/` for compact reading notes and derivation checks. Notes
are human-readable synthesis; they do not replace the original PDFs.

Start from `references/notes/TEMPLATE.md` for papers that matter to the article.
