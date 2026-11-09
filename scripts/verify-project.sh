#!/usr/bin/env bash
# Stop hook: once per turn, run whole-project compilers for each language with
# uncommitted changes. Exit 2 makes Claude continue and fix the errors.
set -uo pipefail

PAYLOAD=$(cat)
command -v jq >/dev/null 2>&1 || exit 0
# Already continuing because of this hook: don't trap Claude in a loop.
[[ "$(jq -r '.stop_hook_active // false' <<<"$PAYLOAD")" == "true" ]] && exit 0

ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$ROOT" 2>/dev/null || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

CHANGED=$( { git diff --name-only HEAD 2>/dev/null || git diff --name-only; git ls-files --others --exclude-standard; } | sort -u)
[[ -n "$CHANGED" ]] || exit 0
changed() { grep -qE "\.($1)$" <<<"$CHANGED"; }
has() { command -v "$1" >/dev/null 2>&1; }

REPORT=""
run() { # run <label> <cmd...>: append output of failing commands to REPORT
  local label=$1 out; shift
  out=$("$@" 2>&1) && return 0
  REPORT+="== $label =="$'\n'"$out"$'\n'
}

if changed 'ts|tsx|js|jsx|mjs|cjs|vue' && [[ -f tsconfig.json && -x node_modules/.bin/tsc ]]; then
  run "tsc" node_modules/.bin/tsc --noEmit --pretty false --incremental
fi
if changed 'rs' && [[ -f Cargo.toml ]] && has cargo; then
  run "cargo check" cargo check --message-format=short
fi
if changed 'go' && [[ -f go.mod ]] && has go; then
  run "go vet" go vet ./...
fi
if changed 'java' && has javac; then
  TMP_OUT=$(mktemp -d)
  mapfile -t JAVA < <(grep -E '\.java$' <<<"$CHANGED" | while read -r f; do [[ -f "$f" ]] && echo "$f"; done)
  (( ${#JAVA[@]} )) && run "javac" javac -Xlint:all -d "$TMP_OUT" "${JAVA[@]}"
  rm -rf "$TMP_OUT"
fi
if changed 'cs' && compgen -G "*.csproj" >/dev/null && has dotnet; then
  run "dotnet build" dotnet build --no-restore -v q
fi
if changed 'swift' && [[ -f Package.swift ]] && has swift; then
  run "swift build" swift build
fi
if changed 'tf|tfvars' && has terraform; then
  while read -r dir; do
    run "terraform validate ($dir)" terraform -chdir="$dir" validate -no-color
  done < <(grep -E '\.(tf|tfvars)$' <<<"$CHANGED" | xargs -r -n1 dirname | sort -u)
fi

[[ -z "$REPORT" ]] && exit 0

FEEDBACK=$(head -n 40 <<<"$REPORT" | head -c 7800)
{
  echo "[Polyglot Project Check] Project-wide checks failed for files changed this session:"
  echo "$FEEDBACK"
  [[ "$FEEDBACK" != "${REPORT%$'\n'}" ]] && echo "… (truncated)"
} >&2
exit 2
