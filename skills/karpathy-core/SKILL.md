---
name: karpathy-core
description: Enforces Andrej Karpathy's four coding principles, mandatory 18-language LSP symbol verification, and deterministic compiler loop compliance. Use automatically whenever writing, editing, refactoring, debugging, or reviewing code in any programming language.
when_to_use: When implementing features, fixing bugs, refactoring modules, editing files, reviewing diffs, or when the user says "karpathy check", "keep it simple", "no bloat", or "surgical edit".
argument-hint: "[optional-target-file-or-task]"
effort: high
---

# Polyglot Karpathy Core: Minimalist & Compiler-Verified Engineering

Apply these four governing principles and mechanical LSP guardrails to every code task. If `$ARGUMENTS` is provided, focus execution strictly on: **$ARGUMENTS**.

## Principle 1: Think Before Coding (Zero Silent Assumptions)
1. **Surface Assumptions Explicitly:** State what you are assuming about input shapes, nullability, concurrency, environment variables, and failure modes.
2. **Expose Ambiguity Early:** If a requirement has two distinct technical interpretations, list both in 2-3 bullet points and ask before writing 200 lines in the wrong direction.
3. **Push Back Toward Simplicity:** If the prompt asks for an overcomplicated pattern (e.g., a generic plugin factory or event bus for a synchronous local call), propose the direct 20-line alternative first.

## Principle 2: Simplicity First (The 200-to-50 Line Rule)
1. **Minimum Viable Surface Area:** Write the smallest, flattest code that solves the exact stated problem. Nothing speculative.
2. **The Rule of Three (Zero Premature Abstraction):** Never extract a helper function, base class, trait, generic wrapper, or custom hook for logic used in fewer than 3 concrete places. Inline single-use logic where it runs.
3. **The 200-to-50 Line Self-Test:** Before saving a file, audit the diff. If you wrote 200 lines and it could be expressed cleanly in 50 lines without losing clarity or type safety, rewrite it.
4. **Flat Control Flow:** Use guard clauses and early `return` / `continue` statements at the top of functions. Keep maximum indentation depth to 2 levels. Never write an `else` block immediately after an `if` that returns or throws.
5. **Strict Dependency Lock:** Never add a new package to `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `composer.json`, or `Gemfile` when standard library APIs or existing workspace dependencies suffice.

## Principle 3: Surgical Changes + Mandatory LSP Graph Verification
1. **LSP Symbol Traversal Over Blind Grep:**
   - Use `Grep` and `Glob` strictly to locate initial entry files.
   - Before modifying any function, struct, class, or interface, run LSP `goToDefinition` and `hover` to inspect its exact resolved type signature.
   - Before changing any exported symbol's parameters, visibility, or return type, run LSP `findReferences` across the workspace and update every caller in the same atomic sequence.
2. **Surgical Diffs Only:**
   - Touch ONLY the lines required to fulfill the task.
   - Do NOT reformat untouched functions, reorder unrelated imports, rename stable variables, or add noisy comments that restate the code.
   - Clean up unused imports, dead variables, or orphaned helpers ONLY if your own changes made them obsolete.

## Principle 4: Goal-Driven Execution & Self-Healing Compiler Loop
1. **Define the Verification Gate First:** Before editing, specify the exact compiler check, typecheck, or failing test case that proves the change works.
2. **Honor the `PostToolUse` Compiler Loop (Exit Code 2):**
   - Every `Write`, `Edit`, and `MultiEdit` operation automatically runs `scripts/verify-edit.sh` against the active language toolchain.
   - If the hook returns `[Polyglot Compiler Loop]` or `[Polyglot Guardrail]` errors on `stderr`, halt feature generation immediately and fix the underlying root cause before touching any other file.
3. **Zero Escape Hatches (Strictly Blocked):**
   - Never silence the compiler or typechecker with `@ts-ignore`, `@ts-expect-error`, `as any`, `: any`, `# type: ignore`, `@phpstan-ignore`, `#[allow(dead_code)]`, or `// nolint`.
