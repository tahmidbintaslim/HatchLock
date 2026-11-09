#!/usr/bin/env bash
# PostToolUse hook: fast, per-file syntax/type check of the file just edited.
# Whole-project compilers run once per turn in verify-project.sh (Stop hook).
# Exit 2 shows stderr to Claude; the edit itself has already landed.
set -uo pipefail

PAYLOAD=$(cat)
command -v jq >/dev/null 2>&1 || exit 0

FILE_PATH=$(jq -r '.tool_input.file_path // empty' <<<"$PAYLOAD")
[[ -n "$FILE_PATH" && -f "$FILE_PATH" ]] || exit 0

# Only check files inside the project; never follow "..".
ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
[[ "$FILE_PATH" == *"/../"* || "$FILE_PATH" == "../"* ]] && exit 0
[[ "$FILE_PATH" == "$ROOT"/* ]] || exit 0

has() { command -v "$1" >/dev/null 2>&1; }
OUTPUT=""
STATUS=0

case "${FILE_PATH##*.}" in
  py|pyi)
    if has pyright; then
      OUTPUT=$(pyright "$FILE_PATH" 2>&1); STATUS=$?
    elif has python3; then
      # Compile to /dev/null so no __pycache__ lands in the repo.
      OUTPUT=$(python3 -c 'import py_compile,sys; py_compile.compile(sys.argv[1], cfile="/dev/null", doraise=True)' "$FILE_PATH" 2>&1); STATUS=$?
    fi ;;
  go)
    if has gofmt; then
      OUTPUT=$(gofmt -e -l "$FILE_PATH" 2>&1 >/dev/null); STATUS=$?
    fi ;;
  c|cpp|cc|h|hpp)
    if has clang; then OUTPUT=$(clang -fsyntax-only "$FILE_PATH" 2>&1); STATUS=$?; fi ;;
  zig)
    if has zig; then OUTPUT=$(zig ast-check "$FILE_PATH" 2>&1); STATUS=$?; fi ;;
  php)
    if has php; then OUTPUT=$(php -l "$FILE_PATH" 2>&1); STATUS=$?; fi ;;
  rb)
    if has ruby; then OUTPUT=$(ruby -c "$FILE_PATH" 2>&1); STATUS=$?; fi ;;
  lua)
    if has luac; then OUTPUT=$(luac -p "$FILE_PATH" 2>&1); STATUS=$?; fi ;;
  sh|bash|zsh)
    if has shellcheck; then
      OUTPUT=$(shellcheck "$FILE_PATH" 2>&1); STATUS=$?
    elif has bash; then
      OUTPUT=$(bash -n "$FILE_PATH" 2>&1); STATUS=$?
    fi ;;
  ex|exs)
    # Parse only; path passed via env so quotes in it can't break the expression.
    if has elixir; then
      OUTPUT=$(F="$FILE_PATH" elixir -e 'Code.string_to_quoted!(File.read!(System.fetch_env!("F")))' 2>&1); STATUS=$?
    fi ;;
  r|R)
    if has Rscript; then
      OUTPUT=$(F="$FILE_PATH" Rscript -e 'invisible(parse(file = Sys.getenv("F")))' 2>&1); STATUS=$?
    fi ;;
  dart)
    if has dart; then OUTPUT=$(dart analyze "$FILE_PATH" 2>&1); STATUS=$?; fi ;;
esac

[[ $STATUS -eq 0 ]] && exit 0

# Hook feedback over 10k chars is replaced by a file pointer; stay well under.
FEEDBACK=$(head -n 40 <<<"$OUTPUT" | head -c 7800)
{
  echo "[Polyglot Compiler Loop] Verification failed after editing $FILE_PATH:"
  echo "$FEEDBACK"
  [[ "$FEEDBACK" != "$OUTPUT" ]] && echo "… (truncated)"
} >&2
exit 2
