#!/usr/bin/env bash
# Shows which language servers and compilers HatchLock can use for this project.
# Only languages found in the project are listed; pass --all to list every one.
set -uo pipefail
# shellcheck source=scripts/lang.sh
. "$(dirname "$0")/lang.sh"

ALL=false
[[ "${1:-}" == "--all" ]] && ALL=true
ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"

# Languages present in the project: tracked + untracked files in a git repo,
# otherwise a shallow scan that skips dependency and build folders.
list_files() {
  if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "$ROOT" ls-files --cached --others --exclude-standard
  else
    find "$ROOT" -maxdepth 6 \( -name node_modules -o -name .git -o -name vendor -o -name dist \
      -o -name build -o -name target -o -name .venv -o -name __pycache__ \) -prune -o -type f -print
  fi
}
FOUND=" "
if ! $ALL; then
  while IFS= read -r f; do
    [[ "$f" == */node_modules/* || "$f" == node_modules/* ]] && continue
    l=$(lang_of "$f"); [[ -n "$l" && "$FOUND" != *" $l "* ]] && FOUND+="$l "
  done < <(list_files | head -n 20000)
  [[ "$FOUND" == " " ]] && ALL=true
fi
want() { $ALL || [[ "$FOUND" == *" $1 "* ]]; }

has() { command -v "$1" >/dev/null 2>&1; }
check() { # check <label> <binary> <install hint>
  if has "$2"; then printf "  [OK]      %-24s (%s)\n" "$1" "$2"
  else printf "  [MISSING] %-24s -> %s\n" "$1" "$3"; fi
}

echo "========================================================================"
echo "  HatchLock LSP & Compiler Toolchain Health Audit"
if $ALL; then echo "  Showing every supported language."
else echo "  Languages in this project:${FOUND% }"; echo "  (Run with --all to see every supported language.)"; fi
echo "========================================================================"

BUNDLED=(
  "zig|Zig|zls|brew install zls"
  "elixir|Elixir|elixir-ls|brew install elixir-ls"
  "dart|Dart|dart|brew install dart-sdk"
  "shell|Bash / Shell|bash-language-server|npm i -g bash-language-server"
  "terraform|Terraform|terraform-ls|brew install hashicorp/tap/terraform-ls"
  "r|R|R|R -e 'install.packages(\"languageserver\")'"
)
OFFICIAL=(
  "typescript|typescript-lsp" "python|pyright-lsp" "rust|rust-analyzer-lsp" "go|gopls-lsp"
  "cpp|clangd-lsp" "java|jdtls-lsp" "csharp|csharp-lsp" "php|php-lsp" "ruby|ruby-lsp"
  "swift|swift-lsp" "kotlin|kotlin-lsp" "lua|lua-lsp"
)
COMPILERS=(
  "typescript|tsc" "python|pyright" "python|python3" "rust|cargo" "go|go" "go|gofmt"
  "cpp|clang-check" "zig|zig" "java|javac" "csharp|dotnet" "php|php" "ruby|ruby"
  "elixir|elixir" "swift|swift" "dart|dart" "lua|luac" "shell|shellcheck" "shell|bash"
  "terraform|terraform" "r|Rscript"
)

shown=0
for row in "${BUNDLED[@]}"; do
  IFS='|' read -r lang label bin hint <<<"$row"; want "$lang" || continue
  (( shown++ )) || echo "  1. LSP servers bundled with HatchLock"
  check "$label" "$bin" "$hint"
done

shown=0
for row in "${OFFICIAL[@]}"; do
  IFS='|' read -r lang plugin <<<"$row"; want "$lang" || continue
  (( shown++ )) || { echo "------------------------------------------------------------------------"; echo "  2. Install Anthropic's official LSP plugin for:"; }
  echo "     claude plugin install $plugin@claude-plugins-official"
done

shown=0
for row in "${COMPILERS[@]}"; do
  IFS='|' read -r lang t <<<"$row"; want "$lang" || continue
  (( shown++ )) || { echo "------------------------------------------------------------------------"; echo "  3. Compilers used by HatchLock's edit checks (missing = check skipped)"; }
  if has "$t" || { [[ "$t" == tsc ]] && [[ -x "$ROOT/node_modules/.bin/tsc" ]]; }; then
    printf "  [OK]      %s\n" "$t"
  else
    printf "  [--]      %s\n" "$t"
  fi
done
want typescript && echo "  (tsc is used from the project's node_modules/.bin when present)"

OFF="${CLAUDE_PLUGIN_OPTION_DISABLED_LANGUAGES:-${CLAUDE_PLUGIN_OPTION_disabled_languages:-}}"
if [[ -n "$OFF" ]]; then
  echo "------------------------------------------------------------------------"
  echo "  Turned off in settings: $OFF"
fi
echo "========================================================================"
echo "  Note: Claude Code only starts LSP servers for files touched in a session,"
echo "  and never in cloud sessions."
echo "  Docs: https://github.com/tahmidbintaslim/HatchLock"
echo "========================================================================"
