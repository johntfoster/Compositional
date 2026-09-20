#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
mkdir -p .agent-runtime
exec > >(tee .agent-runtime/codespace-setup.log) 2>&1
git submodule sync --recursive
git submodule update --init --recursive
tools/agentctl hooks install
git config --local research.manuscriptFreeze true
tools/agentctl check
python3 .agent/shared/tools/research_project.py check
printf '\nInfrastructure ready. Manuscript generation and scientific setup were not run.\n'
