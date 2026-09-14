# Repository-wide default: write every LaTeX build product under ./build/
# (relative to the directory latexmk is invoked from). This keeps the
# repository root clean whether latexmk is run by an agent, from the command
# line, or through LaTeX Workshop (which additionally passes -outdir=<abs>/build
# via .vscode/settings.json).
$out_dir = 'build';
