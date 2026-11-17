#!/usr/bin/env bash
# Google Antigravity hook adapter. Antigravity hooks must exit 0 and answer in JSON,
# and send toolCall{name,args} instead of Claude-style tool_input, so this script
# translates between the two and reuses HatchLock's normal checks.
#   antigravity-hook.sh pre   -> PreToolUse: {"decision":"deny","reason":...} or {}
#   antigravity-hook.sh stop  -> Stop: {"decision":"continue","reason":...} once, or {}
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
PAYLOAD=$(cat)
command -v jq >/dev/null 2>&1 || { echo '{}'; exit 0; }

case "${1:-}" in
  pre)
    # write_to_file{TargetFile,CodeContent}; replace_file_content{TargetFile,TargetContent,ReplacementContent};
    # multi_replace_file_content{TargetFile,ReplacementChunks[{TargetContent,ReplacementContent}]}
    CLAUDE_STYLE=$(jq -c '.toolCall.args // {} | {tool_input: {
        file_path: .TargetFile,
        content: .CodeContent,
        new_string: (.ReplacementContent // ([.ReplacementChunks[]?.ReplacementContent] | join("\n") | if . == "" then null else . end)),
        old_string: (.TargetContent // ([.ReplacementChunks[]?.TargetContent] | join("\n") | if . == "" then null else . end))
      } | with_entries(select(.value != null))}' <<<"$PAYLOAD")
    if REASON=$("$HERE/guard-escape-hatches.sh" <<<"$CLAUDE_STYLE" 2>&1 >/dev/null); then echo '{}'
    else jq -nc --arg r "$REASON" '{decision:"deny", reason:$r}'; fi
    ;;
  stop)
    ROOT=$(jq -r '.workspacePaths[0] // empty' <<<"$PAYLOAD"); [[ -n "$ROOT" ]] || { echo '{}'; exit 0; }
    ID=$(jq -r '.conversationId // "default"' <<<"$PAYLOAD" | tr -cd 'A-Za-z0-9_-')
    # Antigravity has no stop_hook_active flag: a marker allows one extra round, never a loop.
    MARK="${PLUGIN_DATA:-${TMPDIR:-/tmp}}/hatchlock-agy-stop-$ID"
    if [[ -e "$MARK" ]]; then rm -f "$MARK"; echo '{}'; exit 0; fi
    if REASON=$(CLAUDE_PROJECT_DIR="$ROOT" "$HERE/verify-project.sh" <<<'{}' 2>&1 >/dev/null); then echo '{}'
    else touch "$MARK"; jq -nc --arg r "$REASON" '{decision:"continue", reason:$r}'; fi
    ;;
  *) echo '{}' ;;
esac
exit 0
