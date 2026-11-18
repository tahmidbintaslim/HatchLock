---
name: doctor
description: >-
  Audits the language servers and compilers HatchLock can use for the languages in the current project, and lists the official LSP plugins to install. Pass --all for every supported language. Use when the user runs /hatchlock:doctor, asks which language servers are installed, or troubleshoots LSP attachment in Claude Code.
license: MIT
metadata:
  argument-hint: "[--all]"
---
# HatchLock Toolchain Doctor

Run the diagnostic script that ships with the HatchLock plugin, from the project folder, and show its output to the user unchanged. Add `--all` if the user asked to see every language.

- Claude Code and GitHub Copilot: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/lsp-doctor.sh" $ARGUMENTS`
- Grok Build: `bash "$GROK_PLUGIN_ROOT/scripts/lsp-doctor.sh"`
- Anywhere else: run `scripts/lsp-doctor.sh` from the HatchLock plugin folder, or call the `doctor` tool of the `hatchlock` MCP server if it is connected.

After showing the table, ask if the user wants help installing the LSP binary for their current project's primary language.
