---
name: clean
description: De-bloats spaghetti code, collapses speculative abstractions, flattens nested conditionals, and removes dead code while preserving exact behavior and types.
when_to_use: When the user asks to clean up code, simplify a file, remove bloat, flatten nested if/else blocks, review a PR for code quality, or runs /polyglot:clean.
argument-hint: "[file-path-or-module]"
effort: medium
---

# Polyglot Clean: Anti-Bloat Refactoring Engine

Target scope: **$ARGUMENTS**

1. **Inline Premature Abstractions (Rule of Three):** Identify helper functions, wrapper classes, factories, or interfaces used in fewer than 3 concrete call sites (verify via LSP `findReferences`) and inline them directly into their caller.
2. **Flatten Control Flow (Max Depth 2):** Convert arrow-code (`if { if { if } }`) into top-of-function guard clauses with early `return` or `continue`. Remove `else` blocks following branches that return or throw.
3. **Purge Redundant Internal Defenses:** Remove duplicate `typeof`, `!== null`, or fallback checks inside internal functions where the LSP type signature already guarantees a non-null type.
4. **Dead Code Elimination:** Use LSP `findReferences` to identify unreferenced private functions, unused imports, and dead feature flags, and remove them cleanly.
5. **Verify Zero Behavioral Drift:** Ensure every refactor passes `scripts/verify-edit.sh` and existing tests with zero type changes to public exports.
