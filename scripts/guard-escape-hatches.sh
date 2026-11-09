#!/usr/bin/env bash
# PreToolUse hook: blocks Write/Edit calls that would add type-checker escape
# hatches. Exit 2 stops the tool call and shows stderr to Claude.
set -uo pipefail

PAYLOAD=$(cat)
command -v jq >/dev/null 2>&1 || exit 0

FILE_PATH=$(jq -r '.tool_input.file_path // empty' <<<"$PAYLOAD")
case "${FILE_PATH##*.}" in
  ts|tsx|js|jsx|mjs|cjs|vue|py|pyi|rs|go|c|cpp|cc|h|hpp|zig|java|cs|php|rb|ex|exs|swift|kt|kts|dart|lua) ;;
  *) exit 0 ;;
esac

# Write sends .content, Edit sends .new_string: scan only the text being added.
TEXT=$(jq -r '.tool_input.content // .tool_input.new_string // empty' <<<"$PAYLOAD")
MATCHES=$(grep -En '(@ts-ignore|@ts-expect-error|\bas any\b|:\s*any\b|#\s*type:\s*ignore|@phpstan-ignore|#\[allow\(dead_code\)\]|//\s*nolint)' <<<"$TEXT" \
  | grep -v 'polyglot-allow:' || true)
[[ -z "$MATCHES" ]] && exit 0

{
  echo "[Polyglot Guardrail] Blocked type-checker suppression in $FILE_PATH:"
  head -n 10 <<<"$MATCHES"
  echo "Fix the underlying type, or add \"polyglot-allow: <reason>\" on the same line if suppression is truly required."
} >&2
exit 2
