#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "Running claude-code-polyglot automated verification suite..."

fail() { echo "  [FAIL] $*"; exit 1; }

# 1. JSON syntax
for json_file in .claude-plugin/plugin.json .claude-plugin/marketplace.json .lsp.json hooks/hooks.json; do
  jq . "$json_file" >/dev/null || fail "Invalid JSON: $json_file"
  echo "  [PASS] Valid JSON: $json_file"
done

# 2. Plugin loader rules
[[ "$(jq -r .name .claude-plugin/plugin.json)" == "polyglot" ]] || fail "plugin name must be 'polyglot'"
jq -e 'has("hooks") | not' .claude-plugin/plugin.json >/dev/null || fail "plugin.json must not declare hooks"
[[ "$(jq 'keys | length' .lsp.json)" -eq 18 ]] \
  || fail ".lsp.json must define 18 servers"
for skill in karpathy-core optimize architect clean doctor; do
  head -n 1 "skills/$skill/SKILL.md" | grep -qx -- '---' || fail "skills/$skill/SKILL.md missing frontmatter"
  grep -q "^name: $skill$" "skills/$skill/SKILL.md" || fail "skills/$skill/SKILL.md name mismatch"
done
echo "  [PASS] Plugin manifest, 18 LSP servers, and 5 skills are well-formed"

# 3. Fixtures
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# check <expected-exit> <label> <script> <json-payload>
check() {
  local want=$1 label=$2 script=$3 payload=$4 ret
  set +e; ./scripts/"$script" <<<"$payload" 2>"$TMP_DIR/stderr"; ret=$?; set -e
  [[ $ret -eq $want ]] || fail "$label: expected exit $want, got $ret ($(head -c 300 "$TMP_DIR/stderr"))"
  echo "  [PASS] $label (exit $want)"
}
# Hook payloads built with jq so paths with spaces/quotes stay valid JSON.
write_json() { jq -nc --arg f "$1" --arg c "${2:-}" '{tool_name:"Write",tool_input:{file_path:$f,content:$c}}'; }
edit_json()  { jq -nc --arg f "$1" --arg n "$2" '{tool_name:"Edit",tool_input:{file_path:$f,old_string:"x",new_string:$n}}'; }
post() { check "$1" "$2" verify-edit.sh "$(write_json "$3")"; }
pre()  { check "$1" "$2" guard-escape-hatches.sh "$3"; }

cat > "$TMP_DIR/clean.ts" <<'TS'
export function calculateTotal(prices: readonly number[]): number {
  let sum = 0;
  for (const price of prices) {
    sum += price;
  }
  return sum;
}
TS
printf 'if true; then\n' > "$TMP_DIR/broken.sh"

# PreToolUse escape-hatch guard
pre 2 "Write with @ts-ignore blocked"            "$(write_json "$TMP_DIR/bloat.ts" $'// @ts-ignore\nexport const x = 1;')"
pre 2 "Edit adding 'as any' blocked"             "$(edit_json "$TMP_DIR/a.ts" 'const y = x as any;')"
pre 0 "polyglot-allow: exempts the line"         "$(edit_json "$TMP_DIR/a.py" 'x = 1  # type: ignore  # polyglot-allow: stub lib')"
pre 0 "Non-source file (.md) not scanned"        "$(write_json "$TMP_DIR/notes.md" 'Never use @ts-ignore')"
pre 0 "Clean TS write allowed"                   "$(write_json "$TMP_DIR/clean.ts" "$(cat "$TMP_DIR/clean.ts")")"

# PostToolUse per-file check
post 0 "Clean TS file passes"         "$TMP_DIR/clean.ts"
post 2 "Shell syntax error fed back"  "$TMP_DIR/broken.sh"
post 0 "Missing file is ignored"      "$TMP_DIR/does-not-exist.ts"

if command -v python3 >/dev/null 2>&1 && ! command -v pyright >/dev/null 2>&1; then
  printf 'def f(:\n' > "$TMP_DIR/broken.py"
  post 2 "Python syntax error fed back" "$TMP_DIR/broken.py"
  [[ ! -d "$TMP_DIR/__pycache__" ]] || fail "py_compile left __pycache__ behind"
fi

# 4. Doctor
./scripts/lsp-doctor.sh >/dev/null
echo "  [PASS] lsp-doctor.sh executed cleanly"

echo "All tests passed!"
