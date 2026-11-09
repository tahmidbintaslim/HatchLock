#!/usr/bin/env bash
set -uo pipefail

echo "========================================================================"
echo "  Polyglot 18-Language LSP & Compiler Toolchain Health Audit"
echo "========================================================================"

INSTALLED=0
TOTAL=18

check_tool() {
  local lang="$1" bin="$2" hint="$3"
  if command -v "$bin" >/dev/null 2>&1; then
    printf "  [OK]      %-22s (%s)\n" "$lang" "$bin"
    INSTALLED=$((INSTALLED + 1))
  else
    printf "  [MISSING] %-22s -> %s\n" "$lang" "$hint"
  fi
}

check_tool "1. TypeScript/JS/Vue" "typescript-language-server" "npm i -g typescript-language-server typescript"
check_tool "2. Python"            "pyright-langserver"         "npm i -g pyright"
check_tool "3. Rust"              "rust-analyzer"              "rustup component add rust-analyzer"
check_tool "4. Go"                "gopls"                      "go install golang.org/x/tools/gopls@latest"
check_tool "5. C / C++"           "clangd"                     "brew install llvm / apt install clangd"
check_tool "6. Zig"               "zls"                        "brew install zls"
check_tool "7. Java"              "jdtls"                      "brew install jdtls"
check_tool "8. C#"                "csharp-ls"                  "dotnet tool install --global csharp-ls"
check_tool "9. PHP"               "intelephense"               "npm i -g intelephense"
check_tool "10. Ruby"             "ruby-lsp"                   "gem install ruby-lsp"
check_tool "11. Elixir"           "elixir-ls"                  "brew install elixir-ls"
check_tool "12. Swift"            "sourcekit-lsp"              "xcode-select --install"
check_tool "13. Kotlin"           "kotlin-language-server"     "brew install kotlin-language-server"
check_tool "14. Dart"             "dart"                       "brew install dart-sdk"
check_tool "15. Lua"              "lua-language-server"        "brew install lua-language-server"
check_tool "16. Bash / Shell"     "bash-language-server"       "npm i -g bash-language-server"
check_tool "17. Terraform"        "terraform-ls"               "brew install hashicorp/tap/terraform-ls"
check_tool "18. R"                "R"                          "R -e 'install.packages(\"languageserver\")'"

echo "------------------------------------------------------------------------"
echo "  Active LSP Servers Ready: $INSTALLED / $TOTAL"
echo "  (Note: Claude Code only starts servers for files touched in session)"
echo "========================================================================"
echo "  Star on GitHub:    https://github.com/tahmidbintaslim/claude-code-polyglot"
echo "  Buy Me a Coffee:   https://buymeacoffee.com/tahmid"
echo "========================================================================"
