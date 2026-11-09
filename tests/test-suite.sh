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

run_hook() { echo "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$1\"}}" | ./scripts/verify-edit.sh 2>/dev/null; }
expect() { # expect <exit-code> <file> <label>
  set +e; run_hook "$2"; local ret=$?; set -e
  [[ $ret -eq $1 ]] || fail "$3: expected exit $1, got $ret"
  echo "  [PASS] $3 (exit $1)"
}

cat > "$TMP_DIR/clean.ts" <<'TS'
export function calculateTotal(prices: readonly number[]): number {
  let sum = 0;
  for (const price of prices) {
    sum += price;
  }
  return sum;
}
TS

cat > "$TMP_DIR/bloat.ts" <<'TS'
// @ts-ignore
export function brokenTotal(prices: any): number {
  return (prices as any).reduce((a: number, b: number) => a + b, 0);
}
TS

printf 'x = 1  # type: ignore\n' > "$TMP_DIR/suppressed.py"
printf 'if true; then\n' > "$TMP_DIR/broken.sh"

expect 0 "$TMP_DIR/clean.ts"        "Clean TS file passes"
expect 2 "$TMP_DIR/bloat.ts"        "@ts-ignore / as any blocked"
expect 2 "$TMP_DIR/suppressed.py"   "# type: ignore blocked"
expect 2 "$TMP_DIR/broken.sh"       "Shell syntax error fed back"
expect 0 "$TMP_DIR/does-not-exist.ts" "Missing file is ignored"

if command -v python3 >/dev/null 2>&1 && ! command -v pyright >/dev/null 2>&1; then
  printf 'def f(:\n' > "$TMP_DIR/broken.py"
  expect 2 "$TMP_DIR/broken.py" "Python syntax error fed back"
  [[ ! -d "$TMP_DIR/__pycache__" ]] || fail "py_compile left __pycache__ behind"
fi

# 4. Doctor
./scripts/lsp-doctor.sh >/dev/null
echo "  [PASS] lsp-doctor.sh executed cleanly"

echo "All tests passed!"
