---
name: tight-diff
description: Keeps every code change minimal, verified against the language server and compiler, and free of type-checker escape hatches. Use whenever writing, editing, refactoring, debugging, or reviewing code in any language.
when_to_use: When implementing features, fixing bugs, refactoring, editing files, or reviewing diffs, or when the user says "keep it simple", "no bloat", "tight diff", or "surgical edit".
argument-hint: "[optional-target-file-or-task]"
effort: high
---

# Tight Diff: Minimal, Compiler-Verified Changes

Hard rule first: **never silence the type checker.** New `@ts-ignore`, `@ts-expect-error`, `@ts-nocheck`, `as any`, `: any`, `# type: ignore`, `# pyright: ignore`, `@phpstan-ignore`, `#[allow(dead_code)]`, and `//nolint` must never be added (HatchLock's hooks block them before the write lands). Fix the type. If suppression is truly unavoidable (e.g. a test asserting a type error), put `hatchlock-allow: <reason>` on the same line.

If `$ARGUMENTS` is provided, focus strictly on: **$ARGUMENTS**.

## 1. Think Before Coding
1. State assumptions about input shapes, nullability, concurrency, environment, and failure modes.
2. If a requirement has two distinct interpretations, list both briefly and ask before writing code in the wrong direction.
3. If the request implies an overbuilt pattern (plugin factory, event bus for a local call), propose the direct alternative first.

## 2. Simplicity First
1. Write the smallest, flattest code that solves the stated problem. Nothing speculative.
2. **Rule of Three:** no helper, base class, trait, generic wrapper, or hook for logic used in fewer than 3 places.
3. Before saving, audit the diff: if it could be expressed in a quarter of the lines without losing clarity or type safety, rewrite it.
4. Guard clauses and early `return` / `continue`; maximum indentation depth 2; no `else` after a branch that returns or throws.
5. Never add a dependency when the standard library or an existing workspace dependency suffices.

## 3. Surgical Changes, Verified by the Language Server
1. Use `Grep`/`Glob` only to find entry files. Before modifying a function, type, or interface, use the LSP tool (go to definition, hover) to read its resolved signature.
2. Before changing an exported symbol's parameters, visibility, or return type, find all references and update every caller in the same change.
3. Touch only the lines the task needs. Do not reformat, reorder imports, rename stable names, or add comments that restate code. Remove only what your own change made dead.

## 4. Goal-Driven Execution
1. Name the verification first: the compiler check, typecheck, or failing test that proves the change.
2. Where HatchLock's hooks are installed, they enforce this in three stages (elsewhere, run the equivalent compiler or typecheck yourself after each change):
   - **Before each write:** escape hatches are blocked (`[HatchLock Guardrail]`).
   - **After each edit:** a fast per-file syntax/type check (`[HatchLock Compiler Loop]`).
   - **End of turn:** whole-project compilers for changed languages (`[HatchLock Project Check]`).
3. When any of these report errors, stop feature work and fix the root cause before touching other files.
