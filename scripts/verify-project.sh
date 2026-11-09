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

# --relative: paths relative to $ROOT even when it is a monorepo subdirectory.
CHANGED=$( { git diff --name-only --relative HEAD 2>/dev/null || git diff --name-only --relative; git ls-files --others --exclude-standard; } | sort -u)
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
  # Keep the incremental build-info file out of the user's repo.
  CACHE="${CLAUDE_PLUGIN_DATA:-${TMPDIR:-/tmp}}"
  BUILDINFO="$CACHE/hatchlock-$(cksum <<<"$ROOT" | cut -d' ' -f1).tsbuildinfo"
  run "tsc" node_modules/.bin/tsc --noEmit --pretty false --incremental --tsBuildInfoFile "$BUILDINFO"
fi
if changed 'rs' && [[ -f Cargo.toml ]] && has cargo; then
  run "cargo check" cargo check --message-format=short
fi
if changed 'go' && [[ -f go.mod ]] && has go; then
  run "go vet" go vet ./...
fi
# Maven/Gradle projects need their classpath; bare javac would fail every file.
if changed 'java' && has javac && ! compgen -G "pom.xml" >/dev/null && ! compgen -G "build.gradle*" >/dev/null; then
  JAVA=()
  while IFS= read -r f; do [[ -f "$f" ]] && JAVA+=("$f"); done < <(grep -E '\.java$' <<<"$CHANGED")
  if (( ${#JAVA[@]} )); then
    TMP_OUT=$(mktemp -d)
    run "javac" javac -Xlint:all -d "$TMP_OUT" "${JAVA[@]}"
    rm -rf "$TMP_OUT"
  fi
fi
if changed 'cs' && compgen -G "*.csproj" >/dev/null && has dotnet; then
  run "dotnet build" dotnet build --no-restore -v q
fi
if changed 'swift' && [[ -f Package.swift ]] && has swift; then
  run "swift build" swift build
fi
if changed 'tf|tfvars' && has terraform; then
  while IFS= read -r dir; do
    # validate needs `terraform init` first; skip uninitialized directories.
    [[ -d "$dir/.terraform" ]] && run "terraform validate ($dir)" terraform -chdir="$dir" validate -no-color
  done < <(grep -E '\.(tf|tfvars)$' <<<"$CHANGED" | while IFS= read -r f; do dirname "$f"; done | sort -u)
fi

[[ -z "$REPORT" ]] && exit 0

FEEDBACK=$(head -n 40 <<<"$REPORT" | head -c 7800)
{
  echo "[HatchLock Project Check] Project-wide checks failed for languages with uncommitted changes:"
  echo "$FEEDBACK"
  [[ "$FEEDBACK" != "${REPORT%$'\n'}" ]] && echo "… (truncated)"
} >&2
exit 2
