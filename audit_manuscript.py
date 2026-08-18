import glob
import re
import sys

canonical_files = ['main.tex', 'defs.tex'] + sorted(glob.glob('sections/*.tex'))

# Regexes
label_re = re.compile(r'\\label\{([^}]+)\}')
ref_re = re.compile(r'\\(ref|eqref|eref|Cref|cref|pageref)\{([^}]+)\}')

# Math environments to count: displayed math
# \begin{equation}, \begin{equation*}, \begin{align}, \begin{align*}, \begin{gather}, \begin{gather*}, \begin{multline}, \begin{multline*}, \begin{flalign}, \begin{flalign*}, \begin{split}, etc.
# Also let's check for $$...$$ and \[...\]
math_env_re = re.compile(r'\\begin\{(equation|align|gather|multline|flalign|split|displaymath)\*?\}')

labels = {} # name -> (file, line_num)
all_refs = {} # name -> list of (file, line_num, ref_type)
duplicate_labels = []
equation_labels_count = 0
displayed_math_count = 0

# Also check for \[...\] and $$
# We will do line-by-line and block scans if needed, but simple regex matches are fine.

for path in canonical_files:
    with open(path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    # Simple search
    for idx, line in enumerate(lines):
        line_num = idx + 1
        # Strip comments
        # A simple TeX comment stripper (ignores \% but strips from % to end of line)
        cleaned_line = ''
        escaped = False
        for char in line:
            if escaped:
                cleaned_line += char
                escaped = False
            elif char == '\\':
                cleaned_line += char
                escaped = True
            elif char == '%':
                break
            else:
                cleaned_line += char

        # Check label
        for m in label_re.finditer(cleaned_line):
            lbl = m.group(1).strip()
            if lbl in labels:
                duplicate_labels.append((lbl, labels[lbl], (path, line_num)))
            else:
                labels[lbl] = (path, line_num)

            if lbl.startswith('eq:') or 'eq' in lbl.split(':'):
                equation_labels_count += 1

        # Check refs
        for m in ref_re.finditer(cleaned_line):
            ref_type = m.group(1)
            refs_str = m.group(2)
            # Refs can be comma separated in some packages, let's split just in case, but usually simple
            for r in refs_str.split(','):
                r = r.strip()
                if r not in all_refs:
                    all_refs[r] = []
                all_refs[r].append((path, line_num, ref_type))

        # Check display math env starts
        for m in math_env_re.finditer(cleaned_line):
            displayed_math_count += 1

        # Count \[
        displayed_math_count += cleaned_line.count('\\[')
        # Count $$
        displayed_math_count += cleaned_line.count('$$')

print("--- AUDIT REPORT ---")
print(f"Total Canonical Files Searched: {len(canonical_files)}")
print(f"Total Labels Found: {len(labels)}")
print(f"Total Unique References Target Found: {len(all_refs)}")
print(f"Total Displayed Math Environments Counted: {displayed_math_count}")
print(f"Total Equation-like Labels Found: {equation_labels_count}")

print("\n--- DUPLICATE LABELS ---")
if duplicate_labels:
    for lbl, orig, dup in duplicate_labels:
        print(f"Duplicate label '{lbl}':")
        print(f"  First: {orig[0]}:{orig[1]}")
        print(f"  Second: {dup[0]}:{dup[1]}")
else:
    print("None")

print("\n--- UNDEFINED TARGETS (References to non-existent labels) ---")
undefined = {}
for ref, instances in all_refs.items():
    if ref not in labels:
        undefined[ref] = instances

if undefined:
    for ref, instances in sorted(undefined.items()):
        print(f"Undefined target '{ref}':")
        for inst in instances:
            print(f"  Referenced from {inst[0]}:{inst[1]} via \\{inst[2]}")
else:
    print("None")

print("\n--- UNREFERENCED LABELS (Declared but not referred) ---")
unreferenced = []
for lbl, loc in labels.items():
    if lbl not in all_refs:
        unreferenced.append((lbl, loc))

if unreferenced:
    for lbl, loc in sorted(unreferenced, key=lambda x: (x[1][0], x[1][1])):
        print(f"Unreferenced label '{lbl}' at {loc[0]}:{loc[1]}")
else:
    print("None")

print("\n--- INEXPENSIVE SYNTAX / STATIC CHECK ---")
# Let's check matching braces/brackets or common LaTeX typos programmatically since chktex/lacheck are missing
bracket_mismatches = []
for path in canonical_files:
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    # Strip comments from complete content
    lines = content.splitlines()
    cleaned_content = []
    for line in lines:
        cleaned_line = ''
        escaped = False
        for char in line:
            if escaped:
                cleaned_line += char
                escaped = False
            elif char == '\\':
                cleaned_line += char
                escaped = True
            elif char == '%':
                break
            else:
                cleaned_line += char
        cleaned_content.append(cleaned_line)

    full_text = '\n'.join(cleaned_content)

    # Check braces mismatch
    braces = []
    brackets = []
    for pos, char in enumerate(full_text):
        if char == '{':
            braces.append(pos)
        elif char == '}':
            if braces:
                braces.pop()
            else:
                # print unmatched
                pass # a bit complex to map to exact line without helper, let's keep it simple

    # Simple common errors:
    # 1. Unescaped & outside table/align (hard to do without parser)
    # 2. Multiple spaces / bad spacing before punctuations (e.g., " .", " ,")
    bad_punc_re = re.compile(r'\s+([.,;:\!?])')
    for idx, line in enumerate(cleaned_content):
        for m in bad_punc_re.finditer(line):
            # Exclude things like "..." or math mode
            # Just report potential ones
            punc = m.group(1)
            # very simple check
            if punc in ['.', ','] and not line[m.start():].startswith('...'):
                bracket_mismatches.append((path, idx+1, f"Spacing before punctuation '{punc}'"))

if bracket_mismatches:
    print(f"Potential syntax/style warnings found: {len(bracket_mismatches)}")
    for bm in bracket_mismatches[:20]:
        print(f"  {bm[0]}:{bm[1]} - {bm[2]}")
    if len(bracket_mismatches) > 20:
        print(f"  ... and {len(bracket_mismatches)-20} more.")
else:
    print("No basic structural/spacing issues found.")
