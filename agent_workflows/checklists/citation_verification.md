# Citation Verification Checklist

Use when a task asks whether a citation is real, whether a cited paper supports
a manuscript claim, whether a BibTeX entry is correct, or whether a claim should
be edited based on an external source.

## Scope

- Identify the manuscript claim, not just the citation key.
- Record the exact source location as `file:line`.
- Classify the claim as background, equation attribution, method comparison,
  historical attribution, empirical result, definition, or related work.
- Keep manuscript edits scoped to the cited sentence or paragraph unless the
  source evidence requires broader correction.

## BibTeX and Metadata

- Locate every cited key in `all.bib`.
- Check for missing or duplicate keys.
- Compare title, authors, year, venue, volume, issue, pages, publisher, and DOI
  against a reliable metadata source.
- Prefer a DOI when available. Normalize DOI formatting to the repository's
  existing BibTeX style.
- Distinguish preprints, conference papers, book chapters, and final published
  articles when their metadata or claims differ.

## Paper Reality Check

- Verify that the cited work exists through DOI metadata, publisher pages,
  arXiv, official proceedings, library records, MathSciNet/ZbMATH, or another
  durable scholarly source.
- Do not treat citation snippets, AI summaries, or secondary web pages as enough
  evidence that the paper supports a technical claim.
- If no reliable metadata source is available, mark the citation as
  `not-verifiable` rather than guessing.

## Claim Support

- Prefer the source PDF or official full text. Use local files under
  `references/pdfs/` when available.
- For equation claims, inspect the cited equation, surrounding definitions, and
  assumptions in the paper.
- For prose claims, inspect the relevant section or paragraph, not only the
  abstract.
- Record page, section, theorem, table, figure, or equation evidence.
- Assign one verdict:
  - `supports` -- the source directly supports the manuscript claim.
  - `partially-supports` -- the source supports a weaker or narrower claim.
  - `related-only` -- the source is relevant but does not support the claim as
    written.
  - `contradicts` -- the source says something materially different.
  - `not-verifiable` -- the source or evidence could not be inspected.

## Required Output

Report citation audits in this compact form:

```text
Claim: <file:line and short paraphrase>
Citation: <key>
Metadata: <pass/fail; DOI or missing DOI>
Evidence: <paper page/section/equation/table, with short paraphrase>
Verdict: <supports|partially-supports|related-only|contradicts|not-verifiable>
Action: <keep|revise claim|fix BibTeX|replace citation|add source|obtain PDF>
```

When editing, update manuscript prose and `all.bib` only after the evidence is
clear. If the evidence is unavailable, preserve the manuscript and report the
verification gap.
