#!/usr/bin/env bash
# Builds dist/hatchlock-openai.zip: the skills-only package for the OpenAI
# plugin directory, which rejects hooks and does not support LSP servers.
set -euo pipefail
cd "$(dirname "$0")/.."

for f in assets/icon.png assets/logo.png; do
  [[ -f "$f" ]] || { echo "missing $f (square PNG, at least 48x48; 512+ recommended)" >&2; exit 1; }
done

OUT=dist/hatchlock-openai.zip
mkdir -p dist && rm -f "$OUT"
# doctor runs a bundled shell script, so it stays Claude Code only.
zip -qr "$OUT" .codex-plugin assets README.md LICENSE PRIVACY.md \
  skills/tight-diff skills/optimize skills/architect skills/clean
echo "$OUT"
