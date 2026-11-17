#!/usr/bin/env bash
# Builds dist/antigravity/hatchlock: the Google Antigravity plugin layout
# (root plugin.json + hooks.json), kept out of the repo root so it can't
# collide with the Claude/Copilot layout. Prints the package path.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=dist/antigravity/hatchlock
rm -rf "$OUT" && mkdir -p "$OUT/scripts" "$OUT/assets"
cp -R skills "$OUT/"
cp scripts/antigravity-hook.sh scripts/guard-escape-hatches.sh scripts/verify-project.sh scripts/lang.sh scripts/lsp-doctor.sh "$OUT/scripts/"
cp assets/logo.png "$OUT/assets/logo.png"
cp README.md LICENSE PRIVACY.md "$OUT/"
VERSION=$(jq -r .version .claude-plugin/plugin.json)
jq -n --arg v "$VERSION" '{
  "$schema": "https://antigravity.google/schemas/v1/plugin.json",
  name: "hatchlock", displayName: "HatchLock", version: $v,
  description: "Blocks type-checker escape hatches (@ts-ignore, as any, # type: ignore) before they are written and checks the project with your own compilers.",
  logo: "assets/logo.png",
  suggestedPrompts: ["Fix the type errors in src/billing.ts without using any or @ts-ignore.", "Optimize the /orders endpoint, it runs one query per line item.", "Clean up lib/report_builder.py without changing its behaviour."],
  author: {name: "Tahmid Bin Taslim Rafi", url: "https://github.com/tahmidbintaslim"},
  homepage: "https://tahmidbintaslim.github.io/HatchLock/",
  repository: "https://github.com/tahmidbintaslim/HatchLock",
  license: "MIT",
  keywords: ["hatchlock", "type-safety"]
}' > "$OUT/plugin.json"
cat > "$OUT/hooks.json" <<'JSON'
{
  "hatchlock": {
    "enabled": true,
    "PreToolUse": [
      {
        "matcher": "write_to_file|replace_file_content|multi_replace_file_content",
        "hooks": [{ "type": "command", "command": "./scripts/antigravity-hook.sh pre", "timeout": 10 }]
      }
    ],
    "Stop": [{ "type": "command", "command": "./scripts/antigravity-hook.sh stop", "timeout": 300 }]
  }
}
JSON
echo "$OUT"
