# Rendered Equation Number Lookup

Use this before answering or editing when the user refers to a rendered equation
number, including bare numbers in manuscript context.

## Source Priority

1. Prefer `build/main.aux` when it exists.
2. If aux data may be stale, refresh through LaTeX Workshop from `main.tex`
   before relying on rendered numbers. Builds must write into `build/`; a root
   `main.aux` should never exist because agent-invoked builds direct all
   outputs into `build/`.

## Lookup Procedure

1. Resolve the rendered number to a label and source line.
2. Open the source span around the label.
3. Confirm the surrounding environment and any locked-region markers.
4. If editing, inspect nearby references to the label before patching.
5. If the lookup conflicts across aux files, report the conflict and trust the
   active build directory unless a fresh build proves otherwise.

## Helper

The existing resolver can be used from the repository root:

```bash
python3 agent_environment/skills/takeme/scripts/takeme_resolve.py --repo . --target "<number>"
```

## Failure Modes

- Stale aux files in the repository root map a number to the wrong label; keep
  all build products under `build/`.
- A first build pass can shift equation numbers; compile twice when label
  validation matters.
- Raw shell builds may validate source without refreshing the open VS Code PDF
  preview.
