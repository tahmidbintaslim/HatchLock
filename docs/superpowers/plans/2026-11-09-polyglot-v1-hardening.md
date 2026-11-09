# Polyglot v1 Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the scaffolded `polyglot` plugin into a correct, policy-clean, differentiated plugin that installs from the self-hosted marketplace today and can be submitted to the Anthropic plugin directory and community lists.

**Architecture:** Three hook stages replace the single after-the-fact hook: a PreToolUse guard actually *prevents* type-suppression escape hatches; a fast per-file PostToolUse check reports syntax errors; a Stop hook runs the slow whole-project compilers once per turn. `.lsp.json` keeps only the 6 languages Anthropic does not ship official LSP plugins for. The `karpathy-core` skill becomes `tight-diff`, with attribution instead of branding.

**Tech Stack:** Bash 4+, jq, Claude Code ≥ 2.1.289 plugin system (`claude plugin validate`, `claude plugin eval`).

**Spec:** `docs/research/2026-11-09-plugin-publishing-research.md` (research report with sources) plus the user decisions recorded below.

## Decisions (from user, 2026-11-09)

1. Trim `.lsp.json` to the 6 languages with no official Anthropic LSP plugin: Zig, Elixir, Dart, Bash/Shell, Terraform, R.
2. Rename `karpathy-core` → **`tight-diff`** (invoked `/polyglot:tight-diff`). Checked: absent from `claude-plugins-official` (317 plugins) and `claude-plugins-community` (2,283 plugins); no exact match on skills.sh / claudskills.com / web search. Nearby but distinct: `diff-scope-minimizer`, `minimal-diff-implementer`, `surgical-refactoring`.
3. Plugin name `polyglot` stays: absent from both Anthropic catalogs and from web search. Risk: the directory may hold a single generic word for manual review — only the portal's Validate step can confirm.
4. Full analysis & plan first, then execute by scope (below).

## Analysis summary (see research report for sources)

| Area | Finding | Consequence |
|---|---|---|
| Schema | `claude plugin validate . --strict` passes today (v2.1.319). Only directory warning: `ICON_MISSING`. Hook command quoting is fine. | No schema rework needed. |
| Hook semantics | PostToolUse exit 2 only *reports*; the edit already landed. Only PreToolUse exit 2 blocks. | Escape-hatch blocking must move to PreToolUse. |
| Hook timing | Default timeout 600 s; ours is 30 s. Whole-project `tsc`/`cargo check` per edit is slow, overlaps under parallel edits, and fights over Cargo's lock. | Per-file checks after edits; project checks once on Stop. |
| Tools | `MultiEdit` no longer exists; current editors: `Write`, `Edit`, `NotebookEdit`. | Matcher `Write\|Edit`. |
| Output cap | Hook output > 10,000 chars is replaced by a file path + 2,000-char preview. | Truncate to ≤ 8,000 chars. |
| LSP overlap | 12 of 18 languages duplicate official plugins (typescript-lsp ≈ 212k installs); one server per extension, first wins. | Ship only the 6 unique ones. LSP never starts in cloud sessions — document. |
| Policy | Directory Policy 4C bans sponsored content in software output; real-person/brand names trigger review hold; `npx` launchers held for review; README must disclose what hooks run. | Remove BMC line from doctor output, de-brand, use project-local `tsc`. |
| Competition | Karpathy principles already shipped (~231k stars). No plugin blocks escape hatches across languages *before* write. | Lead positioning with the guard. |

## Scopes

| Scope | Tasks | Ships |
|---|---|---|
| **S1 — P0 must-fix** | 1, 2, 3, 4 | Correct hooks, de-branded, policy-clean. Releasable as 1.1.0. |
| **S2 — P1 should-do** | 5, 6, 7 | Trimmed LSP set, README disclosure, manifests/icon, eval-ready tests. Directory-submittable. |
| **S3 — P2 later** | 8 (outline only) | Evals, opt-outs, smart doctor, submissions. |

## Global Constraints

- Bash scripts must pass `bash -n` and `shellcheck` (when installed); `set -uo pipefail`; quote every variable.
- Only dependency: `jq`. If `jq` is missing every hook exits 0 (never block on a missing tool).
- Every compiler step runs only if its tool exists (`command -v`); missing tool → skip silently.
- Hook commands reference scripts only via `"${CLAUDE_PLUGIN_ROOT}/scripts/<name>.sh"`.
- Never invoke `npx`/`uvx`; TypeScript uses `$ROOT/node_modules/.bin/tsc` only.
- Feedback text to Claude ≤ 8,000 characters and ≤ 40 lines.
- Project root = `${CLAUDE_PROJECT_DIR:-$PWD}`. Ignore edited paths that contain `..` segments or resolve outside the root.
- No sponsorship/ads text in anything a script prints or a skill loads. README badges and `.github/FUNDING.yml` stay.
- The strings "Karpathy"/"Andrej" may appear only in the README attribution section.
- `version` lives only in `.claude-plugin/plugin.json`.
- Gate for every task: `./tests/test-suite.sh` passes and `claude plugin validate . --strict` passes.

## Review Focus

1. **Stop-hook loop:** project still fails after Claude's fix attempt → Claude must not be forced into an endless loop. Stop hook exits 0 when stdin has `"stop_hook_active": true`. (Test in Task 3.)
2. **Legitimate suppression:** a genuinely needed `// @ts-expect-error` (e.g. testing a type error) → allowed when the same line carries `polyglot-allow: <reason>`. (Test in Task 1.)
3. **Paths with spaces / outside project:** `/tmp/my dir/a.ts` and `../x.ts` → no crash; outside-root files skipped by the Post hook. (Test in Task 2.)
4. **Huge compiler output:** 5,000 lines of errors → feedback truncated to ≤ 8,000 chars with a "truncated" note. (Test in Task 2.)
5. **Non-git or clean project:** Stop hook in a dir without git or with no changes → exits 0 instantly, runs no compiler. (Test in Task 3.)

---

## Scope S1 — P0

### Task 1: PreToolUse escape-hatch guard

**Files:**
- Create: `scripts/guard-escape-hatches.sh`
- Modify: `hooks/hooks.json`, `scripts/verify-edit.sh` (delete its suppression-grep block), `tests/test-suite.sh`

**Interfaces:**
- Consumes: stdin hook JSON. For `Write` the new text is `.tool_input.content`; for `Edit` it is `.tool_input.new_string`; path is `.tool_input.file_path`.
- Produces: exit 0 (allow) or exit 2 with stderr starting `[Polyglot Guardrail]` (block). Pattern list (ERE, unchanged from v1.0): `@ts-ignore|@ts-expect-error|\bas any\b|:\s*any\b|#\s*type:\s*ignore|@phpstan-ignore|#\[allow\(dead_code\)\]|//\s*nolint`. Lines containing `polyglot-allow:` are exempt. Only the source extensions already listed in v1.0's `case` are scanned.

- [ ] **Step 1: Write failing tests** in `tests/test-suite.sh` (new `pre()` helper piping `{"tool_name":…,"tool_input":{"file_path":…,"content"|"new_string":…}}` into the guard):
  - `Write` of `bloat.ts` with `// @ts-ignore` → exit 2
  - `Edit` with `new_string` `x as any` on `a.ts` → exit 2
  - `Edit` with `new_string` `x = 1  # type: ignore  # polyglot-allow: stub lib` on `a.py` → exit 0
  - `Write` of `notes.md` containing `@ts-ignore` → exit 0
  - `Write` of clean `clean.ts` → exit 0
- [ ] **Step 2: Run** `./tests/test-suite.sh` → FAIL (script missing).
- [ ] **Step 3: Implement** `scripts/guard-escape-hatches.sh`; `chmod +x`. Text = `.tool_input.content // .tool_input.new_string // empty`; `grep -En` on it, then `grep -v 'polyglot-allow:'`. Stderr: header line, ≤10 matches, then `Fix the underlying type, or add "polyglot-allow: <reason>" on the same line if suppression is truly required.`
- [ ] **Step 4: Register** in `hooks/hooks.json`: `PreToolUse`, matcher `Write|Edit`, command `"${CLAUDE_PLUGIN_ROOT}/scripts/guard-escape-hatches.sh"`, timeout 10. Remove the grep block from `verify-edit.sh`; drop the old Post suppression tests.
- [ ] **Step 5: Run** `./tests/test-suite.sh && claude plugin validate . --strict` → pass.
- [ ] **Step 6: Commit** `feat: block type-suppression escape hatches before the write lands`

### Task 2: Fast per-file PostToolUse check

**Files:**
- Modify: `scripts/verify-edit.sh`, `hooks/hooks.json`, `tests/test-suite.sh`

**Interfaces:**
- Consumes: stdin hook JSON `.tool_input.file_path`; env `CLAUDE_PROJECT_DIR`.
- Produces: exit 0 or exit 2 with stderr `[Polyglot Compiler Loop] …` truncated to ≤ 40 lines / 8,000 chars, ending `… (truncated)` when cut. Shared truncation logic stays inline (one call site per script; Rule of Three).

Per-file check matrix (project-wide commands move to Task 3):

| Ext | Command |
|---|---|
| py, pyi | `pyright <file>` → fallback `py_compile` to `/dev/null` |
| go | `gofmt -e -l <file>` (syntax only) |
| c, cpp, cc, h, hpp | `clang -fsyntax-only <file>` |
| zig | `zig ast-check <file>` |
| php | `php -l` · rb: `ruby -c` · lua: `luac -p` · sh/bash/zsh: `shellcheck` → `bash -n` |
| ex, exs | `Code.string_to_quoted!` via env var (unchanged) |
| r, R | `parse(file=Sys.getenv("F"))` (unchanged) |
| dart | `dart analyze <file>` |
| ts…vue, rs, java, cs, swift, tf | none here (project-level only, Task 3) |

- [ ] **Step 1: Write failing tests:**
  - broken `.sh` → exit 2 (kept)
  - `.ts` file with a type error → exit 0 (no per-file TS check any more)
  - file path with a space (`$TMP/my dir/ok.sh`) → exit 0
  - path `$CLAUDE_PROJECT_DIR/../x.sh` (broken content) → exit 0 (outside root skipped)
  - fake checker: put a stub `shellcheck` printing 5,000 lines and exiting 1 first on `PATH` → exit 2, stderr ≤ 8,000 chars and contains `(truncated)`
- [ ] **Step 2: Run** suite → new tests FAIL.
- [ ] **Step 3: Implement:** resolve `ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"`; skip if path contains `/../` or does not start with `ROOT/`; apply the matrix; truncate. Hook timeout → 60. Matcher → `Write|Edit`.
- [ ] **Step 4: Run** suite + validate → pass.
- [ ] **Step 5: Commit** `fix: per-file post-edit checks with project-root guard and output cap`

### Task 3: Stop-hook project check

**Files:**
- Create: `scripts/verify-project.sh`
- Modify: `hooks/hooks.json`, `tests/test-suite.sh`

**Interfaces:**
- Consumes: stdin Stop JSON (`stop_hook_active`), env `CLAUDE_PROJECT_DIR`.
- Produces: exit 0, or exit 2 with stderr `[Polyglot Project Check] …` (≤ 8,000 chars), which makes Claude continue and fix.

Logic: exit 0 if `stop_hook_active` is true, if `ROOT` is not a git work tree, or if `git status --porcelain` lists no changed files. Collect changed extensions; for each language present run once, from `ROOT`:

| Changed ext | Condition | Command |
|---|---|---|
| ts…vue | `tsconfig.json` and `node_modules/.bin/tsc` exist | `node_modules/.bin/tsc --noEmit --pretty false --incremental` |
| rs | `Cargo.toml` | `cargo check --message-format=short` |
| go | `go.mod` | `go vet ./...` |
| java | any changed `.java` | `javac -Xlint:all -d <tmp>` on changed files |
| cs | `*.csproj` | `dotnet build --no-restore -v q` |
| swift | `Package.swift` | `swift build` |
| tf | any | `terraform validate -no-color` in each changed file's dir |

- [ ] **Step 1: Write failing tests** (temp git repo fixtures, `CLAUDE_PROJECT_DIR` set):
  - `{"stop_hook_active":true}` with a broken change → exit 0
  - non-git temp dir → exit 0
  - git repo, no changes → exit 0
  - git repo with changed `.ts` and a stub `node_modules/.bin/tsc` that prints an error and exits 2 → exit 2, stderr contains the error
- [ ] **Step 2: Run** suite → FAIL.
- [ ] **Step 3: Implement** script; register `Stop` hook, timeout 300; `chmod +x`.
- [ ] **Step 4: Run** suite + validate → pass.
- [ ] **Step 5: Commit** `feat: run whole-project compilers once per turn on Stop`

### Task 4: De-brand and remove sponsored output

**Files:**
- Rename: `skills/karpathy-core/` → `skills/tight-diff/`; `.cursor/rules/polyglot-karpathy.mdc` → `.cursor/rules/polyglot-tight-diff.mdc`
- Modify: `skills/tight-diff/SKILL.md`, `skills/optimize/SKILL.md`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `scripts/lsp-doctor.sh`, `README.md`, `tests/test-suite.sh`

- [ ] **Step 1: Write failing tests:**
  - skill list in suite becomes `tight-diff optimize architect clean doctor`
  - `! grep -rniE 'karpathy|andrej' --exclude=README.md --exclude-dir=docs --exclude-dir=.git .`
  - `! ./scripts/lsp-doctor.sh | grep -iE 'coffee|sponsor|polar'`
- [ ] **Step 2: Run** suite → FAIL.
- [ ] **Step 3: Implement:**
  - SKILL `name: tight-diff`; title "Tight Diff: Minimal, Compiler-Verified Changes"; update Principle 4 to describe Pre guard / Post check / Stop check and `polyglot-allow:`; drop `MultiEdit`; remove the `when_to_use` phrase "karpathy check".
  - `optimize`: replace "Andrej Karpathy's `llm.c` and `nanoGPT`" with "first-principles, `llm.c`-style".
  - `plugin.json`: description "Blocks type-suppression escape hatches before they land, gates edits on your local compilers across 18 languages, adds 6 LSP servers missing from the official set, and ships minimal-diff, optimization, and architecture skills." Keyword `karpathy` → `type-safety`; add `escape-hatch`, `quality-gate`.
  - `marketplace.json`: matching descriptions; remove top-level and entry `version`.
  - `lsp-doctor.sh`: drop the two footer link lines (keep a GitHub repo URL line only).
  - README: replace Karpathy branding with "Inspired by" section: credit to Andrej Karpathy's Jan 2026 post on LLM coding pitfalls (link https://x.com/karpathy/status/2015883857489522876) + "not affiliated with or endorsed by Andrej Karpathy or Anthropic".
- [ ] **Step 4: Run** suite + validate → pass.
- [ ] **Step 5: Commit** `refactor!: rename karpathy-core to tight-diff and remove sponsored output`; bump `plugin.json` version to `1.1.0`.

---

## Scope S2 — P1

### Task 5: Trim LSP set to the 6 unique languages

**Files:** Modify `.lsp.json`, `scripts/lsp-doctor.sh`, `tests/test-suite.sh`, `README.md`

- [ ] **Step 1: Tests:** `jq 'keys' .lsp.json` equals `["bash","dart","elixir","r","terraform","zig"]`; every entry's keys ⊆ `command args transport env initializationOptions settings workspaceFolder startupTimeout shutdownTimeout requestTimeout restartOnCrash maxRestarts diagnostics extensionToLanguage` (validate does not check `.lsp.json`; one bad key silently drops the file).
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement:** delete the 12 duplicated servers. Doctor: section 1 "Bundled LSP servers (6)", section 2 "Official Anthropic LSP plugins" printing `claude plugin install <name>@claude-plugins-official` for each of typescript-lsp, pyright-lsp, rust-analyzer-lsp, gopls-lsp, clangd-lsp, jdtls-lsp, csharp-lsp, php-lsp, ruby-lsp, swift-lsp, kotlin-lsp, lua-lsp, section 3 "Compilers used by the hooks" (`tsc`, `pyright`/`python3`, `cargo`, `go`, `clang`, `zig`, `javac`, `dotnet`, `php`, `ruby`, `elixir`, `swift`, `dart`, `luac`, `shellcheck`, `terraform`, `Rscript`). README matrix gets an "LSP source" column.
- [ ] **Step 4: Run** suite + validate → pass.
- [ ] **Step 5: Commit** `refactor: ship only LSP servers missing from the official marketplace`

### Task 6: Directory-ready manifests, README, icon

**Files:** Modify `.claude-plugin/plugin.json`, `README.md`; Create `.claude-plugin/icon.png` (**user-supplied**, square PNG 512–2048 px, < 2 MB — the directory accepts the first icon only, so it should be final art).

- [ ] **Step 1:** `plugin.json` add `"homepage": "https://github.com/tahmidbintaslim/claude-code-polyglot"`, `"icon": ".claude-plugin/icon.png"`.
- [ ] **Step 2:** README sections: *What the hooks run* (table of every command by stage, plus "no network calls, no telemetry"), *Escape hatches & `polyglot-allow:`*, *Cloud sessions* (LSP servers do not start there; hooks still run), *Updating* (`claude plugin marketplace update polyglot-marketplace`), *Enterprise* (`allowManagedHooksOnly` disables the hooks), *3 example prompts*, *Inspired by* (from Task 4), *Not affiliated* disclaimer. Title "Polyglot for Claude Code".
- [ ] **Step 3: Run** `claude plugin validate . --strict --profile directory` → `Validation passed`.
- [ ] **Step 4: Commit** `docs: directory-ready README, homepage, icon`

### Task 7: CI

**Files:** Create `.github/workflows/ci.yml`

- [ ] **Step 1:** Ubuntu job: install `jq shellcheck`, `npm i -g @anthropic-ai/claude-code`, run `shellcheck scripts/*.sh tests/*.sh`, `./tests/test-suite.sh`, `claude plugin validate . --strict`.
- [ ] **Step 2:** Push; confirm green.
- [ ] **Step 3: Commit** `ci: run test suite, shellcheck and plugin validate`

---

## Scope S3 — P2 (outline; plan in detail when S2 ships)

8. `claude plugin eval init` cases: `tight-diff` triggers on "refactor X"; guard blocks a prompted `@ts-ignore`; `--threshold 1.0` in CI with `--trust-plugin`.
9. Per-language opt-out via `userConfig` (e.g. `disabledLanguages`) read in all three scripts.
10. Doctor detects repo languages from file extensions and prints only relevant installs.
11. Submissions: claude.ai/directory/manage (paid plan, public repo, "Plugin bundle"); awesome-claude-code issue form once repo is ≥ 14 days old or ≥ 100 stars; MCP Registry not applicable (no MCP server).
