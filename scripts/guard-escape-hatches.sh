#!/usr/bin/env bash
# PreToolUse hook: blocks Write/Edit calls that would add type-checker escape
# hatches. Exit 2 stops the tool call and shows stderr to Claude.
set -uo pipefail

PAYLOAD=$(cat)
command -v jq >/dev/null 2>&1 || exit 0

FILE_PATH=$(jq -r '.tool_input.file_path // empty' <<<"$PAYLOAD")
[[ "$FILE_PATH" == *.d.ts ]] && exit 0  # ambient declarations legitimately use `any`

# Per-language patterns (POSIX ERE, portable to BSD grep).
TS='@ts-(ignore|expect-error|nocheck)|eslint-disable|(^|[^[:alnum:]_])as any([[:space:]]*[]);,.}]|[[:space:]]*$)|:[[:space:]]*any([[:space:]]*[]);,=|>[}]|[[:space:]]*$)|[<,][[:space:]]*any[[:space:]]*[>,]'
case "${FILE_PATH##*.}" in
  ts|tsx|js|jsx|mjs|cjs|vue) PATTERN=$TS ;;
  py|pyi)   PATTERN='#[[:space:]]*(type|pyright):[[:space:]]*ignore' ;;
  php)      PATTERN='@(phpstan-ignore|psalm-suppress)' ;;
  rs)       PATTERN='#!?\[allow\((dead_code|unused)' ;;
  go)       PATTERN='//[[:space:]]*nolint' ;;
  *) exit 0 ;;
esac

# Write sends .content, Edit sends .new_string.
NEW=$(jq -r '.tool_input.content // .tool_input.new_string // empty' <<<"$PAYLOAD")
# Suppressions already present (Edit's old_string, or the file being overwritten)
# are not new: Claude may keep them while editing nearby code.
OLD=$(jq -r '.tool_input.old_string // empty' <<<"$PAYLOAD")
[[ -z "$OLD" && -f "$FILE_PATH" ]] && OLD=$(cat "$FILE_PATH")

MATCHES=$(grep -En -- "$PATTERN" <<<"$NEW" | grep -v 'hatchlock-allow:' || true)
if [[ -n "$MATCHES" && -n "$OLD" ]]; then
  EXISTING=$(grep -E -- "$PATTERN" <<<"$OLD" || true)
  # Drop matches whose full line already existed ("N:" prefix stripped before comparing).
  MATCHES=$(while IFS= read -r m; do
    grep -qxF -- "${m#*:}" <<<"$EXISTING" || echo "$m"
  done <<<"$MATCHES")
fi
[[ -z "$MATCHES" ]] && exit 0

{
  echo "[HatchLock Guardrail] Blocked type-checker suppression in $FILE_PATH:"
  head -n 10 <<<"$MATCHES"
  echo "Fix the underlying type, or add \"hatchlock-allow: <reason>\" on the same line if suppression is truly required."
} >&2
exit 2
