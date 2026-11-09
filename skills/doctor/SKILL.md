---
name: doctor
description: Audits locally installed LSP binaries and compiler toolchains across all 18 supported programming languages and prints 1-line installation commands for missing tools.
when_to_use: When the user runs /polyglot:doctor, asks which language servers are installed, or troubleshoots LSP attachment in Claude Code.
effort: low
---

# Polyglot Toolchain Doctor

Run the bundled diagnostic script and display its output verbatim to the user:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/lsp-doctor.sh"
```

After showing the table, ask if the user wants help installing the LSP binary for their current project's primary language.
