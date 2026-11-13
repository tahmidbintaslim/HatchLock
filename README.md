<p align="center">
  <a href="https://tahmidbintaslim.github.io/HatchLock/"><img src="assets/banner.png" alt="HatchLock: stop your AI from hiding type errors. Without HatchLock, a // @ts-ignore comment hides the error. With HatchLock, the comment is blocked and the type is fixed." width="100%"></a>
</p>

# HatchLock

**Stop your AI from hiding type errors.**

When an AI coding assistant hits a type error, the quick way out is to tell the type checker to look away: `@ts-ignore`, `as any`, `# type: ignore`. The error is still there. You just can't see it.

HatchLock is a free plugin for Claude Code that closes that way out:

- **It blocks the shortcut before it is written.** The AI is told to fix the type instead.
- **It checks each edit with your own compilers**, so mistakes are caught while the AI is still working.
- **It leaves your existing code alone.** Only new shortcuts are stopped.
- **It runs on your machine.** No account, no tracking, nothing sent anywhere.

[Website](https://tahmidbintaslim.github.io/HatchLock/) · [Report a problem](https://github.com/tahmidbintaslim/HatchLock/issues) · [![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE) [![Buy Me A Coffee](https://img.shields.io/badge/Buy_Me_A_Coffee-Support-FFDD00?logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/tahmid)

---

## Install

```bash
claude plugin marketplace add tahmidbintaslim/HatchLock
```

```bash
claude plugin install hatchlock@hatchlock-marketplace
```

Or run from a local clone:

```bash
git clone https://github.com/tahmidbintaslim/HatchLock.git
```

```bash
claude --plugin-dir ./HatchLock
```

### Updating

Third-party marketplaces do not auto-update by default:

```bash
claude plugin marketplace update hatchlock-marketplace
```

---

## How it works

HatchLock checks code at three points:

| Stage | Hook | What happens |
| :--- | :--- | :--- |
| **Before each write** | `PreToolUse` on `Write`/`Edit`/`NotebookEdit` | The new text is scanned for escape hatches. If one is found, the write is **blocked** and Claude is told to fix the type instead. |
| **After each edit** | `PostToolUse` on `Write`/`Edit` | A fast syntax/type check runs on that one file. Errors go back to Claude. |
| **End of each turn** | `Stop` | Whole-project compilers run once for each language with uncommitted changes. Errors make Claude continue and fix them (at most once per turn, never a loop). |

### Blocked escape hatches

| Language | Blocked |
| :--- | :--- |
| TypeScript / JS / Vue | `@ts-ignore`, `@ts-expect-error`, `@ts-nocheck`, `eslint-disable`, `as any`, `: any`, `<any>`, `Record<string, any>` |
| Python (incl. notebooks) | `# type: ignore`, `# pyright: ignore` |
| PHP | `@phpstan-ignore`, `@psalm-suppress` |
| Rust | `#[allow(dead_code)]`, `#[allow(unused…)]` |
| Go | `//nolint` |

Only **new** suppressions are blocked: ones already in the code Claude is editing are left alone. `.d.ts` declaration files are skipped.

**Genuinely need one?** Put `hatchlock-allow: <reason>` on the same line (the reason is required):

```ts
// @ts-expect-error hatchlock-allow: asserting this call is a type error
```

### What the hooks run

Everything runs locally with tools you already have installed. A missing tool means that check is skipped, never a failure. **No network calls, no telemetry, no data leaves your machine.**

| Language | After each edit (that file) | End of turn (project) |
| :--- | :--- | :--- |
| TypeScript / JS / Vue | — | `node_modules/.bin/tsc --noEmit --incremental` (needs `tsconfig.json`; build info kept outside the repo) |
| Python | `pyright <file>` → fallback `python3` compile check | — |
| Rust | — | `cargo check` (needs `Cargo.toml`) |
| Go | `gofmt -e` | `go vet ./...` (needs `go.mod`) |
| C / C++ | `clang-check -p` (only with `compile_commands.json`) | — |
| Zig | `zig ast-check` | — |
| Java | — | `javac -Xlint:all` on changed files, output to a temp dir (skipped for Maven/Gradle projects) |
| C# | — | `dotnet build --no-restore` (needs `*.csproj`) |
| PHP | `php -l` | — |
| Ruby | `ruby -c` | — |
| Elixir | parse with `Code.string_to_quoted!` | — |
| Swift | — | `swift build` (needs `Package.swift`) |
| Dart | `dart analyze <file>` | — |
| Lua | `luac -p` | — |
| Bash / Shell | `shellcheck -S warning` → fallback `bash -n` | — |
| Terraform | — | `terraform validate` in changed, initialized directories |
| R | `parse(file=…)` | — |
| Kotlin | — | — (no check; `kotlinc` is too slow for a hook) |

Requires `jq`. Without it, every hook exits silently.

---

## Language servers

HatchLock bundles LSP configs **only for languages Anthropic does not ship an official LSP plugin for**:

| Language | Server | Install |
| :--- | :--- | :--- |
| Zig | `zls` | `brew install zls` |
| Elixir | `elixir-ls` | `brew install elixir-ls` |
| Dart | `dart language-server` | `brew install dart-sdk` |
| Bash / Shell | `bash-language-server` | `npm i -g bash-language-server` |
| Terraform | `terraform-ls` | `brew install hashicorp/tap/terraform-ls` |
| R | `languageserver` | `R -e 'install.packages("languageserver")'` |

For TypeScript, Python, Rust, Go, C/C++, Java, C#, PHP, Ruby, Swift, Kotlin and Lua, install Anthropic's official plugins, for example:

```bash
claude plugin install typescript-lsp@claude-plugins-official
```

Run `/hatchlock:doctor` to see exactly what is installed and what to add.

**Cloud sessions:** Claude Code does not start language servers in cloud sessions. The hooks still run.

---

## Skills

| Command | What it does |
| :--- | :--- |
| `tight-diff` (auto) | Minimal, surgical changes; LSP lookups before changing signatures; no escape hatches; verify before moving on. |
| `/hatchlock:optimize [target]` | First-principles performance: N+1 queries, accidental O(N²), memory, LLM prompt/prefix-cache layout. |
| `/hatchlock:architect [feature]` | Data-first design: schemas and state machines first, then a 3-option trade-off matrix. |
| `/hatchlock:clean [file]` | Inline single-use abstractions, flatten nesting, remove dead code without behaviour changes. |
| `/hatchlock:doctor` | Audit installed language servers and compilers. |

### Example prompts

1. "Fix the type errors in `src/billing.ts` without using `any` or `@ts-ignore`."
2. "/hatchlock:optimize the `/orders` endpoint, it's doing one query per line item."
3. "/hatchlock:clean `lib/report_builder.py`, then confirm behaviour is unchanged."

---

## Enterprise

Organizations that set `allowManagedHooksOnly` in managed settings disable plugin hooks, including HatchLock's. The skills and language servers still work.

## ChatGPT and Codex

The four portable skills (`tight-diff`, `optimize`, `architect`, `clean`) also ship as a skills-only HatchLock plugin for ChatGPT/Codex. OpenAI's directory does not accept hooks or LSP servers, so that version gives guidance only: no blocking and no compiler checks. Maintainers build it with `./scripts/build-openai-zip.sh`.

## Other editors

`.cursor/rules/hatchlock-tight-diff.mdc` carries the same rules for Cursor and Windsurf (advisory only; no hooks).

## Website

The landing page lives in `site/` (Astro). Design notes are in `DESIGN.md` and `PRODUCT.md`.

```bash
cd site && npm install && npm run dev
```

## Development

```bash
./tests/test-suite.sh
```

```bash
claude plugin validate . --strict
```

## Privacy

HatchLock collects and sends no data. See [PRIVACY.md](PRIVACY.md).

## Support

Report bugs and ask questions in [GitHub Issues](https://github.com/tahmidbintaslim/HatchLock/issues).

## Inspired by

The `tight-diff` principles are adapted from [Andrej Karpathy's January 2026 post on LLM coding pitfalls](https://x.com/karpathy/status/2015883857489522876). HatchLock is an independent project and is not affiliated with or endorsed by Andrej Karpathy, Anthropic or OpenAI.

## ☕ Support the project

- ⭐ Star the repository
- ☕ [Buy Me a Coffee](https://buymeacoffee.com/tahmid)
- 🌐 [Tahmid Bin Taslim Rafi](https://tahmid.space)

MIT License.
