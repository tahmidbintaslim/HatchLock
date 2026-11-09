---
name: doctor
description: Audits the 6 bundled LSP servers and the compilers used by the edit checks, and lists the official LSP plugins for other languages.
when_to_use: When the user runs /hatchlock:doctor, asks which language servers are installed, or troubleshoots LSP attachment in Claude Code.
effort: low
---

# HatchLock Toolchain Doctor

Run the bundled diagnostic script and display its output verbatim to the user:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/lsp-doctor.sh"
```

After showing the table, ask if the user wants help installing the LSP binary for their current project's primary language.
