#!/usr/bin/env bash
# shellcheck disable=SC2016 # stub scripts are written as literal single-quoted text
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
# Only LSP servers missing from the official marketplace are bundled.
[[ "$(jq -c 'keys' .lsp.json)" == '["bash","dart","elixir","r","terraform","zig"]' ]] \
  || fail ".lsp.json must define exactly the 6 unique servers"
# claude plugin validate does not read .lsp.json; one unknown key drops the whole file.
BAD=$(jq -r 'to_entries[] | .key as $k | .value | keys[]
  | select(IN("command","args","transport","env","initializationOptions","settings","workspaceFolder",
      "startupTimeout","shutdownTimeout","requestTimeout","restartOnCrash","maxRestarts","diagnostics",
      "extensionToLanguage") | not) | "\($k).\(.)"' .lsp.json)
[[ -z "$BAD" ]] || fail "unknown .lsp.json keys: $BAD"
for skill in tight-diff optimize architect clean doctor; do
  head -n 1 "skills/$skill/SKILL.md" | grep -qx -- '---' || fail "skills/$skill/SKILL.md missing frontmatter"
  grep -q "^name: $skill$" "skills/$skill/SKILL.md" || fail "skills/$skill/SKILL.md name mismatch"
done
echo "  [PASS] Plugin manifest, 6 LSP servers, and 5 skills are well-formed"

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
edit_json()  { jq -nc --arg f "$1" --arg n "$2" --arg o "${3:-x}" '{tool_name:"Edit",tool_input:{file_path:$f,old_string:$o,new_string:$n}}'; }
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
pre 2 "hatchlock-allow: needs a reason"          "$(edit_json "$TMP_DIR/a.py" 'x = 1  # type: ignore  # hatchlock-allow:')"
pre 2 "Upper-case extension still scanned"       "$(write_json "$TMP_DIR/B.TS" '// @ts-ignore')"
pre 2 "NotebookEdit cell scanned"                "$(jq -nc --arg f "$TMP_DIR/n.ipynb" '{tool_name:"NotebookEdit",tool_input:{notebook_path:$f,new_source:"x = f()  # type: ignore"}}')"
pre 0 "Non-source file (.md) not scanned"        "$(write_json "$TMP_DIR/notes.md" 'Never use @ts-ignore')"
pre 0 "Clean TS write allowed"                   "$(write_json "$TMP_DIR/clean.ts" "$(cat "$TMP_DIR/clean.ts")")"
pre 0 "Existing suppression in Edit context kept" "$(edit_json "$TMP_DIR/a.ts" $'// @ts-ignore legacy\nfoo(1)' $'// @ts-ignore legacy\nfoo()')"
printf 'x = f()  # type: ignore\n' > "$TMP_DIR/legacy.py"
pre 0 "Write keeping a file's existing suppression" "$(write_json "$TMP_DIR/legacy.py" $'x = f()  # type: ignore\ny = 2')"
pre 2 "@ts-nocheck blocked"                      "$(write_json "$TMP_DIR/b.ts" '// @ts-nocheck')"
pre 2 "Record<string, any> blocked"              "$(edit_json "$TMP_DIR/a.ts" 'let m: Record<string, any> = {};')"
pre 2 "# pyright: ignore blocked"                "$(edit_json "$TMP_DIR/a.py" 'x = f()  # pyright: ignore')"
pre 0 "Python any() call allowed"                "$(edit_json "$TMP_DIR/a.py" 'd = {"k": any(vals)}')"
pre 0 "'as any other' prose allowed"             "$(edit_json "$TMP_DIR/a.ts" '// use this as any other iterable')"
pre 0 ".d.ts declarations skipped"               "$(write_json "$TMP_DIR/x.d.ts" 'declare const x: any;')"

# PostToolUse per-file check
post 0 "Clean TS file passes"         "$TMP_DIR/clean.ts"
post 2 "Shell syntax error fed back"  "$TMP_DIR/broken.sh"
post 0 "Missing file is ignored"      "$TMP_DIR/does-not-exist.ts"
printf 'const n: number = "s";\n' > "$TMP_DIR/typeerr.ts"
post 0 "TS type errors deferred to Stop check" "$TMP_DIR/typeerr.ts"
mkdir -p "$TMP_DIR/my dir" && printf '#!/usr/bin/env bash\necho ok\n' > "$TMP_DIR/my dir/ok.sh"
post 0 "Path with a space"            "$TMP_DIR/my dir/ok.sh"
printf '#!/usr/bin/env bash\necho $1\n' > "$TMP_DIR/style.sh"
post 0 "Shellcheck style notes are not failures" "$TMP_DIR/style.sh"
printf '#include "project_header.h"\nint main(void) { return 0; }\n' > "$TMP_DIR/main.c"
post 0 "C file with project headers not flagged without a compile db" "$TMP_DIR/main.c"
cp "$TMP_DIR/broken.sh" "$OUT_DIR/broken.sh"
post 0 "File outside project skipped" "$OUT_DIR/broken.sh"
post 0 "Path with .. skipped"         "$TMP_DIR/../$(basename "$OUT_DIR")/broken.sh"
CLAUDE_PROJECT_DIR="$TMP_DIR/" post 2 "Trailing slash on project dir"  "$TMP_DIR/broken.sh"
ln -s "$TMP_DIR" "$OUT_DIR/link"
CLAUDE_PROJECT_DIR="$OUT_DIR/link" post 2 "Symlinked project dir"      "$TMP_DIR/broken.sh"

# Huge checker output is truncated (stub shellcheck first on PATH)
mkdir -p "$TMP_DIR/bin"
cat > "$TMP_DIR/bin/shellcheck" <<'STUB'
#!/usr/bin/env bash
for i in $(seq 5000); do printf 'error line %s: %0300d\n' "$i" 0; done
exit 1
STUB
chmod +x "$TMP_DIR/bin/shellcheck"
PATH="$TMP_DIR/bin:$PATH" post 2 "Huge output still fails" "$TMP_DIR/my dir/ok.sh"
[[ $(wc -c <"$TMP_DIR/stderr") -le 8000 ]] || fail "feedback exceeds 8000 chars"
grep -q '(truncated)' "$TMP_DIR/stderr" || fail "missing (truncated) marker"
echo "  [PASS] Feedback capped at 8000 chars"
LONG="$TMP_DIR/$(printf 'd%.0s' {1..200})"; mkdir -p "$LONG"
PATH="$TMP_DIR/bin:$PATH" post 2 "Long path + huge output" "$(cp "$TMP_DIR/my dir/ok.sh" "$LONG/ok.sh" && echo "$LONG/ok.sh")"
[[ $(wc -c <"$TMP_DIR/stderr") -le 8000 ]] || fail "feedback with long path exceeds 8000 chars"

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
printf '#!/usr/bin/env bash\necho "$*" > "%s/tsc-args"\necho "src/a.ts(1,7): error TS2322: Type string is not assignable to number."\nexit 2\n' "$TMP_DIR" > "$REPO/node_modules/.bin/tsc"
chmod +x "$REPO/node_modules/.bin/tsc"
git -C "$REPO" add -A && git -C "$REPO" -c user.email=t@t -c user.name=t commit -qm init
CLAUDE_PROJECT_DIR="$REPO" stop 0 "Clean git tree: no project check"  '{"stop_hook_active":false}'
CLAUDE_PROJECT_DIR="$OUT_DIR" stop 0 "Non-git dir: no project check"   '{"stop_hook_active":false}'
printf 'export const n: number = "s";\n' > "$REPO/a.ts"
CLAUDE_PROJECT_DIR="$REPO" stop 2 "Changed .ts with tsc errors fed back" '{"stop_hook_active":false}'
grep -q 'TS2322' "$TMP_DIR/stderr" || fail "tsc error missing from Stop feedback"
if ! grep -q -- '--tsBuildInfoFile' "$TMP_DIR/tsc-args" || grep -q -- "--tsBuildInfoFile $REPO" "$TMP_DIR/tsc-args"; then
  fail "tsc must keep its build-info file outside the repo"
fi
echo "  [PASS] tsc build-info kept out of the repo"
CLAUDE_PROJECT_DIR="$REPO" stop 0 "stop_hook_active: no loop"         '{"stop_hook_active":true}'

# Monorepo: project dir is a subdirectory of the git repo
MONO="$TMP_DIR/mono"; mkdir -p "$MONO/infra/app/.terraform" "$MONO/infra/svc" "$TMP_DIR/bin2"
git -C "$MONO" init -q && git -C "$MONO" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
printf '#!/usr/bin/env bash\nd=${1#-chdir=}\n[[ -d "$d" ]] || { echo "no such dir $d"; exit 1; }\n[[ -d "$d/.terraform" ]] || { echo "not initialized: $d"; exit 1; }\n' > "$TMP_DIR/bin2/terraform"
printf '#!/usr/bin/env bash\necho "javac: cannot find symbol"; exit 1\n' > "$TMP_DIR/bin2/javac"
chmod +x "$TMP_DIR/bin2/"*
# Tracked-then-modified: git diff reports these relative to the repo top level.
echo 'resource "x" "y" {}' > "$MONO/infra/app/main.tf"
git -C "$MONO" add -A && git -C "$MONO" -c user.email=t@t -c user.name=t commit -qm tf
echo 'resource "x" "z" {}' > "$MONO/infra/app/main.tf"
PATH="$TMP_DIR/bin2:$PATH" CLAUDE_PROJECT_DIR="$MONO/infra" stop 0 "Monorepo subdir paths resolved" '{"stop_hook_active":false}'
echo 'resource "x" "y" {}' > "$MONO/infra/svc/main.tf"
PATH="$TMP_DIR/bin2:$PATH" CLAUDE_PROJECT_DIR="$MONO/infra" stop 0 "terraform skipped before init" '{"stop_hook_active":false}'
rm -rf "$MONO/infra/svc" "$MONO/infra/app"
touch "$MONO/infra/pom.xml"; echo 'class A {}' > "$MONO/infra/A.java"
PATH="$TMP_DIR/bin2:$PATH" CLAUDE_PROJECT_DIR="$MONO/infra" stop 0 "javac skipped in Maven/Gradle projects" '{"stop_hook_active":false}'
! grep -n 'mapfile' scripts/*.sh || fail "mapfile is unavailable in macOS bash 3.2"

# Branding & policy
! grep -rniIE 'karpathy|andrej' --exclude=README.md --exclude=test-suite.sh --exclude-dir=docs --exclude-dir=.git --exclude-dir=.superpowers . || fail "Karpathy branding outside README attribution"
! grep -rniIE 'polyglot' --exclude-dir=docs --exclude-dir=.git --exclude-dir=.superpowers --exclude=README.md --exclude=test-suite.sh . | grep -v 'claude-code-polyglot' || fail "stale 'polyglot' name"
! ./scripts/lsp-doctor.sh | grep -iE 'coffee|sponsor|polar' || fail "sponsored text in doctor output"
jq -e '[.. | objects | has("version")] | any | not' .claude-plugin/marketplace.json >/dev/null || fail "version must live only in plugin.json"
echo "  [PASS] No personal branding, stale names, sponsored output, or duplicate versions"

# Skills shipped to OpenAI must be provider-neutral
! grep -niE '\bclaude\b' skills/{tight-diff,optimize,architect,clean}/SKILL.md || fail "provider-specific wording in portable skills"
echo "  [PASS] Portable skills are provider-neutral"

# OpenAI / ChatGPT skills-only package
CODEX=.codex-plugin/plugin.json
jq -e . "$CODEX" >/dev/null || fail "invalid $CODEX"
[[ "$(jq -r .version "$CODEX")" == "$(jq -r .version .claude-plugin/plugin.json)" ]] || fail "codex/claude versions differ"
[[ "$(jq -r .name "$CODEX")" == "hatchlock" ]] || fail "codex name must be hatchlock"
jq -e '.interface | (.displayName|length) <= 30 and (.shortDescription|length) <= 30
  and (.defaultPrompt|length) <= 3 and all(.defaultPrompt[]; length <= 128)
  and has("longDescription") and has("developerName") and has("category") and has("capabilities")
  and has("logo") and has("composerIcon") and has("privacyPolicyURL") and has("supportURL")' "$CODEX" >/dev/null \
  || fail "codex interface fields missing or too long"
[[ -f PRIVACY.md ]] || fail "PRIVACY.md missing"
PKG="$TMP_DIR/pkg"; mkdir -p "$PKG"
cp -R .codex-plugin skills scripts README.md LICENSE PRIVACY.md "$PKG/"
mkdir -p "$PKG/assets"
python3 -c 'import sys,zlib,struct
def c(t,d): return struct.pack(">I",len(d))+t+d+struct.pack(">I",zlib.crc32(t+d))
open(sys.argv[1],"wb").write(b"\x89PNG\r\n\x1a\n"+c(b"IHDR",struct.pack(">IIBBBBB",64,64,8,2,0,0,0))+c(b"IDAT",zlib.compress(b"\0"*(64*3+1)*64))+c(b"IEND",b""))' "$PKG/assets/icon.png"
cp "$PKG/assets/icon.png" "$PKG/assets/logo.png"
"$PKG/scripts/build-openai-zip.sh" >/dev/null || fail "build-openai-zip.sh failed"
LIST=$(unzip -Z1 "$PKG/dist/hatchlock-openai.zip")
grep -qx '.codex-plugin/plugin.json' <<<"$LIST" || fail "zip lacks .codex-plugin/plugin.json"
grep -qx 'skills/tight-diff/SKILL.md' <<<"$LIST" || fail "zip lacks tight-diff skill"
! grep -E '^(hooks/|scripts/|skills/doctor/|\.lsp\.json|\.claude-plugin/)' <<<"$LIST" || fail "zip contains Claude-only parts"
rm "$PKG/assets/logo.png"
! "$PKG/scripts/build-openai-zip.sh" >/dev/null 2>&1 || fail "build must fail without icons"
echo "  [PASS] OpenAI skills-only package builds and excludes hooks, LSP, doctor"

# 4. Doctor
./scripts/lsp-doctor.sh >/dev/null
echo "  [PASS] lsp-doctor.sh executed cleanly"

echo "All tests passed!"
