# 🌐 claude-code-polyglot

**18-Language Native LSP Code Intelligence, Self-Healing Compiler Loops, and Andrej Karpathy Engineering Skills for Claude Code.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Claude Code Plugin](https://img.shields.io/badge/Claude_Code-Plugin_&_Marketplace-blueviolet)](https://github.com/tahmidbintaslim/claude-code-polyglot)
[![Languages: 18](https://img.shields.io/badge/LSP_Languages-18_Supported-success)](#supported-languages)
[![Buy Me A Coffee](https://img.shields.io/badge/Buy_Me_A_Coffee-Support-FFDD00?logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/tahmid)

Stop AI spaghetti code, premature abstractions, and silent cross-file type breaks. **`claude-code-polyglot`** combines **18 native Language Server Protocol (`.lsp.json`) bridges**, a **deterministic `PostToolUse` compiler loop (`Exit Code 2`)**, and **Andrej Karpathy's minimalist coding & AI/systems optimization principles** in a single 1-command install.

---

## ⚡ Why `polyglot` Beats Static `CLAUDE.md` Prompts

| Capability | Raw Claude Code | Static `CLAUDE.md` Prompts | `claude-code-polyglot` |
| :--- | :---: | :---: | :---: |
| **Karpathy 4 Coding Principles** | ❌ | ✅ | ✅ Auto-enforced (`karpathy-core`) |
| **Native 18-Language LSP Graph** | ❌ | ❌ | ✅ Pre-wired in `.lsp.json` |
| **Self-Healing Compiler Loop** | ❌ | ❌ | ✅ `PostToolUse` Hook (`Exit Code 2`) |
| **Blocks `@ts-ignore` / `as any` / `# type: ignore`** | ❌ | ⚠️ Prompt only | ✅ Mechanically blocked by hook |
| **AI/LLM & SQL Performance Optimization** | ❌ | ❌ | ✅ `/polyglot:optimize` |
| **Data-First System Architecture & ADRs** | ❌ | ❌ | ✅ `/polyglot:architect` |

---

## 🚀 1-Command Installation

### Option 1: Install via Claude Code Marketplace (Recommended)
```bash
claude plugin marketplace add tahmidbintaslim/claude-code-polyglot
claude plugin install polyglot@polyglot-marketplace
```

### Option 2: Run Directly from a Local Clone
```bash
git clone https://github.com/tahmidbintaslim/claude-code-polyglot.git
claude --plugin-dir ./claude-code-polyglot
```

---

## 🛠️ Included Slash Commands & Skills

- **Always-On (`karpathy-core`):** Automatically enforces Think Before Coding, Simplicity First (200-to-50 line rule), LSP Symbol Traversal before Edits, and Goal-Driven Compiler Verification.
- **`/polyglot:optimize [target]`:** First-principles latency, memory, SQL N+1, and AI/LLM token/KV-cache optimization (`llm.c` / `nanoGPT` philosophy).
- **`/polyglot:architect [feature]`:** Data-first schema modeling, boundary validation, and 3-tier architecture trade-off matrices.
- **`/polyglot:clean [file]`:** Strips single-use wrappers (Rule of Three) and flattens nested control flow to guard clauses.
- **`/polyglot:doctor`:** Audits your machine for all 18 LSP binaries and prints 1-line install commands for missing tools.

---

## Supported Languages

| # | Language | Extensions | LSP Server | Post-Edit Check |
| :-- | :--- | :--- | :--- | :--- |
| 1 | TypeScript / JS / Vue | `.ts .tsx .js .jsx .mjs .cjs .vue` | `typescript-language-server` | `npx tsc --noEmit` (if `tsconfig.json`) |
| 2 | Python | `.py .pyi` | `pyright-langserver` | `pyright` → `python3 -m py_compile` |
| 3 | Rust | `.rs` | `rust-analyzer` | `cargo check` (if `Cargo.toml`) |
| 4 | Go | `.go` | `gopls` | `go vet` (package dir) |
| 5 | C / C++ | `.c .cpp .cc .h .hpp` | `clangd` | `clang -fsyntax-only` |
| 6 | Zig | `.zig` | `zls` | `zig ast-check` |
| 7 | Java | `.java` | `jdtls` | `javac -Xlint:all` |
| 8 | C# | `.cs` | `csharp-ls` | `dotnet build` (if `*.csproj`) |
| 9 | PHP | `.php` | `intelephense` | `php -l` |
| 10 | Ruby | `.rb` | `ruby-lsp` | `ruby -c` |
| 11 | Elixir | `.ex .exs` | `elixir-ls` | `Code.string_to_quoted!` parse |
| 12 | Swift | `.swift` | `sourcekit-lsp` | `swiftc -typecheck` |
| 13 | Kotlin | `.kt .kts` | `kotlin-language-server` | — (LSP only; `kotlinc` too slow for a 30s hook) |
| 14 | Dart | `.dart` | `dart language-server` | `dart analyze` |
| 15 | Lua | `.lua` | `lua-language-server` | `luac -p` |
| 16 | Bash / Shell | `.sh .bash .zsh` | `bash-language-server` | `shellcheck` → `bash -n` |
| 17 | Terraform | `.tf .tfvars` | `terraform-ls` | `terraform validate` |
| 18 | R | `.r .R` | `languageserver` | `parse(file=...)` |

Missing toolchains are skipped silently — the hook never blocks on a tool you don't have.

## 🧪 Development

```bash
./tests/test-suite.sh
```

---

## ☕ Support & Sponsorship

If `claude-code-polyglot` saves you hours of debugging AI-generated type breaks and spaghetti abstractions, consider supporting ongoing maintenance:

- ⭐ **Star this repository** on GitHub to help more developers discover it!
- ☕ [Buy Me a Coffee](https://buymeacoffee.com/tahmid)
- 🌐 [Author Website — Tahmid Bin Taslim Rafi](https://tahmid.space)
