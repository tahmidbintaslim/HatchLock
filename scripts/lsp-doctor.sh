#!/usr/bin/env bash
# Prints which language servers and compilers HatchLock can use on this machine.
set -uo pipefail

has() { command -v "$1" >/dev/null 2>&1; }
check() { # check <label> <binary> <install hint>
  if has "$2"; then printf "  [OK]      %-24s (%s)\n" "$1" "$2"
  else printf "  [MISSING] %-24s -> %s\n" "$1" "$3"; fi
}

echo "========================================================================"
echo "  HatchLock LSP & Compiler Toolchain Health Audit"
echo "========================================================================"
echo "  1. LSP servers bundled with HatchLock"
check "Zig"            zls                  "brew install zls"
check "Elixir"         elixir-ls            "brew install elixir-ls"
check "Dart"           dart                 "brew install dart-sdk"
check "Bash / Shell"   bash-language-server "npm i -g bash-language-server"
check "Terraform"      terraform-ls         "brew install hashicorp/tap/terraform-ls"
check "R"              R                    "R -e 'install.packages(\"languageserver\")'"

echo "------------------------------------------------------------------------"
echo "  2. Other languages: install Anthropic's official LSP plugins"
for p in typescript-lsp pyright-lsp rust-analyzer-lsp gopls-lsp clangd-lsp jdtls-lsp \
         csharp-lsp php-lsp ruby-lsp swift-lsp kotlin-lsp lua-lsp; do
  echo "     claude plugin install $p@claude-plugins-official"
done

echo "------------------------------------------------------------------------"
echo "  3. Compilers used by HatchLock's edit checks (missing = check skipped)"
for t in tsc pyright python3 cargo go gofmt clang zig javac dotnet php ruby elixir swift dart luac shellcheck terraform Rscript; do
  if has "$t"; then printf "  [OK]      %s\n" "$t"; else printf "  [--]      %s\n" "$t"; fi
done
echo "  (tsc is used from the project's node_modules/.bin when present)"
echo "========================================================================"
echo "  Note: Claude Code only starts LSP servers for files touched in a session,"
echo "  and never in cloud sessions."
echo "  Docs: https://github.com/tahmidbintaslim/claude-code-polyglot"
echo "========================================================================"
