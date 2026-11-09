#!/usr/bin/env bash
# PostToolUse hook: blocks type-suppression escape hatches and runs the local
# compiler/typechecker for the edited file. Exit 2 feeds stderr back to Claude.
set -uo pipefail

PAYLOAD=$(cat)
# No jq -> can't parse the payload; never block the user on a missing tool.
command -v jq >/dev/null 2>&1 || exit 0

FILE_PATH=$(jq -r '.tool_input.file_path // empty' <<<"$PAYLOAD")
[[ -n "$FILE_PATH" && -f "$FILE_PATH" ]] || exit 0

EXT="${FILE_PATH##*.}"

# 1. Anti-suppression escape-hatch blocker (source files only)
case "$EXT" in
  ts|tsx|js|jsx|mjs|cjs|vue|py|pyi|rs|go|c|cpp|cc|h|hpp|zig|java|cs|php|rb|ex|exs|swift|kt|kts|dart|lua)
    MATCHES=$(grep -En '(@ts-ignore|@ts-expect-error|\bas any\b|:\s*any\b|#\s*type:\s*ignore|@phpstan-ignore|#\[allow\(dead_code\)\]|//\s*nolint)' "$FILE_PATH" 2>/dev/null || true)
    if [[ -n "$MATCHES" ]]; then
      echo "[Polyglot Guardrail] Blocked compiler/type suppression detected in $FILE_PATH:" >&2
      head -n 10 <<<"$MATCHES" >&2
      echo "Fix the underlying type or interface contract instead of silencing the compiler." >&2
      exit 2
    fi
    ;;
esac

# 2. Deterministic compiler & syntax loop (each check is skipped if its tool is absent)
OUTPUT=""
STATUS=0
has() { command -v "$1" >/dev/null 2>&1; }

case "$EXT" in
  ts|tsx|js|jsx|mjs|cjs|vue)
    if [[ -f tsconfig.json ]] && has npx; then
      OUTPUT=$(npx --no-install tsc --noEmit --pretty false 2>&1); STATUS=$?
    fi ;;
  py|pyi)
    if has pyright; then
      OUTPUT=$(pyright "$FILE_PATH" 2>&1); STATUS=$?
    elif has python3; then
      # Compile to a throwaway path so no __pycache__ lands in the repo.
      OUTPUT=$(python3 -c 'import py_compile,sys; py_compile.compile(sys.argv[1], cfile="/dev/null", doraise=True)' "$FILE_PATH" 2>&1); STATUS=$?
    fi ;;
  rs)
    if [[ -f Cargo.toml ]] && has cargo; then
      OUTPUT=$(cargo check --message-format=short 2>&1); STATUS=$?
    fi ;;
  go)
    # Vet the whole package: single-file vet misses symbols from sibling files.
    if has go; then
      OUTPUT=$(cd "$(dirname "$FILE_PATH")" && go vet . 2>&1); STATUS=$?
    fi ;;
  c|cpp|cc|h|hpp)
    if has clang; then
      OUTPUT=$(clang -fsyntax-only "$FILE_PATH" 2>&1); STATUS=$?
    fi ;;
  zig)
    if has zig; then
      OUTPUT=$(zig ast-check "$FILE_PATH" 2>&1); STATUS=$?
    fi ;;
  java)
    if has javac; then
      # -d to a temp dir so .class files don't litter the source tree.
      TMP_OUT=$(mktemp -d)
      OUTPUT=$(javac -Xlint:all -d "$TMP_OUT" "$FILE_PATH" 2>&1); STATUS=$?
      rm -rf "$TMP_OUT"
    fi ;;
  cs)
    if compgen -G "*.csproj" >/dev/null && has dotnet; then
      OUTPUT=$(dotnet build --no-restore -v q 2>&1); STATUS=$?
    fi ;;
  php)
    if has php; then
      OUTPUT=$(php -l "$FILE_PATH" 2>&1); STATUS=$?
    fi ;;
  rb)
    if has ruby; then
      OUTPUT=$(ruby -c "$FILE_PATH" 2>&1); STATUS=$?
    fi ;;
  ex|exs)
    # Parse only; path passed via env so quotes in it can't break the expression.
    if has elixir; then
      OUTPUT=$(F="$FILE_PATH" elixir -e 'Code.string_to_quoted!(File.read!(System.fetch_env!("F")))' 2>&1); STATUS=$?
    fi ;;
  swift)
    if has swiftc; then
      OUTPUT=$(swiftc -typecheck "$FILE_PATH" 2>&1); STATUS=$?
    fi ;;
  dart)
    if has dart; then
      OUTPUT=$(dart analyze "$FILE_PATH" 2>&1); STATUS=$?
    fi ;;
  lua)
    if has luac; then
      OUTPUT=$(luac -p "$FILE_PATH" 2>&1); STATUS=$?
    fi ;;
  sh|bash|zsh)
    if has shellcheck; then
      OUTPUT=$(shellcheck "$FILE_PATH" 2>&1); STATUS=$?
    elif has bash; then
      OUTPUT=$(bash -n "$FILE_PATH" 2>&1); STATUS=$?
    fi ;;
  tf|tfvars)
    if has terraform; then
      OUTPUT=$(terraform validate -no-color 2>&1); STATUS=$?
    fi ;;
  r|R)
    if has Rscript; then
      OUTPUT=$(F="$FILE_PATH" Rscript -e 'invisible(parse(file = Sys.getenv("F")))' 2>&1); STATUS=$?
    fi ;;
esac

if [[ $STATUS -ne 0 ]]; then
  echo "[Polyglot Compiler Loop] Verification failed after editing $FILE_PATH:" >&2
  head -n 35 <<<"$OUTPUT" >&2
  exit 2
fi

exit 0
