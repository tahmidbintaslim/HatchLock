#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "Running HatchLock automated verification suite..."

fail() { echo "  [FAIL] $*"; exit 1; }

# 1. JSON syntax
for json_file in .claude-plugin/plugin.json .claude-plugin/marketplace.json .lsp.json hooks/hooks.json; do
  jq . "$json_file" >/dev/null || fail "Invalid JSON: $json_file"
  echo "  [PASS] Valid JSON: $json_file"
done

# 2. Plugin loader rules
[[ "$(jq -r .name .claude-plugin/plugin.json)" == "hatchlock" ]] || fail "plugin name must be 'hatchlock'"
jq -e 'has("hooks") | not' .claude-plugin/plugin.json >/dev/null || fail "plugin.json must not declare hooks"
[[ "$(jq 'keys | length' .lsp.json)" -eq 18 ]] \
  || fail ".lsp.json must define 18 servers"
for skill in tight-diff optimize architect clean doctor; do
  head -n 1 "skills/$skill/SKILL.md" | grep -qx -- '---' || fail "skills/$skill/SKILL.md missing frontmatter"
  grep -q "^name: $skill$" "skills/$skill/SKILL.md" || fail "skills/$skill/SKILL.md name mismatch"
done
echo "  [PASS] Plugin manifest, 18 LSP servers, and 5 skills are well-formed"

# 3. Fixtures
TMP_DIR=$(mktemp -d)
OUT_DIR=$(mktemp -d)   # a directory outside the "project"
trap 'rm -rf "$TMP_DIR" "$OUT_DIR"' EXIT
export CLAUDE_PROJECT_DIR="$TMP_DIR"

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
pre 0 "hatchlock-allow: exempts the line"         "$(edit_json "$TMP_DIR/a.py" 'x = 1  # type: ignore  # hatchlock-allow: stub lib')"
pre 0 "Non-source file (.md) not scanned"        "$(write_json "$TMP_DIR/notes.md" 'Never use @ts-ignore')"
pre 0 "Clean TS write allowed"                   "$(write_json "$TMP_DIR/clean.ts" "$(cat "$TMP_DIR/clean.ts")")"

# PostToolUse per-file check
post 0 "Clean TS file passes"         "$TMP_DIR/clean.ts"
post 2 "Shell syntax error fed back"  "$TMP_DIR/broken.sh"
post 0 "Missing file is ignored"      "$TMP_DIR/does-not-exist.ts"
printf 'const n: number = "s";\n' > "$TMP_DIR/typeerr.ts"
post 0 "TS type errors deferred to Stop check" "$TMP_DIR/typeerr.ts"
mkdir -p "$TMP_DIR/my dir" && printf 'echo ok\n' > "$TMP_DIR/my dir/ok.sh"
post 0 "Path with a space"            "$TMP_DIR/my dir/ok.sh"
cp "$TMP_DIR/broken.sh" "$OUT_DIR/broken.sh"
post 0 "File outside project skipped" "$OUT_DIR/broken.sh"
post 0 "Path with .. skipped"         "$TMP_DIR/../$(basename "$OUT_DIR")/broken.sh"

# Huge checker output is truncated (stub shellcheck first on PATH)
mkdir -p "$TMP_DIR/bin"
printf '#!/usr/bin/env bash\nfor i in $(seq 5000); do echo "error line $i: something is wrong here"; done\nexit 1\n' > "$TMP_DIR/bin/shellcheck"
chmod +x "$TMP_DIR/bin/shellcheck"
PATH="$TMP_DIR/bin:$PATH" post 2 "Huge output still fails" "$TMP_DIR/my dir/ok.sh"
[[ $(wc -c <"$TMP_DIR/stderr") -le 8000 ]] || fail "feedback exceeds 8000 chars"
grep -q '(truncated)' "$TMP_DIR/stderr" || fail "missing (truncated) marker"
echo "  [PASS] Feedback capped at 8000 chars"

if command -v python3 >/dev/null 2>&1 && ! command -v pyright >/dev/null 2>&1; then
  printf 'def f(:\n' > "$TMP_DIR/broken.py"
  post 2 "Python syntax error fed back" "$TMP_DIR/broken.py"
  [[ ! -d "$TMP_DIR/__pycache__" ]] || fail "py_compile left __pycache__ behind"
fi

# Stop-hook project check
stop() { check "$1" "$2" verify-project.sh "$3"; }
REPO="$TMP_DIR/repo"; mkdir -p "$REPO/node_modules/.bin"
git -C "$REPO" init -q
printf 'node_modules/\n' > "$REPO/.gitignore"
echo '{}' > "$REPO/tsconfig.json"
printf '#!/usr/bin/env bash\necho "src/a.ts(1,7): error TS2322: Type string is not assignable to number."\nexit 2\n' > "$REPO/node_modules/.bin/tsc"
chmod +x "$REPO/node_modules/.bin/tsc"
git -C "$REPO" add -A && git -C "$REPO" -c user.email=t@t -c user.name=t commit -qm init
CLAUDE_PROJECT_DIR="$REPO" stop 0 "Clean git tree: no project check"  '{"stop_hook_active":false}'
CLAUDE_PROJECT_DIR="$OUT_DIR" stop 0 "Non-git dir: no project check"   '{"stop_hook_active":false}'
printf 'export const n: number = "s";\n' > "$REPO/a.ts"
CLAUDE_PROJECT_DIR="$REPO" stop 2 "Changed .ts with tsc errors fed back" '{"stop_hook_active":false}'
grep -q 'TS2322' "$TMP_DIR/stderr" || fail "tsc error missing from Stop feedback"
CLAUDE_PROJECT_DIR="$REPO" stop 0 "stop_hook_active: no loop"         '{"stop_hook_active":true}'

# Branding & policy
! grep -rniIE 'karpathy|andrej' --exclude=README.md --exclude=test-suite.sh --exclude-dir=docs --exclude-dir=.git --exclude-dir=.superpowers . || fail "Karpathy branding outside README attribution"
! grep -rniIE 'polyglot' --exclude-dir=docs --exclude-dir=.git --exclude-dir=.superpowers --exclude=README.md --exclude=test-suite.sh . | grep -v 'claude-code-polyglot' || fail "stale 'polyglot' name"
! ./scripts/lsp-doctor.sh | grep -iE 'coffee|sponsor|polar' || fail "sponsored text in doctor output"
jq -e '[.. | objects | has("version")] | any | not' .claude-plugin/marketplace.json >/dev/null || fail "version must live only in plugin.json"
echo "  [PASS] No personal branding, stale names, sponsored output, or duplicate versions"

# 4. Doctor
./scripts/lsp-doctor.sh >/dev/null
echo "  [PASS] lsp-doctor.sh executed cleanly"

echo "All tests passed!"
