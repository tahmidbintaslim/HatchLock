---
name: doctor
description: Audits the language servers and compilers HatchLock can use for the languages in the current project, and lists the official LSP plugins to install. Pass --all for every supported language.
when_to_use: When the user runs /hatchlock:doctor, asks which language servers are installed, or troubleshoots LSP attachment in Claude Code.
argument-hint: "[--all]"
effort: low
---

# HatchLock Toolchain Doctor

Run the bundled diagnostic script and display its output verbatim to the user:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/lsp-doctor.sh" $ARGUMENTS
```

After showing the table, ask if the user wants help installing the LSP binary for their current project's primary language.
